import 'package:content/content.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/progress/attempt_score.dart';
import 'package:the_last_room/core/progress/drift_progress_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/core/sync/sync_worker.dart';

import '../../features/voice/voice_fixture.dart';
import '../backend/fakes.dart';
import '../db/db_support.dart';

/// The shipped missions and the voice fixture (brief 37's Chapter 2 isn't here yet).
const List<Mission> catalog = [...missions, voiceFixture];

/// A voice attempt that made two of the fixture's four points.
AttemptRecord voiceAttempt({VoiceScoreSource source = VoiceScoreSource.ai}) =>
    AttemptRecord.voice(
      missionId: voiceFixture.id,
      attemptNumber: 1,
      hinted: true,
      score: voiceScoreFor(voiceFixture, const [
        'm08_names_change',
        'm08_owns_it',
      ])!.score,
      voice: VoiceAnswerRecord(
        madePointIds: const ['m08_names_change', 'm08_owns_it'],
        source: source,
        seconds: 52,
      ),
    );

void main() {
  late AppDatabase db;
  late CapturedLog log;
  late OutboxSignal signal;
  final now = DateTime.utc(2026, 11, 2, 18);

  setUp(() {
    db = memoryDb();
    log = CapturedLog();
    signal = OutboxSignal();
  });
  tearDown(() async {
    await signal.close();
    await db.close();
  });

  DriftProgressRepository repo(AppDatabase on) => DriftProgressRepository(
    on,
    log: log.log,
    signal: signal,
    clock: () => now,
    catalog: catalog,
  );

  test(
    'a voice attempt is stored, queued, and read back scored by the engine',
    () async {
      await repo(db).recordAttempt(voiceAttempt());
      final read = (await repo(db).attempts()).single;
      expect(read.voice!.madePointIds, ['m08_names_change', 'm08_owns_it']);
      expect(read.voice!.source, VoiceScoreSource.ai);
      expect(read.voice!.seconds, 52);
      expect(read.beatOptionIds, isEmpty);
      expect(read.score, voiceAttempt().score);
      expect(await rows(db, 'outbox'), 1);
    },
  );

  test(
    'a voice row whose mission is gone is skipped, never mis-scored',
    () async {
      await repo(db).recordAttempt(voiceAttempt());
      final shipped = DriftProgressRepository(db, log: log.log);
      expect(await shipped.attempts(), isEmpty);
    },
  );

  test('a version-2 database upgrades with its attempts intact', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final s in [
            ...AppDatabase.schema,
            ...AppDatabase.upgrades.first,
          ]) {
            raw.execute(s);
          }
          raw.execute('pragma user_version = 2');
        },
      ),
    );
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(old.close);
    await repo(old).recordAttempt(voiceAttempt());
    expect((await repo(old).attempts()).single.voice, isNotNull);
    expect(AppDatabase(NativeDatabase.memory()).schemaVersion, 3);
  });

  test('the server row carries the points, never picks, audio or words', () {
    final stored = StoredAttempt(
      attemptId: 'a1',
      missionId: voiceFixture.id,
      attemptNumber: 1,
      seed: 0,
      beatOptionIds: const [],
      followUpId: '',
      replyOptionId: '',
      hinted: true,
      completedAt: now,
      voice: voiceAttempt().voice,
    );
    final row = remoteAttempt(stored, voiceAttempt().score).toRow();
    expect(row['voice_answer'], {
      'made': ['m08_names_change', 'm08_owns_it'],
      'source': 'ai',
      'seconds': 52,
    });
    expect(row.keys, isNot(contains('beat_option_ids')));
    expect(row.keys, isNot(contains('follow_up_id')));
    expect(row.keys, isNot(contains('reply_option_id')));
    expect(row['total_score'], voiceAttempt().score.total);
  });

  test('a server voice row reads back, and restores to the same score', () {
    final row = <String, Object?>{
      'attempt_id': 'a1',
      'mission_id': voiceFixture.id,
      'content_schema_version': 2,
      'relevance_score': 100,
      'specificity_score': 0,
      'structure_score': 0,
      'adaptability_score': 100,
      'total_score': 45,
      'hinted': true,
      'flags': const <Object?>[],
      'completed_at': '2026-11-02T18:00:00Z',
      'attempt_number': 1,
      'seed': 0,
      'beat_option_ids': null,
      'follow_up_id': null,
      'reply_option_id': null,
      'voice_answer': {
        'made': ['m08_names_change', 'm08_owns_it'],
        'source': 'self_check',
        'seconds': 12,
      },
    };
    final remote = RemoteAttempt.fromRow(row)!;
    final record = storedAttempt(remote).toRecord(catalog: catalog)!;
    expect(record.voice!.source, VoiceScoreSource.selfCheck);
    expect(record.score.total, 45);
  });

  test(
    'the sync worker sends a voice attempt, and a fresh device restores it',
    () async {
      final server = FakeBackend();
      await repo(db).recordAttempt(voiceAttempt());
      final worker = SyncWorker(
        db: db,
        backend: server,
        log: log.log,
        signal: signal,
        clock: () => now,
        catalog: catalog,
      );
      addTearDown(worker.dispose);
      await worker.start();
      final sent = server.attempts.values.single;
      expect(sent.voiceAnswer!['source'], 'ai');
      expect(await rows(db, 'outbox'), 0);

      final fresh = memoryDb();
      addTearDown(fresh.close);
      final again = SyncWorker(
        db: fresh,
        backend: server,
        log: log.log,
        signal: signal,
        clock: () => now,
        catalog: catalog,
      );
      addTearDown(again.dispose);
      await again.start();
      final restored = (await repo(fresh).attempts()).single;
      expect(restored.voice!.madePointIds, ['m08_names_change', 'm08_owns_it']);
      expect(restored.score, voiceAttempt().score);
    },
  );
}
