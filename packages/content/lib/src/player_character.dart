import 'identified.dart';

/// The candidate the player plays (owner's writing notes, 2026-10-30): a fresh graduate with a
/// fixed set of facts. Every answer line in every mission draws on the same facts, so the
/// story stays consistent from Mission 1 to Mission 7, and the review missions can call back
/// to it.
class PlayerCharacter {
  const PlayerCharacter({
    required this.name,
    required this.premise,
    required this.facts,
    required this.figures,
  });

  final String name;

  /// Shown before Mission 1: who you play, in one or two sentences.
  final String premise;

  final List<CharacterFact> facts;

  /// Every figure written in digits that a line may quote ("600", "40%"). A test fails on any
  /// other, so a number can't drift between missions.
  final Set<String> figures;
}

/// One thing that's true about the candidate.
class CharacterFact implements Identified {
  const CharacterFact({
    required this.id,
    required this.label,
    required this.detail,
    required this.markers,
  });

  @override
  final String id;

  /// What the fact is about: "Degree", "Internship"…
  final String label;

  /// The fact in full, for writers, the character card and the AI coach.
  final String detail;

  /// Words a line uses when it draws on this fact ("Larkfield", "café"). A test checks that
  /// every mission draws on the sheet through them.
  final List<String> markers;
}
