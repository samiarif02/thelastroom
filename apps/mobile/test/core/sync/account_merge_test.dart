import 'package:content/content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/profile/drift_profile_repository.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/drift_progress_repository.dart';
import 'package:the_last_room/core/sync/account_merge.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/core/sync/sync_worker.dart';
import 'package:the_last_room/features/recall/recall_store.dart';
import 'package:the_last_room/features/settings/account/save_progress_controller.dart';

import '../../features/tower/played_attempt.dart';
import '../backend/fakes.dart';
import '../db/db_support.dart';

/// FR-3's "Sign in on another device": this device's progress and the saved account's meet as
/// a union of attempts (insert or skip, like the restore), and the account's profile wins.
void main() {
  late AppDatabase db;
  late FakeBackend server;
  late CapturedLog log;
  late OutboxSignal signal;
  late DriftProgressRepository progress;
  late DriftProfileRepository profiles;
  final now = DateTime.utc(2026, 11, 4, 9);
  const accountAttempt = '22222222-0000-4000-8000-000000000001';

  SyncWorker worker() =>
      SyncWorker(db: db, backend: server, log: log.log, signal: signal);

  setUp(() {
    db = memoryDb();
    server = FakeBackend();
    log = CapturedLog();
    signal = OutboxSignal();
    progress = DriftProgressRepository(
      db,
      log: log.log,
      signal: signal,
      clock: () => now,
    );
    profiles = DriftProfileRepository(db, signal: signal);
  });
  tearDown(() async {
    await signal.close();
    await db.close();
  });

  /// This device as a guest: one attempt already synced (under the guest's id), one still
  /// queued, and an onboarded profile.
  Future<(String synced, String queued)> guestDevice() async {
    await profiles.save(
      const PlayerProfile(firstName: 'Here', onboarded: true),
    );
    await progress.recordAttempt(playedAttempt(missions[0]));
    await worker().flush();
    final synced = (await progress.attempts()).single.attemptId!;
    server.attempts
        .clear(); // that row is the old guest's: the account can't see it
    server.profile = null;
    await progress.recordAttempt(playedAttempt(missions[1]));
    final queued = (await progress.attempts())
        .firstWhere((a) => a.attemptId != synced)
        .attemptId!;
    return (synced, queued);
  }

  /// The saved account: one attempt of its own and a profile.
  void savedAccount({bool withProfile = true}) {
    final played = playedAttempt(missions[2]);
    final stored = StoredAttempt(
      attemptId: accountAttempt,
      missionId: played.missionId,
      attemptNumber: played.attemptNumber,
      seed: played.seed,
      beatOptionIds: played.beatOptionIds,
      followUpId: played.followUpId,
      replyOptionId: played.replyOptionId,
      hinted: played.hinted,
      completedAt: now,
    );
    server.attempts[accountAttempt] = remoteAttempt(stored, played.score);
    if (withProfile) {
      server.profile = const RemoteProfile(firstName: 'Saved', onboarded: true);
    }
  }

  test(
    'the local half re-keys synced attempts and queues everything',
    () async {
      final (synced, queued) = await guestDevice();
      final renamed = await prepareAccountMerge(db);
      expect(renamed.keys, [synced]);
      final ids = {for (final a in await progress.attempts()) a.attemptId};
      expect(ids, {renamed[synced], queued});
      final outbox = await Outbox(db).due(now.add(const Duration(days: 1)));
      expect({for (final e in outbox) e.ref}, {renamed[synced], queued});
      expect(outbox.every((e) => e.kind == OutboxKind.attempt), isTrue);
      expect(await db.metaValue(accountMergeKey), 'pending');
    },
  );

  test(
    'the account worker unions attempts and the account profile wins',
    () async {
      final (_, queued) = await guestDevice();
      await prepareAccountMerge(db);
      savedAccount();
      var restored = 0;
      final w = SyncWorker(
        db: db,
        backend: server,
        log: log.log,
        signal: signal,
        onRestored: () => restored++,
      );
      await w.start();
      await w.dispose();

      // Down: the account's attempt and profile. Up: both of this device's attempts.
      final local = {for (final a in await progress.attempts()) a.attemptId};
      expect(local, hasLength(3));
      expect(local, contains(accountAttempt));
      expect(server.attempts.keys.toSet(), local);
      expect(server.attempts.keys, contains(queued));
      expect((await DriftProfileRepository.read(db))!.firstName, 'Saved');
      expect(server.profile!.firstName, 'Saved');
      expect(await db.metaValue(accountMergeKey), isNull);
      expect(await rows(db, 'outbox'), 0);
      expect(restored, 1);
    },
  );

  test('an account with no profile yet takes this device\'s', () async {
    await guestDevice();
    await prepareAccountMerge(db);
    savedAccount(withProfile: false);
    final w = worker();
    await w.start();
    await w.dispose();
    expect(server.profile!.firstName, 'Here');
  });

  test(
    'offline: the merge stays pending and the next flush finishes it',
    () async {
      await guestDevice();
      await prepareAccountMerge(db);
      savedAccount();
      server.online = false;
      final w = worker();
      await w.start();
      expect(await db.metaValue(accountMergeKey), 'pending');
      expect((await DriftProfileRepository.read(db))!.firstName, 'Here');

      server.online = true;
      await w.flush();
      await w.dispose();
      expect(await db.metaValue(accountMergeKey), isNull);
      expect((await DriftProfileRepository.read(db))!.firstName, 'Saved');
      expect(await progress.attempts(), hasLength(3));
    },
  );

  test('a fresh device just receives the account', () async {
    await prepareAccountMerge(db);
    savedAccount();
    final w = worker();
    await w.start();
    await w.dispose();
    expect(
      [for (final a in await progress.attempts()) a.attemptId],
      [accountAttempt],
    );
  });

  test('the Recall Room keeps its place for a re-keyed attempt', () async {
    final (synced, queued) = await guestDevice();
    final recall = InMemoryRecallStore(
      RecallSchedule(ingested: {synced, queued}),
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        recallStoreProvider.overrideWithValue(recall),
      ],
    );
    addTearDown(container.dispose);
    final hadProgress = await container.read(accountDevicePrepProvider)();
    expect(hadProgress, isTrue);
    final ids = {for (final a in await progress.attempts()) a.attemptId!};
    expect(recall.schedule.ingested, ids);
  });
}
