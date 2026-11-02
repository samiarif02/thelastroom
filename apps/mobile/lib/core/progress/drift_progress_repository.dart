import 'dart:convert';
import 'dart:math' as math;

import 'package:content/content.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/ids.dart';
import '../logging/log.dart';
import '../sync/outbox.dart';
import 'attempt_score.dart';
import 'progress_repository.dart';

/// [ProgressRepository] on the device's database: attempts survive a restart, and each one is
/// queued for the server in the same transaction that stores it.
class DriftProgressRepository implements ProgressRepository {
  DriftProgressRepository(
    this._db, {
    required this._log,
    this._signal,
    DateTime Function()? clock,
    math.Random? random,
    String? baselineMissionId,
    this._catalog = missions,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? math.Random.secure(),
       _baselineMissionId =
           baselineMissionId ?? missions.firstWhere((m) => m.isBaseline).id;

  final AppDatabase _db;
  final Log _log;
  final OutboxSignal? _signal;
  final DateTime Function() _clock;
  final math.Random _random;
  final String _baselineMissionId;

  /// The missions stored attempts are rescored against (tests pass a fixture catalog).
  final List<Mission> _catalog;

  @override
  Future<void> recordAttempt(AttemptRecord attempt) async {
    final id = attempt.attemptId ?? newUuid(_random);
    final completedAt = attempt.completedAt ?? _clock();
    await _db.transaction(() async {
      await insertAttemptRow(
        _db,
        StoredAttempt(
          attemptId: id,
          missionId: attempt.missionId,
          attemptNumber: attempt.attemptNumber,
          seed: attempt.seed,
          beatOptionIds: attempt.beatOptionIds,
          followUpId: attempt.followUpId,
          replyOptionId: attempt.replyOptionId,
          hinted: attempt.hinted,
          draft: attempt.draft,
          completedAt: completedAt,
          beatPlays: attempt.beatPlays,
          voice: attempt.voice,
        ),
      );
      await Outbox(_db).add(OutboxKind.attempt, id);
    });
    _signal?.ping();
  }

  @override
  Future<List<AttemptRecord>> attempts({String? missionId}) async {
    final rows = await _db
        .customSelect(
          'select * from attempts '
          '${missionId == null ? '' : 'where mission_id = ? '}'
          'order by completed_at, rowid',
          variables: [if (missionId != null) Variable.withString(missionId)],
        )
        .get();
    final records = <AttemptRecord>[];
    for (final row in rows) {
      final stored = StoredAttempt.fromRow(row);
      final record = stored.toRecord(catalog: _catalog);
      if (record == null) {
        // Content changed under an old row: skip it rather than show a wrong score.
        _log.warn('stored attempt no longer matches content', {
          'mission_id': stored.missionId,
        });
        continue;
      }
      records.add(record);
    }
    return List.unmodifiable(records);
  }

  @override
  Future<AttemptRecord?> baseline() async {
    final first = await attempts(missionId: _baselineMissionId);
    return first.isEmpty ? null : first.first;
  }

  /// One stored attempt by id, for the sync worker.
  Future<StoredAttempt?> byId(String attemptId) async {
    final row = await _db
        .customSelect(
          'select * from attempts where attempt_id = ?',
          variables: [Variable.withString(attemptId)],
        )
        .getSingleOrNull();
    return row == null ? null : StoredAttempt.fromRow(row);
  }

  /// How many attempts this device holds (the restore runs only on an empty database).
  Future<int> get count async {
    final row = await _db
        .customSelect('select count(*) as n from attempts')
        .getSingle();
    return row.read<int>('n');
  }
}

/// The content version new attempts are recorded against.
const int currentContentVersion = contentSchemaVersion;

/// An attempt as the database holds it: the picks, never the score.
class StoredAttempt {
  const StoredAttempt({
    required this.attemptId,
    required this.missionId,
    required this.attemptNumber,
    required this.seed,
    required this.beatOptionIds,
    required this.followUpId,
    required this.replyOptionId,
    required this.hinted,
    required this.completedAt,
    this.draft,
    this.contentSchemaVersion = currentContentVersion,
    this.beatPlays = const [],
    this.voice,
  });

  factory StoredAttempt.fromRow(QueryRow row) => StoredAttempt(
    attemptId: row.read<String>('attempt_id'),
    missionId: row.read<String>('mission_id'),
    attemptNumber: row.read<int>('attempt_number'),
    seed: row.read<int>('seed'),
    beatOptionIds: [
      for (final id
          in jsonDecode(row.read<String>('beat_option_ids')) as List<Object?>)
        '$id',
    ],
    followUpId: row.read<String>('follow_up_id'),
    replyOptionId: row.read<String>('reply_option_id'),
    hinted: row.read<int>('hinted') == 1,
    draft: row.readNullable<String>('draft'),
    completedAt: DateTime.fromMillisecondsSinceEpoch(
      row.read<int>('completed_at'),
      isUtc: true,
    ),
    contentSchemaVersion: row.read<int>('content_schema_version'),
    beatPlays: switch (row.readNullable<String>('beat_plays')) {
      final json? => BeatPlayRecord.listFrom(jsonDecode(json)),
      null => const [],
    },
    voice: switch (row.readNullable<String>('voice')) {
      final json? => VoiceAnswerRecord.fromJson(jsonDecode(json)),
      null => null,
    },
  );

  final String attemptId;
  final String missionId;
  final int attemptNumber;
  final int seed;
  final List<String> beatOptionIds;
  final String followUpId;
  final String replyOptionId;
  final bool hinted;

  /// The player's own words. Stays on the device: never synced, never logged.
  final String? draft;
  final DateTime completedAt;
  final int contentSchemaVersion;

  /// How each beat was played ([AttemptRecord.beatPlays]); empty on a version-1 row.
  final List<BeatPlayRecord> beatPlays;

  /// A voice mission's answer ([AttemptRecord.voice]); null on a built one.
  final VoiceAnswerRecord? voice;

  /// The record the game reads, scored by the engine; null when the picks (or a voice answer's
  /// mission) no longer match the content in [catalog].
  AttemptRecord? toRecord({List<Mission> catalog = missions}) {
    final voice = this.voice;
    if (voice != null) {
      final score = scoreFromVoice(
        missionId: missionId,
        madePointIds: voice.madePointIds,
        catalog: catalog,
      );
      if (score == null) return null;
      return AttemptRecord.voice(
        missionId: missionId,
        attemptNumber: attemptNumber,
        score: score,
        hinted: hinted,
        voice: voice,
        attemptId: attemptId,
        completedAt: completedAt,
      );
    }
    final score = scoreFromPicks(
      missionId: missionId,
      beatOptionIds: beatOptionIds,
      followUpId: followUpId,
      replyOptionId: replyOptionId,
      hinted: hinted,
      beatPlays: beatPlays,
    );
    if (score == null) return null;
    return AttemptRecord(
      missionId: missionId,
      attemptNumber: attemptNumber,
      seed: seed,
      beatOptionIds: beatOptionIds,
      followUpId: followUpId,
      replyOptionId: replyOptionId,
      score: score,
      hinted: hinted,
      draft: draft,
      attemptId: attemptId,
      completedAt: completedAt,
      beatPlays: beatPlays,
    );
  }
}

/// Inserts [a]; an attempt already stored (same id) is left as it is.
Future<void> insertAttemptRow(AppDatabase db, StoredAttempt a) =>
    db.customStatement(
      'insert into attempts (attempt_id, mission_id, attempt_number, seed, beat_option_ids, '
      'follow_up_id, reply_option_id, hinted, draft, completed_at, content_schema_version, '
      'beat_plays, voice) '
      'values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (attempt_id) do nothing',
      [
        a.attemptId,
        a.missionId,
        a.attemptNumber,
        a.seed,
        jsonEncode(a.beatOptionIds),
        a.followUpId,
        a.replyOptionId,
        if (a.hinted) 1 else 0,
        a.draft,
        a.completedAt.millisecondsSinceEpoch,
        a.contentSchemaVersion,
        if (a.beatPlays.isEmpty)
          null
        else
          jsonEncode([for (final p in a.beatPlays) p.toJson()]),
        switch (a.voice) {
          final voice? => jsonEncode(voice.toJson()),
          null => null,
        },
      ],
    );
