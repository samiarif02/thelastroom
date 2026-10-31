import 'package:flutter/painting.dart';

import 'typography.dart';
import 'vivid.dart';

/// The vivid layer's type (brief 17): Manrope ExtraBold for titles that feel like a game's,
/// not a form's; Manrope for everything read. White on colour by default ([BrandVivid.onDeep]);
/// re-colour only to a pair `test/vivid_contrast_test.dart` holds.
abstract final class BrandVividType {
  /// The hero card's mission title and onboarding's big lines.
  static const TextStyle hero = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 32,
    height: 1.08,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w800,
    color: BrandVivid.onDeep,
  );

  /// A chapter card's title, a screen's heading.
  static const TextStyle title = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 22,
    height: 1.15,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w800,
    color: BrandVivid.onDeep,
  );

  /// The big chapter numeral and the stats: tabular lining figures, so digits don't jitter.
  static const TextStyle numeral = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 44,
    height: 1,
    letterSpacing: -1,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    color: BrandVivid.onDeep,
  );

  /// Small tracked caps over a title: "CHAPTER 1 · MISSION 2". Set in capitals by the caller.
  static const TextStyle kicker = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 11,
    height: 1.3,
    letterSpacing: 2.2,
    fontWeight: FontWeight.w600,
    color: BrandVivid.onDeepSoft,
  );

  /// Body copy on colour.
  static const TextStyle body = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 15,
    height: 1.5,
    color: BrandVivid.onDeepSoft,
  );

  /// A row's name: a mission in a chapter's list.
  static const TextStyle row = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: BrandVivid.onDeep,
  );

  /// Buttons: "Play", "Next", "Let's go".
  static const TextStyle button = TextStyle(
    fontFamily: BrandFonts.sans,
    package: BrandFonts.package,
    fontSize: 18,
    height: 1.2,
    letterSpacing: 0.3,
    fontWeight: FontWeight.w800,
    color: BrandVivid.onAccent,
  );

  /// Every style, for the font test.
  static const List<TextStyle> all = [
    hero,
    title,
    numeral,
    kicker,
    body,
    row,
    button,
  ];
}
