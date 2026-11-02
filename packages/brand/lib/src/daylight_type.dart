import 'package:flutter/painting.dart';

import 'daylight.dart';

/// Daylight's bundled pair (SIL OFL 1.1, variable fonts in `fonts/`, never fetched at runtime):
/// Bricolage Grotesque for display, Geist for everything read.
abstract final class DaylightFonts {
  /// Display: headings, the interviewer's line, scores. Axes `wght`, `opsz`, `wdth`.
  static const String display = 'BricolageGrotesque';

  /// Reading: body, labels, buttons, captions. Axis `wght`.
  static const String text = 'Geist';

  /// Fonts live in the brand package, so every style names it.
  static const String package = 'brand';

  /// Display weight: semibold. Nothing is heavier than bold anywhere.
  static const double displayWeight = 600;

  /// Bricolage's width axis at its normal width.
  static const double displayWidth = 100;
}

/// The named text styles (direction.md, "Type"): every size is a Tailwind step with its paired
/// line height, and nothing else is allowed. Each sets its font axes explicitly, so the app
/// matches the browser-rendered mockups (which used automatic optical sizing). [DaylightColors.ink]
/// by default; re-colour only to a pair `test/daylight_contrast_test.dart` holds.
///
/// Sentence case everywhere, no italics. Scores, XP and timers add [tabular].
abstract final class DaylightType {
  /// 48/48: the debrief score.
  static final TextStyle heading2 = _display(48, 48, -0.02);

  /// 36/40: celebration titles.
  static final TextStyle heading3 = _display(36, 40, -0.02);

  /// 30/36: the screen greeting ("Morning, Sami.").
  static final TextStyle heading4 = _display(30, 36, -0.015);

  /// 24/32: mission titles, "Why those details?".
  static final TextStyle heading5 = _display(24, 32, -0.01);

  /// 20/28: the interviewer's line in the bubble, section heads.
  static final TextStyle heading6 = _display(20, 28, -0.005);

  /// 20/28 medium: labels, dimension names.
  static final TextStyle title1 = _text(20, 28, FontWeight.w500);
  static final TextStyle title2 = _text(18, 28, FontWeight.w500);
  static final TextStyle title3 = _text(16, 24, FontWeight.w500);
  static final TextStyle title4 = _text(14, 20, FontWeight.w500);

  /// 16/24: Body 1–3 (semibold, medium, regular). Answer text is [body3], never smaller.
  static final TextStyle body1 = _text(16, 24, FontWeight.w600);
  static final TextStyle body2 = _text(16, 24, FontWeight.w500);
  static final TextStyle body3 = _text(16, 24, FontWeight.w400);

  /// 14/20: Body 4–6, secondary copy.
  static final TextStyle body4 = _text(14, 20, FontWeight.w600);
  static final TextStyle body5 = _text(14, 20, FontWeight.w500);
  static final TextStyle body6 = _text(14, 20, FontWeight.w400);

  /// 18/28 semibold: primary buttons.
  static final TextStyle buttonLarge = _text(18, 28, FontWeight.w600);

  /// 16/24 semibold: in-card buttons.
  static final TextStyle buttonMedium = _text(16, 24, FontWeight.w600);

  /// 12/16: kickers (semibold, sentence case, a hair of tracking) and metadata (medium).
  static final TextStyle caption3 = _text(
    12,
    16,
    FontWeight.w600,
    tracking: 0.01,
  );
  static final TextStyle caption4 = _text(12, 16, FontWeight.w500);

  /// Tabular lining figures, so a score or a timer doesn't jitter as it counts.
  static const List<FontFeature> figures = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  /// [style] with [figures].
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: figures);

  /// Every named style, for the font tests and the catalog's type sheet.
  static final Map<String, TextStyle> all = {
    'Heading 2': heading2,
    'Heading 3': heading3,
    'Heading 4': heading4,
    'Heading 5': heading5,
    'Heading 6': heading6,
    'Title 1': title1,
    'Title 2': title2,
    'Title 3': title3,
    'Title 4': title4,
    'Body 1': body1,
    'Body 2': body2,
    'Body 3': body3,
    'Body 4': body4,
    'Body 5': body5,
    'Body 6': body6,
    'Button large': buttonLarge,
    'Button medium': buttonMedium,
    'Caption 3': caption3,
    'Caption 4': caption4,
  };

  /// Bricolage at [size] / [line], semibold, optical size = the font size, normal width,
  /// tracked by [em] (negative on large type).
  static TextStyle _display(double size, double line, double em) => TextStyle(
    fontFamily: DaylightFonts.display,
    package: DaylightFonts.package,
    fontSize: size,
    height: line / size,
    letterSpacing: em * size,
    fontWeight: FontWeight.w600,
    fontVariations: [
      const FontVariation.weight(DaylightFonts.displayWeight),
      FontVariation.opticalSize(size),
      const FontVariation.width(DaylightFonts.displayWidth),
    ],
    color: DaylightColors.ink,
  );

  static TextStyle _text(
    double size,
    double line,
    FontWeight weight, {
    double tracking = 0,
  }) => TextStyle(
    fontFamily: DaylightFonts.text,
    package: DaylightFonts.package,
    fontSize: size,
    height: line / size,
    letterSpacing: tracking * size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: DaylightColors.ink,
  );
}
