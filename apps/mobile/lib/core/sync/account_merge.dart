import 'dart:math' as math;

import '../backend/backend.dart';
import '../db/app_database.dart';
import '../db/ids.dart';
import '../leaderboard/leaderboard_report.dart';
import '../profile/drift_profile_repository.dart';
import '../progress/drift_progress_repository.dart';
import 'outbox.dart';
import 'sync_worker.dart';

/// "Sign in on another device" (FR-3): how this device's progress and the account's meet.
///
/// The rule is the sync's own: attempts are an append-only log keyed by `attempt_id`, so the two
/// sides are a **union**, never an overwrite. Every attempt the account has comes down (insert or
/// skip, like the restore), and every attempt this device has goes up to the account (the
/// outbox). The profile is one row, so one side wins: **the account's saved profile**, when it
/// has one (it's what the player saved); otherwise this device's profile is sent up.
///
/// It runs in two halves. [prepareAccountMerge] is local and runs the moment the code is
/// accepted, before the session switches; the pull half runs in the [SyncWorker] of the new
/// session ([pullAccountMerge]), and retries on each start until it succeeds, so an offline
/// moment in between loses nothing.
const String accountMergeKey = 'account_merge';

/// The local half, run before the session becomes the account's. Returns the attempt ids it
/// gave new values (old id → new id), so the caller can carry anything keyed by them (the Recall
/// Room's ingested set) over.
///
/// An attempt no longer in the outbox already reached the server under this device's guest id,
/// and its `attempt_id` belongs to that guest's row there: sent again, the server would skip it
/// (insert on conflict do nothing). So it takes a fresh id and is queued again, and reaches the
/// account as a new row. Attempts still queued keep their ids. The queued profile row is dropped:
/// the pull half decides whose profile wins.
Future<Map<String, String>> prepareAccountMerge(
  AppDatabase db, {
  math.Random? random,
}) async {
  final rng = random ?? math.Random.secure();
  final outbox = Outbox(db);
  return db.transaction(() async {
    final rows = await db
        .customSelect(
          'select attempt_id, exists (select 1 from outbox o '
          "where o.kind = 'attempt' and o.ref = a.attempt_id) as queued "
          'from attempts a',
        )
        .get();
    final renamed = <String, String>{};
    for (final row in rows) {
      var id = row.read<String>('attempt_id');
      if (row.read<int>('queued') == 0) {
        final fresh = newUuid(rng);
        await db.customStatement(
          'update attempts set attempt_id = ? where attempt_id = ?',
          [fresh, id],
        );
        renamed[id] = fresh;
        id = fresh;
      }
      await outbox.add(OutboxKind.attempt, id);
    }
    await db.customStatement('delete from outbox where kind = ? and ref = ?', [
      OutboxKind.profile.name,
      Outbox.profileRef,
    ]);
    await db.setMeta(accountMergeKey, 'pending');
    // The pull below replaces the one-time restore for this database.
    await db.setMeta(SyncWorker.restoredKey, 'merged');
    return renamed;
  });
}

/// The pull half, run by the new session's [SyncWorker] when [prepareAccountMerge] left it
/// pending. Returns whether anything came down (so the app re-reads the profile). Throws when
/// the backend fails; the caller retries on its next start.
Future<bool> pullAccountMerge(AppDatabase db, Backend backend) async {
  if (await db.metaValue(accountMergeKey) == null) return false;
  final attempts = await backend.fetchAttempts();
  final profile = await backend.fetchProfile();
  await db.transaction(() async {
    for (final a in attempts) {
      await insertAttemptRow(db, storedAttempt(a));
    }
    if (profile != null) {
      await DriftProfileRepository.write(db, playerProfile(profile));
      await restoreLeaderboardVisibility(db, profile);
    } else if (await DriftProfileRepository.read(db) != null) {
      await Outbox(db).add(OutboxKind.profile, Outbox.profileRef);
    }
    // The device's leaderboard numbers go to the account it now is (they're recomputed from the
    // union of attempts as soon as the app re-reads them).
    if (await DriftLeaderboardReportStore.read(db) != null) {
      await Outbox(db).add(OutboxKind.leaderboard, Outbox.leaderboardRef);
    }
    await db.customStatement('delete from meta where key = ?', [
      accountMergeKey,
    ]);
  });
  return attempts.isNotEmpty || profile != null;
}

/// Whether this device holds any progress of its own (for `account_signed_in`'s `had_progress`).
Future<bool> deviceHasProgress(AppDatabase db) async {
  final row = await db
      .customSelect('select count(*) as n from attempts')
      .getSingle();
  return row.read<int>('n') > 0;
}
