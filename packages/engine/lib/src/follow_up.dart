import 'beat.dart';
import 'flag.dart';

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
String selectFollowUp({
  required List<BeatPick> picks,
  required List<FollowUpCandidate> candidates,
}) => throw UnimplementedError();
