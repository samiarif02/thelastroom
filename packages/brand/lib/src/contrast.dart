import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.x contrast ratio between two opaque colours (1.0 to 21.0).
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA for body text.
const double wcagAaNormalText = 4.5;

/// WCAG AA for large text (24 px, or 18.66 px bold) and UI components.
const double wcagAaLargeText = 3;

double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}
