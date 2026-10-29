import 'dimension.dart';

/// The closed set of mistakes an answer line can carry (brief §3, FR-21). A content author
/// tags each option with any of these; the enum makes any other flag a compile error.
///
/// A flag doesn't subtract points on its own: the option's 0–3 scores already price the
/// mistake. Instead the content validator holds a flagged option to at most
/// [flaggedDimensionCeiling] on [lowers], so "this flag lowers that dimension" is checked,
/// not double-counted. Flags also pick the follow-up and the debrief lesson.
enum Flag {
  vague('vague', lowers: Dimension.specificity),
  weNotI('we_not_i', lowers: Dimension.specificity),
  generic('generic', lowers: Dimension.specificity),

  /// Pointing at someone else answers a different question from "what was *your* part".
  blame('blame', lowers: Dimension.relevance),
  offQuestion('off_question', lowers: Dimension.relevance),
  rambling('rambling', lowers: Dimension.structure),
  memorized('memorized', lowers: Dimension.structure);

  const Flag(this.wireName, {required this.lowers});

  /// The name used in content files, the database and analytics.
  final String wireName;

  /// The dimension an option carrying this flag is capped on.
  final Dimension lowers;
}

/// The highest score a flagged option may have on the dimension its flag lowers.
const int flaggedDimensionCeiling = 1;
