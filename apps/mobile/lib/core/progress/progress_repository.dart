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

  /// The player's own words from the draft-first step (FR-11), or null if skipped. It stays on
  /// the device: never logged, never sent as an event.
  final String? draft;

  @override
  String toString() =>
      'AttemptRecord($missionId #$attemptNumber, total ${score.total})';
}

/// Where the player's progress is kept. Brief 10 ships [InMemoryProgressRepository]; brief 08
/// implements this on drift and overrides [progressRepositoryProvider], and no screen changes.
abstract interface class ProgressRepository {
  /// Stores a finished attempt.
  Future<void> recordAttempt(AttemptRecord attempt);

  /// Every stored attempt, oldest first; only [missionId]'s when it's given.
  Future<List<AttemptRecord>> attempts({String? missionId});

  /// The first completed attempt at the baseline mission (Mission 1), every later score's
  /// reference point (FR-30), or null before it's played.
  Future<AttemptRecord?> baseline();
}

/// Progress for this run of the app only: lost on restart until brief 08's drift store lands.
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
