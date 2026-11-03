import 'dart:io';
import 'dart:math' as math;

import 'package:content/content.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/backend/remote_rows.dart';
import 'package:the_last_room/core/db/app_database.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/progress/attempt_score.dart';
import 'package:the_last_room/core/progress/drift_progress_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/core/sync/sync_worker.dart';

import '../../features/mission/mission_harness.dart';
import '../db/db_support.dart';

/// Brief 30's playthrough: Mission 1 scored 71 on the debrief (an unsound reason) and 77 on
/// the tower, Mission 2 scored 32 (a guess) and 54. A stored attempt must keep how each beat was
/// played, so every screen shows the score the debrief showed.
void main() {
  final mission = missions.first;
  final followUp = mission.followUps.firstWhere((f) => f.trigger == null);
  final strongest = [
    for (final b in mission.beats)
      b.options.firstWhere((o) => b.isStrongest(o.id)),
  ];
  Reason unsound(Beat b, AnswerOption o) =>
      b.why!.reasons.firstWhere((r) => !r.isSoundFor(o.id));
  Reason sound(Beat b, AnswerOption o) =>
      b.why!.reasons.firstWhere((r) => r.isSoundFor(o.id));

  // The open beat with the wrong principle, the evidence beat guessed, the land beat right.
  final plays = [
    BeatPlayRecord(
      reasonId: unsound(mission.beats[0], strongest[0]).id,
      decidedIn: const Duration(seconds: 4),
    ),
    BeatPlayRecord(
      reasonId: sound(mission.beats[1], strongest[1]).id,
      decidedIn: const Duration(milliseconds: 900),
    ),
    BeatPlayRecord(
      reasonId: sound(mission.beats[2], strongest[2]).id,
      decidedIn: const Duration(seconds: 3),
    ),
  ];

  /// The debrief's score: the engine on the live picks.
  final live = scoreAttempt(
    AttemptInput(
      picks: [
        for (var i = 0; i < mission.beats.length; i++)
          BeatPick(
            beat: mission.beats[i].kind,
            choice: strongest[i].scored,
            decidedIn: plays[i].decidedIn,
            reason: mission.beats[i].reasonPick(
              mission.beats[i].why!.reasons.firstWhere(
                (r) => r.id == plays[i].reasonId,
              ),
              strongest[i].id,
            ),
          ),
      ],
      followUpReply: followUp.replies.first.scored,
      hinted: mission.hinted,
    ),
  );

  final record = AttemptRecord(
    missionId: mission.id,
    attemptNumber: 1,
    seed: testSeed,
    beatOptionIds: [for (final o in strongest) o.id],
    followUpId: followUp.id,
    replyOptionId: followUp.replies.first.id,
    score: live,
    hinted: mission.hinted,
    beatPlays: plays,
  );

  test('the live score really is lowered by the reason and the guess', () {
    final fullCredit = scoreFromPicks(
      missionId: mission.id,
      beatOptionIds: record.beatOptionIds,
      followUpId: followUp.id,
      replyOptionId: record.replyOptionId,
      hinted: mission.hinted,
    )!;
    expect(live.total, lessThan(fullCredit.total));
    expect(live.guessed, isTrue);
  });

  test('scoreFromPicks with the beat plays gives the debrief\'s score', () {
    expect(
      scoreFromPicks(
        missionId: mission.id,
        beatOptionIds: record.beatOptionIds,
        followUpId: followUp.id,
        replyOptionId: record.replyOptionId,
        hinted: mission.hinted,
        beatPlays: plays,
      ),
      live,
    );
  });

  test('the device store reads back the debrief\'s score', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = DriftProgressRepository(
      db,
      log: Log(sink: (_) {}),
      clock: () => DateTime.utc(2026, 11, 2, 9),
      random: math.Random(1),
    );
    await repo.recordAttempt(record);
    final back = (await repo.attempts()).single;
    expect(back.score, live);
    expect(back.beatPlays.map((p) => p.reasonId), plays.map((p) => p.reasonId));
    expect(back.beatPlays[1].decidedIn, const Duration(milliseconds: 900));
  });

  test('the server row carries the plays, and a restore scores the same', () {
    final stored = StoredAttempt(
      attemptId: 'a',
      missionId: mission.id,
      attemptNumber: 1,
      seed: testSeed,
      beatOptionIds: record.beatOptionIds,
      followUpId: followUp.id,
      replyOptionId: record.replyOptionId,
      hinted: mission.hinted,
      completedAt: DateTime.utc(2026, 11, 2, 9),
      beatPlays: plays,
    );
    final row = remoteAttempt(stored, live).toRow();
    expect(row['beat_plays'], hasLength(3));
    final restored = storedAttempt(RemoteAttempt.fromRow(row)!);
    expect(restored.toRecord()!.score, live);
  });

  test('a row synced before brief 30 (no plays) restores at full credit, as before', () {
    final stored = StoredAttempt(
      attemptId: 'b',
      missionId: mission.id,
      attemptNumber: 1,
      seed: testSeed,
      beatOptionIds: record.beatOptionIds,
      followUpId: followUp.id,
      replyOptionId: record.replyOptionId,
      hinted: mission.hinted,
      completedAt: DateTime.utc(2026, 11, 2, 9),
    );
    final row = remoteAttempt(stored, live).toRow();
    expect(row.containsKey('beat_plays'), isFalse);
    expect(storedAttempt(RemoteAttempt.fromRow(row)!).beatPlays, isEmpty);
  });

  group('reason XP is rescored from the stored picks (brief 55)', () {
    test('the stored attempt earns the debrief\'s reason XP, once', () {
      // Open: the wrong principle (close, 5); evidence guessed (0); land: sound (10).
      expect(live.reasonVerdicts, [
        ReasonVerdict.close,
        ReasonVerdict.guessed,
        ReasonVerdict.sound,
      ]);
      expect(reasonXp(live), 15);
      final again = scoreFromPicks(
        missionId: mission.id,
        beatOptionIds: record.beatOptionIds,
        followUpId: followUp.id,
        replyOptionId: record.replyOptionId,
        hinted: mission.hinted,
        beatPlays: plays,
      )!;
      expect(reasonXp(again), reasonXp(live));
    });

    test('an attempt stored before brief 30 earns no reason XP', () {
      final old = scoreFromPicks(
        missionId: mission.id,
        beatOptionIds: record.beatOptionIds,
        followUpId: followUp.id,
        replyOptionId: record.replyOptionId,
        hinted: mission.hinted,
      )!;
      expect(old.reasonVerdicts, isEmpty);
      expect(reasonXp(old), 0);
    });

    test('a reason an older build stored on a built beat keeps its score but earns nothing', () {
      final m = missions.firstWhere((m) => m.beats.any((b) => b.build != null));
      final reply = m.followUps.firstWhere((f) => f.trigger == null);
      final ids = [
        for (final b in m.beats)
          b.build?.strongAnswer.id ??
              b.options.firstWhere((o) => b.isStrongest(o.id)).id,
      ];
      // A sound reason everywhere a why is asked; on the built beat, a wrong one (QA 51).
      final stored = [
        for (var i = 0; i < m.beats.length; i++)
          BeatPlayRecord(
            reasonId: m.beats[i].build == null
                ? m.beats[i].why!.reasons
                      .firstWhere((r) => r.isSoundFor(ids[i]))
                      .id
                : m.beats[i].why!.reasons
                      .firstWhere((r) => !r.isSoundFor(ids[i]))
                      .id,
            decidedIn: const Duration(seconds: 4),
          ),
      ];
      final rescored = scoreFromPicks(
        missionId: m.id,
        beatOptionIds: ids,
        followUpId: reply.id,
        replyOptionId: reply.replies.first.id,
        hinted: m.hinted,
        beatPlays: stored,
      )!;
      // As scored when it was played: the reason kept on the built beat.
      final asPlayed = scoreAttempt(
        AttemptInput(
          picks: [
            for (var i = 0; i < m.beats.length; i++)
              BeatPick(
                beat: m.beats[i].kind,
                choice: m.beats[i].optionById(ids[i])!.scored,
                decidedIn: stored[i].decidedIn,
                reason: m.beats[i].reasonPick(
                  m.beats[i].why!.reasons.firstWhere(
                    (r) => r.id == stored[i].reasonId,
                  ),
                  ids[i],
                ),
              ),
          ],
          followUpReply: reply.replies.first.scored,
          hinted: m.hinted,
        ),
      );
      expect(rescored.total, asPlayed.total);
      expect(rescored.beatCredits, asPlayed.beatCredits);
      final asked = m.beats.where((b) => b.build == null).length;
      expect(rescored.reasonVerdicts, List.filled(asked, ReasonVerdict.sound));
      expect(reasonXp(rescored), asked * reasonSoundXp);
    });
  });

  test(
    'a version-1 database upgrades in place and keeps its attempts',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final dir = await Directory.systemTemp.createTemp('upgrade');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/v1.sqlite');

      // Version 1 exactly as shipped: the schema, user_version 1, one attempt row.
      final v1 = _V1Database(NativeDatabase(file));
      await v1.customStatement(
        'insert into attempts (attempt_id, mission_id, attempt_number, seed, beat_option_ids, '
        'follow_up_id, reply_option_id, hinted, completed_at, content_schema_version) '
        "values ('old', ?, 1, 42, ?, ?, ?, 0, 0, 1)",
        [
          mission.id,
          '["${record.beatOptionIds.join('","')}"]',
          followUp.id,
          record.replyOptionId,
        ],
      );
      await v1.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final repo = DriftProgressRepository(db, log: Log(sink: (_) {}));
      final old = (await repo.attempts()).single;
      expect(old.beatPlays, isEmpty);
      expect(
        old.score.guessed,
        isFalse,
        reason: 'a version-1 row scores at full credit',
      );
      await repo.recordAttempt(record);
      expect((await repo.attempts()).last.score, live);
    },
  );
}

/// The device database as version 1 shipped it: [AppDatabase.schema], nothing after.
class _V1Database extends GeneratedDatabase {
  _V1Database(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final statement in AppDatabase.schema) {
        await customStatement(statement);
      }
    },
  );
}
