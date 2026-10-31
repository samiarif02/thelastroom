import 'dart:async';

import 'package:engine/engine.dart';

import '../backend/backend.dart';
import '../db/app_database.dart';
import '../logging/log.dart';
import '../profile/drift_profile_repository.dart';
import '../profile/profile_repository.dart';
import '../progress/drift_progress_repository.dart';
import 'outbox.dart';

/// Sends the outbox to the backend, and restores a fresh install once (FR-60, FR-61).
///
/// It runs only for a signed-in guest (no keys, no session: it's never built). Every failure is
/// a `warn` log and a later retry with backoff, never an error the player sees. It sends in
/// batches of [Outbox.batchSize], one flush at a time, when it starts, when something is queued
/// ([OutboxSignal]), when the app resumes, and when the next retry falls due.
class SyncWorker {
  SyncWorker({
    required this._db,
    required this._backend,
    required this._log,
    required this._signal,
    this._onRestored,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Backend _backend;
  final Log _log;
  final OutboxSignal _signal;

  /// Called after the restore wrote anything, so the app re-reads the profile.
  final void Function()? _onRestored;
  final DateTime Function() _clock;

  StreamSubscription<void>? _queued;
  Timer? _retry;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;

  /// The one-time restore has run on this database.
  static const String restoredKey = 'restored';

  /// A retry never waits less than this, even when a row is already due.
  static const Duration minRetryWait = Duration(seconds: 1);

  Outbox get _outbox => Outbox(_db);

  /// Restores if this is a fresh install, then sends what's waiting, and keeps listening.
  Future<void> start() async {
    _queued ??= _signal.queued.listen((_) => unawaited(flush()));
    await _restoreOnce();
    await flush();
  }

  /// Sends everything due now. Concurrent calls share one run; a call during a run makes it go
  /// round once more, so nothing queued meanwhile waits for the timer.
  Future<void> flush() {
    if (_disposed) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _flushAll().whenComplete(() => _running = null);
  }

  Future<void> _flushAll() async {
    // Batch after batch while rows are due; a failed batch is pushed into the future by its
    // backoff, so this always ends.
    var more = false;
    do {
      _again = false;
      more = await _flushOnce();
    } while ((_again || more) && !_disposed);
    await _scheduleRetry();
  }

  /// Sends one batch; false when nothing was due.
  Future<bool> _flushOnce() async {
    final due = await _outbox.due(_clock());
    if (due.isEmpty) return false;
    final attempts = [
      for (final e in due)
        if (e.kind == OutboxKind.attempt) e,
    ];
    final profile = [
      for (final e in due)
        if (e.kind == OutboxKind.profile) e,
    ];
    await _send(attempts, _sendAttempts);
    await _send(profile, (_) => _sendProfile());
    return true;
  }

  Future<void> _send(
    List<OutboxEntry> entries,
    Future<void> Function(List<OutboxEntry>) send,
  ) async {
    if (entries.isEmpty) return;
    try {
      await send(entries);
      await _outbox.sent(entries);
    } on Object catch (error) {
      // Offline or the backend refused: wait and try again. Only the error's type is logged,
      // never a row (the profile holds the player's name).
      _log.warn('sync failed, will retry', {
        'kind': entries.first.kind.name,
        'rows': entries.length,
        'error': '${error.runtimeType}',
      });
      await _outbox.failed(entries, _clock());
    }
  }

  Future<void> _sendAttempts(List<OutboxEntry> entries) async {
    final rows = <RemoteAttempt>[];
    final stale = <OutboxEntry>[];
    final progress = DriftProgressRepository(_db, log: _log);
    for (final e in entries) {
      final stored = await progress.byId(e.ref);
      final record = stored?.toRecord();
      if (stored == null || record == null) {
        stale.add(e);
        continue;
      }
      rows.add(remoteAttempt(stored, record.score));
    }
    // A row that can't be scored any more can never be sent; it leaves the outbox.
    if (stale.isNotEmpty) {
      _log.warn('dropped unsendable outbox rows', {'rows': stale.length});
      await _outbox.sent(stale);
    }
    await _backend.insertAttempts(rows);
  }

  Future<void> _sendProfile() async {
    final profile = await DriftProfileRepository.read(_db);
    if (profile != null) await _backend.upsertProfile(remoteProfile(profile));
  }

  Future<void> _scheduleRetry() async {
    _retry?.cancel();
    if (_disposed) return;
    final next = await _outbox.nextDue();
    if (next == null || _disposed) return;
    var wait = next.difference(_clock());
    if (wait < minRetryWait) wait = minRetryWait;
    _retry = Timer(wait, () => unawaited(flush()));
  }

  /// On a fresh install (an empty database), pulls the player's attempts and profile from the
  /// server once. Marked done only when it succeeds, so a failure retries on the next start.
  Future<void> _restoreOnce() async {
    if (await _db.metaValue(restoredKey) != null) return;
    final progress = DriftProgressRepository(_db, log: _log);
    final empty =
        await progress.count == 0 &&
        await DriftProfileRepository.read(_db) == null;
    if (!empty) {
      await _db.setMeta(restoredKey, 'skipped');
      return;
    }
    try {
      final attempts = await _backend.fetchAttempts();
      final profile = await _backend.fetchProfile();
      await _db.transaction(() async {
        for (final a in attempts) {
          await insertAttemptRow(_db, storedAttempt(a));
        }
        if (profile != null) {
          await DriftProfileRepository.write(_db, playerProfile(profile));
        }
        await _db.setMeta(restoredKey, 'done');
      });
      if (attempts.isNotEmpty || profile != null) _onRestored?.call();
    } on Object catch (error) {
      _log.warn('restore failed, will retry', {
        'error': '${error.runtimeType}',
      });
    }
  }

  /// Stops listening and cancels the retry timer; a running flush finishes.
  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    await _queued?.cancel();
  }
}

/// The server row for a stored attempt and its engine score. The draft is never part of it.
RemoteAttempt remoteAttempt(StoredAttempt a, MissionScore score) =>
    RemoteAttempt(
      attemptId: a.attemptId,
      missionId: a.missionId,
      contentSchemaVersion: a.contentSchemaVersion,
      relevance: score.dimensions[Dimension.relevance]!,
      specificity: score.dimensions[Dimension.specificity]!,
      structure: score.dimensions[Dimension.structure]!,
      adaptability: score.dimensions[Dimension.adaptability]!,
      total: score.total,
      hinted: a.hinted,
      flags: [for (final f in score.flags) f.wireName]..sort(),
      completedAt: a.completedAt,
      attemptNumber: a.attemptNumber,
      seed: a.seed,
      beatOptionIds: a.beatOptionIds,
      followUpId: a.followUpId,
      replyOptionId: a.replyOptionId,
    );

/// A restored attempt as the device stores it (no draft: it never left the old device).
StoredAttempt storedAttempt(RemoteAttempt a) => StoredAttempt(
  attemptId: a.attemptId,
  missionId: a.missionId,
  attemptNumber: a.attemptNumber,
  seed: a.seed,
  beatOptionIds: a.beatOptionIds,
  followUpId: a.followUpId,
  replyOptionId: a.replyOptionId,
  hinted: a.hinted,
  completedAt: a.completedAt,
  contentSchemaVersion: a.contentSchemaVersion,
);

RemoteProfile remoteProfile(PlayerProfile p) => RemoteProfile(
  firstName: p.firstName,
  experience: p.experience?.name,
  targetRole: p.targetRole?.name,
  nervesLevel: p.nervesLevel,
  calmMode: p.calmMode,
  weeklyGoal: p.weeklyGoal,
  autoAdvance: p.autoAdvance,
  onboarded: p.onboarded,
  chapter2WaitlistAt: p.waitlistJoinedAt,
);

PlayerProfile playerProfile(RemoteProfile r) => PlayerProfile(
  firstName: r.firstName,
  experience: enumByName(Experience.values, r.experience),
  targetRole: enumByName(TargetRole.values, r.targetRole),
  nervesLevel: r.nervesLevel,
  calmMode: r.calmMode,
  weeklyGoal: r.weeklyGoal,
  autoAdvance: r.autoAdvance,
  onboarded: r.onboarded,
  waitlistJoinedAt: r.chapter2WaitlistAt,
);
