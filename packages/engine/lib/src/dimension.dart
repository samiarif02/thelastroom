/// The four scoring dimensions and their weights (brief §4).
///
/// The weights are a hypothesis, not a validated rubric: validating them needs human-rated
/// samples, and the README says so.
enum Dimension {
  relevance(weightPercent: 25),
  specificity(weightPercent: 30),
  structure(weightPercent: 25),
  adaptability(weightPercent: 20);

  const Dimension({required this.weightPercent});

  /// This dimension's share of a mission score, in percent. All four sum to 100.
  final int weightPercent;
}
