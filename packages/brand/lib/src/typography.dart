import 'package:flutter/painting.dart';

import 'colors.dart';

/// The bundled families (SIL OFL 1.1, in `fonts/`, never fetched at runtime).
abstract final class BrandFonts {
  /// The display serif: titles, names, subtitles, scores, the pen.
  static const String display = 'CormorantGaramond';

  /// The body sans: body copy, choices, labels.
  static const String sans = 'Manrope';

  /// Fonts live in this package, so every style names it.
  static const String package = 'brand';
}

/// The type ramp: Cormorant Garamond for everything spoken or engraved, Manrope for everything
/// read. Colours are the default use; components re-colour a style from the grade or the paper
/// (`style.copyWith(color: grade.key)`), always to an AA-tested pair.
abstract final class BrandType {
  /// "CHAPTER ONE" and "NORTHSTAR LABS" above a title: tracked sans caps in the accent.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 10.5,
    height: 1.4,
    letterSpacing: 4.2,
    fontWeight: FontWeight.w600,
    color: _accent,
  );

  /// The chapter title card: serif caps, tracked wide. Set in capitals by the caller.
  static const TextStyle titleCard = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontSize: 40,
    height: 1.15,
    letterSpacing: 7,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
  );

  /// Headings and names: the italic serif.
  static const TextStyle display = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontStyle: FontStyle.italic,
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
  );

  /// Body copy.
  static const TextStyle body = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 15,
    height: 1.6,
    color: BrandColors.textPrimary,
  );

  /// The interviewer's line, typewritten, in the serif.
  static const TextStyle subtitle = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
  );

  /// The speaker's name above a subtitle, in serif small caps.
  static const TextStyle speaker = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontSize: 17,
    height: 1.2,
    letterSpacing: 2.4,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.enable('smcp')],
    color: _accent,
  );

  /// Answer card text.
  static const TextStyle choice = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 14.5,
    height: 1.5,
    color: BrandColors.textPrimary,
  );

  /// Small tracked labels: places, field names, captions.
  static const TextStyle label = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 2.8,
    fontWeight: FontWeight.w600,
    color: BrandColors.textSecondary,
  );

  /// The italic roman numeral on an answer plaque ("ii.").
  static const TextStyle numeral = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontStyle: FontStyle.italic,
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: _accent,
  );

  /// Scores: tabular lining figures, so digits don't jitter while they tick. Ink on paper.
  static const TextStyle score = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    color: BrandColors.ink,
  );

  /// The word inside a stamp, or under the total on the seal.
  static const TextStyle stamp = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontSize: 12,
    height: 1,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
    color: BrandColors.redPen,
  );

  /// The fountain-pen note in the margin.
  static const TextStyle note = TextStyle(
    fontFamily: BrandFonts.display,
    package: BrandFonts.package,
    fontStyle: FontStyle.italic,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w500,
    color: BrandColors.redPen,
  );

  /// Every style in the ramp, for the AA and font tests.
  static const List<TextStyle> all = [
    eyebrow,
    titleCard,
    display,
    body,
    subtitle,
    speaker,
    choice,
    label,
    numeral,
    score,
    stamp,
    note,
  ];

  // The lobby grade's key: the default accent before a screen applies its own grade.
  static const Color _accent = ChapterGrade.lobbyKey;
}
