import 'beat.dart';
import 'flag.dart';
import 'line_cost.dart';

/// A follow-up the content offers for a mission, as the engine sees it.
class FollowUpCandidate {
  const FollowUpCandidate({required this.id, this.trigger});

  final String id;

  /// The flag this follow-up answers ("What did *you* specifically do?" for [Flag.weNotI]).
  /// `null` marks the mission's default, asked when no flag matches.
  final Flag? trigger;
}

/// Picks the interviewer's follow-up from the weakest part of the answer (FR-14).
///
/// Returns the id of the candidate whose [FollowUpCandidate.trigger] is a flag on the weakest
/// pick (lowest weighted score; ties go to the earliest beat). If that pick has no flag with a
/// candidate, the next weakest is tried, then the default. Content validation guarantees every
/// mission has a default, so this always returns an id.
///
/// "Weakest" is the largest weighted shortfall on relevance, specificity and structure, the
/// same measure that orders `MissionScore.optionIdsByCost`, so the interviewer probes the line
/// the debrief marks. When one pick carries two flags that both have a follow-up, the one
/// listed first in [candidates] wins: the content author sets the priority.
///
/// Throws a [StateError] if no flag matches and [candidates] has no default.
String selectFollowUp({
  required List<BeatPick> picks,
  required List<FollowUpCandidate> candidates,
}) {
  final shortfalls = [
    for (final pick in picks) weightedShortfall(pick.choice, beatDimensions),
  ];
  for (final index in indexesByCost(shortfalls)) {
    final flags = picks[index].choice.flags;
    for (final candidate in candidates) {
      final trigger = candidate.trigger;
      if (trigger != null && flags.contains(trigger)) return candidate.id;
    }
  }
  for (final candidate in candidates) {
    if (candidate.trigger == null) return candidate.id;
  }
  throw StateError('no follow-up matched and there is no default');
}
