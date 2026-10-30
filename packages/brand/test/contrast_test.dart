import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every text pair the Boardroom uses, held to WCAG AA for body text (4.5:1), including the
/// grade keys: they set small text (the speaker's name, eyebrows, numerals), not only large.
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

  const darkGrounds = {
    'void': BrandColors.void_,
    'surface': BrandColors.surface,
    'surfaceRaised': BrandColors.surfaceRaised,
  };
  final lightTexts = {
    'textPrimary': BrandColors.textPrimary,
    'textSecondary': BrandColors.textSecondary,
    for (final g in ChapterGrade.values) '${g.name} key': g.key,
  };
  const paperInks = {
    'ink': BrandColors.ink,
    'inkSoft': BrandColors.inkSoft,
    'redPen': BrandColors.redPen,
  };

  group('light text on every dark surface', () {
    for (final ground in darkGrounds.entries) {
      for (final text in lightTexts.entries) {
        test('${text.key} on ${ground.key}', () {
          expect(
            contrastRatio(text.value, ground.value),
            greaterThanOrEqualTo(wcagAaNormalText),
          );
        });
      }
    }
  });

  group('every grade key on its own shadow (the vignette)', () {
    for (final g in ChapterGrade.values) {
      test(g.name, () {
        expect(
          contrastRatio(g.key, g.shadow),
          greaterThanOrEqualTo(wcagAaNormalText),
        );
      });
    }
  });

  group('ink on the dossier paper', () {
    for (final ink in paperInks.entries) {
      test(ink.key, () {
        expect(
          contrastRatio(ink.value, BrandColors.paper),
          greaterThanOrEqualTo(wcagAaNormalText),
        );
      });
    }
  });

  test('paper on the wax seal (the total pressed into it)', () {
    expect(
      contrastRatio(BrandColors.paper, BrandColors.redPen),
      greaterThanOrEqualTo(wcagAaNormalText),
    );
  });

  test('every type style defaults to a colour from a tested pair', () {
    final tested = {...lightTexts.values, ...paperInks.values};
    for (final style in BrandType.all) {
      expect(tested, contains(style.color), reason: '$style');
    }
  });

  test('the default brass in the type ramp is the lobby key', () {
    expect(BrandType.eyebrow.color, ChapterGrade.lobby.key);
    expect(BrandType.speaker.color, ChapterGrade.lobby.key);
  });
}
