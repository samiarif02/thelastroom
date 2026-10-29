import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tokens are provisional, but the bar isn't: whatever the design session picks must keep
/// these pairs at WCAG AA (brief §9).
void main() {
  test('contrastRatio matches the WCAG reference values', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      contrastRatio(const Color(0xFF777777), const Color(0xFFFFFFFF)),
      closeTo(4.48, 0.01),
    );
  });

  group('text tokens meet WCAG AA on every surface', () {
    const surfaces = {
      'void': BrandColors.void_,
      'surface': BrandColors.surface,
      'surfaceRaised': BrandColors.surfaceRaised,
    };
    const texts = {
      'textPrimary': BrandColors.textPrimary,
      'textSecondary': BrandColors.textSecondary,
    };
    for (final s in surfaces.entries) {
      for (final t in texts.entries) {
        test('${t.key} on ${s.key}', () {
          expect(
            contrastRatio(t.value, s.value),
            greaterThanOrEqualTo(wcagAaNormalText),
          );
        });
      }
    }
  });

  test(
    'every chapter grade key colour is legible as large text on the surface',
    () {
      for (final grade in ChapterGrade.values) {
        expect(
          contrastRatio(grade.key, BrandColors.surface),
          greaterThanOrEqualTo(wcagAaLargeText),
          reason: grade.name,
        );
      }
    },
  );
}
