/// Spacing, radii and hit-target tokens.
abstract final class BrandSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;

  /// Minimum touch target: 48 dp, which meets both the brief's 44 pt (iOS) and Android's 48 dp
  /// (brief 31; Flutter's tap-target guidelines check both).
  static const double minTarget = 48;
}

/// Corner radii. Film frames and paper are mostly square; radii stay small.
abstract final class BrandRadius {
  static const double none = 0;
  static const double sm = 2;
  static const double md = 6;

  /// The vivid layer's cards (brief 17): soft and friendly, like a game's.
  static const double card = 24;

  /// Rows and badges inside a card.
  static const double lg = 16;

  /// Buttons: fully round ends.
  static const double pill = 999;
}
