/// Spacing, radii and hit-target tokens.
abstract final class BrandSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;

  /// Minimum touch target (brief §9 quality bar: 44 pt).
  static const double minTarget = 44;
}

/// Corner radii. Film frames and paper are mostly square; radii stay small.
abstract final class BrandRadius {
  static const double none = 0;
  static const double sm = 2;
  static const double md = 6;
}
