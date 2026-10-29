import 'dimension.dart';

/// One answer option's points: 0–3 on each of the four dimensions (brief §4, FR-20).
///
/// Every option carries all four, so a missing score can't exist. The range is checked by
/// [isInRange] (the content validator runs it over every option) rather than by the
/// constructor, so a bad value is reported with the option's id instead of crashing a test.
class DimensionScores {
  const DimensionScores({
    required this.relevance,
    required this.specificity,
    required this.structure,
    required this.adaptability,
  });

  final int relevance;
  final int specificity;
  final int structure;

  /// Only follow-up replies count towards adaptability (brief §4); on beat options the
  /// engine ignores it.
  final int adaptability;

  /// The highest score an option can earn on one dimension.
  static const int max = 3;

  int operator [](Dimension dimension) => switch (dimension) {
    Dimension.relevance => relevance,
    Dimension.specificity => specificity,
    Dimension.structure => structure,
    Dimension.adaptability => adaptability,
  };

  /// Whether every dimension is within 0–[max].
  bool get isInRange =>
      Dimension.values.every((d) => this[d] >= 0 && this[d] <= max);
}
