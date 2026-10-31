import 'package:content/content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/profile/drift_profile_repository.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/drift_progress_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/core/sync/sync_worker.dart';

import '../../features/tower/played_attempt.dart';
import '../backend/fakes.dart';
import '../db/db_support.dart';

void main() {
  late AppDatabase db;
  late FakeBackend server;
  late CapturedLog log;
  late OutboxSignal signal;
  late DateTime now;
  late DriftProgressRepository progress;
  late DriftProfileRepository profiles;
  var restored = 0;

  SyncWorker worker() => SyncWorker(
    db: db,
    backend: server,
    log: log.log,
    signal: signal,
    onRestored: () => restored++,
    clock: () => now,
  );

  setUp(() {
    db = memoryDb();
    server = FakeBackend();
    log = CapturedLog();
    signal = OutboxSignal();
    now = DateTime.utc(2026, 10, 31, 9);
    restored = 0;
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

  test(
    'an attempt reaches the server once, however often it is flushed',
    () async {
      await progress.recordAttempt(playedAttempt(missions[0]));
      final w = worker();
      await w.flush();
      // The same attempt queued and sent again (a retry after a lost response).
      final id = (await progress.attempts()).single.attemptId!;
      await Outbox(db).add(OutboxKind.attempt, id);
      await w.flush();
      await w.dispose();
      expect(server.attempts, hasLength(1));
      expect(server.attempts.keys.single, id);
      expect(await rows(db, 'outbox'), 0);
    },
  );

  test(
    'the server row carries the engine score and the picks, never the draft',
    () async {
      final played = playedAttempt(missions[0]);
      await progress.recordAttempt(
        AttemptRecord(
          missionId: played.missionId,
          attemptNumber: played.attemptNumber,
          seed: played.seed,
          beatOptionIds: played.beatOptionIds,
          followUpId: played.followUpId,
          replyOptionId: played.replyOptionId,
          score: played.score,
          hinted: played.hinted,
          draft: 'my own private words',
        ),
      );
      final w = worker();
      await w.flush();
      await w.dispose();
      final row = server.attempts.values.single;
      expect(row.total, played.score.total);
      expect(row.beatOptionIds, played.beatOptionIds);
      expect(
        row.toRow().values.map((v) => '$v').join(),
        isNot(contains('private')),
      );
    },
  );

  test('offline, then online: it waits with backoff, then sends', () async {
    server.online = false;
    await progress.recordAttempt(playedAttempt(missions[0]));
    final w = worker();
    await w.flush();
    expect(server.attempts, isEmpty);
    expect(log.at(LogLevel.warn), isNotEmpty, reason: 'a warn, never an error');
    expect(log.at(LogLevel.error), isEmpty);

    server.online = true;
    await w.flush();
    expect(
      server.attempts,
      isEmpty,
      reason: 'not due yet: no tight retry loop',
    );

    now = now.add(Outbox.backoff(1));
    await w.flush();
    await w.dispose();
    expect(server.attempts, hasLength(1));
  });

  test('a long backlog goes in batches', () async {
    for (var i = 0; i < Outbox.batchSize + 5; i++) {
      await progress.recordAttempt(playedAttempt(missions[0], attempt: i + 1));
    }
    final w = worker();
    await w.flush();
    await w.dispose();
    expect(server.attemptBatches, [Outbox.batchSize, 5]);
    expect(server.attempts, hasLength(Outbox.batchSize + 5));
  });

  test('queuing something makes a started worker send it', () async {
    final w = worker();
    await w.start();
    await progress.recordAttempt(playedAttempt(missions[0]));
    await profiles.save(
      const PlayerProfile(firstName: 'Sami', onboarded: true),
    );
    await Future<void>.delayed(Duration.zero);
    await w.flush();
    await w.dispose();
    expect(server.attempts, hasLength(1));
    expect(server.profile?.firstName, 'Sami');
  });

  test('the name is never in a log line', () async {
    server.online = false;
    await profiles.save(
      const PlayerProfile(firstName: 'Sami', onboarded: true),
    );
    final w = worker();
    await w.flush();
    await w.dispose();
    for (final r in log.records) {
      expect('${r.message} ${r.fields}', isNot(contains('Sami')));
    }
  });

  group('restore on a fresh install', () {
    setUp(() {
      final played = playedAttempt(missions[0]);
      server.attempts['11111111-0000-4000-8000-000000000001'] = remoteAttempt(
        storedFrom(played, '11111111-0000-4000-8000-000000000001', now),
        played.score,
      );
      server.profile = const RemoteProfile(
        firstName: 'Sami',
        nervesLevel: 4,
        calmMode: true,
        onboarded: true,
      );
    });

    test('an empty database pulls attempts and profile once', () async {
      final w = worker();
      await w.start();
      await w.dispose();
      expect((await progress.attempts()).single.missionId, missions[0].id);
      final p = await profiles.load();
      expect(p.firstName, 'Sami');
      expect(p.calmMode, isTrue);
      expect(restored, 1);
      expect(
        await rows(db, 'outbox'),
        0,
        reason: 'restored rows aren\'t re-sent',
      );

      final again = worker();
      await again.start();
      await again.dispose();
      expect(server.fetches, 1, reason: 'once');
    });

    test('a device that already has progress is never overwritten', () async {
      await progress.recordAttempt(playedAttempt(missions[1]));
      final w = worker();
      await w.start();
      await w.dispose();
      expect(server.fetches, 0);
      expect((await progress.attempts()).map((a) => a.missionId), [
        missions[1].id,
      ]);
    });

    test('a failed restore is tried again on the next start', () async {
      server.online = false;
      final w = worker();
      await w.start();
      await w.dispose();
      server.online = true;
      final again = worker();
      await again.start();
      await again.dispose();
      expect(await progress.attempts(), hasLength(1));
    });
  });

  test('no keys, no session: the sync worker is never built', () {
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(emptyEnv),
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(syncWorkerProvider), isNull);
  });
}

/// The stored form of [played], as the old device held it.
StoredAttempt storedFrom(AttemptRecord played, String id, DateTime at) =>
    StoredAttempt(
      attemptId: id,
      missionId: played.missionId,
      attemptNumber: played.attemptNumber,
      seed: played.seed,
      beatOptionIds: played.beatOptionIds,
      followUpId: played.followUpId,
      replyOptionId: played.replyOptionId,
      hinted: played.hinted,
      completedAt: at,
    );
