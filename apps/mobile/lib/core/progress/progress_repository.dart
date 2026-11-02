import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One finished mission attempt: what was picked, in what order it was shown, and how the
/// engine scored it. Enough to replay the attempt and to recompute its score offline.
class AttemptRecord {
  const AttemptRecord({
    required this.missionId,
    required this.attemptNumber,
    required this.seed,
    required this.beatOptionIds,
    required this.followUpId,
    required this.replyOptionId,
    required this.score,
    required this.hinted,
    this.draft,
    this.attemptId,
    this.completedAt,
    this.beatPlays = const [],
  });

  final String missionId;

  /// 1 for the player's first attempt at this mission.
  final int attemptNumber;

  /// The seed the options were shuffled with (`shuffledOrder`), so a replay shows the same order.
  final int seed;

  /// One option id per beat, in beat order.
  final List<String> beatOptionIds;
  final String followUpId;
  final String replyOptionId;
  final MissionScore score;
  final bool hinted;

  /// How each beat was played, in beat order: the reason given and the time taken. The score
  /// depends on both (wave 5), so a stored attempt keeps them to be scored again the same way.
  /// Empty for an attempt stored before brief 30: it rescores at full credit, as it did then.
  final List<BeatPlayRecord> beatPlays;

  /// The player's own words from the draft-first step (FR-11), or null if skipped. It stays on
  /// the device: never logged, never sent as an event.
  final String? draft;

  /// The device-generated id the server deduplicates on. A store assigns it when it records the
  /// attempt; null on a record that hasn't been stored.
  final String? attemptId;

  /// When the player finished, by the device's clock. Set by the store, like [attemptId].
  final DateTime? completedAt;

  @override
  String toString() =>
      'AttemptRecord($missionId #$attemptNumber, total ${score.total})';
}

/// One beat as it was played: the reason given ("why that line?"; null where none was asked)
/// and how long the player took to pick (null where it wasn't measured).
class BeatPlayRecord {
  const BeatPlayRecord({this.reasonId, this.decidedIn});

  final String? reasonId;
  final Duration? decidedIn;

  /// The stored and synced shape (`beat_plays`), microseconds so a rescore crosses the guess
  /// threshold exactly where the live score did.
  Map<String, Object?> toJson() => {
    'reason_id': reasonId,
    'decided_us': decidedIn?.inMicroseconds,
  };

  /// Reads [toJson]'s shape; anything malformed reads as "not recorded".
  static BeatPlayRecord fromJson(Object? json) {
    if (json is! Map) return const BeatPlayRecord();
    final reason = json['reason_id'];
    final us = json['decided_us'];
    return BeatPlayRecord(
      reasonId: reason is String ? reason : null,
      decidedIn: us is int ? Duration(microseconds: us) : null,
    );
  }

  /// A list of [fromJson]s from a decoded `beat_plays` value; empty for anything else.
  static List<BeatPlayRecord> listFrom(Object? json) =>
      json is List ? [for (final p in json) fromJson(p)] : const [];
}

/// Where the player's progress is kept. [InMemoryProgressRepository] for tests and the catalog;
/// the app overrides [progressRepositoryProvider] with the drift store (`main.dart`), so
/// progress survives a restart and syncs, and no screen changes.
abstract interface class ProgressRepository {
  /// Stores a finished attempt.
  Future<void> recordAttempt(AttemptRecord attempt);

  /// Every stored attempt, oldest first; only [missionId]'s when it's given.
  Future<List<AttemptRecord>> attempts({String? missionId});

  /// The first completed attempt at the baseline mission (Mission 1), every later score's
  /// reference point (FR-30), or null before it's played.
  Future<AttemptRecord?> baseline();
}

/// Progress for this run of the app only (tests, and the default before `main.dart` overrides).
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository({String? baselineMissionId})
    : _baselineMissionId =
          baselineMissionId ?? missions.firstWhere((m) => m.isBaseline).id;

  final String _baselineMissionId;
  final List<AttemptRecord> _attempts = [];

  @override
  Future<void> recordAttempt(AttemptRecord attempt) async =>
      _attempts.add(attempt);

  @override
  Future<List<AttemptRecord>> attempts({String? missionId}) async =>
      List.unmodifiable(
        missionId == null
            ? _attempts
            : _attempts.where((a) => a.missionId == missionId),
      );

  @override
  Future<AttemptRecord?> baseline() async {
    for (final attempt in _attempts) {
      if (attempt.missionId == _baselineMissionId) return attempt;
    }
    return null;
  }
}

/// The player's progress. Overridden by brief 08 (drift) and in tests.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => InMemoryProgressRepository(),
);
