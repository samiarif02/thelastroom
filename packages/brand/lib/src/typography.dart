import 'package:flutter/painting.dart';

import 'colors.dart';

/// Type tokens. A dramatic display serif for titles, chapter cards and interviewer names; a
/// clean sans for body and choices; tabular figures for scores (brief §9).
///
/// PROVISIONAL: these use the platform fonts until the design session bundles the OFL display
/// serif and body sans in this package (set `fontFamily` and `package: 'brand'` on each style).
/// Bundled, never fetched at runtime.
abstract final class BrandType {
  /// Chapter title cards ("CHAPTER ONE — GET THROUGH THE DOOR").
  static const TextStyle titleCard = TextStyle(
    fontSize: 40,
    height: 1.1,
    letterSpacing: 6,
    fontWeight: FontWeight.w400,
    color: BrandColors.textPrimary,
  );

  /// Screen titles and interviewer names.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 1.2,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w400,
    color: BrandColors.textPrimary,
  );

  /// Body copy, choices, subtitles.
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 1.45,
    color: BrandColors.textPrimary,
  );

  /// Small caps labels: the speaker's name, eyebrows.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.3,
    letterSpacing: 2.4,
    fontWeight: FontWeight.w600,
    color: BrandColors.textSecondary,
  );

  /// Scores and counters: tabular figures so digits don't jitter while they tick.
  static const TextStyle score = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: BrandColors.textPrimary,
  );
}
