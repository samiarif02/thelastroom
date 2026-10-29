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

  // Brief 03: every text pair in every prototype direction, at AA for body text. The grade key
  // is used for small labels (the speaker's name, eyebrows), so it is held to 4.5 too, not 3.
  for (final direction in cinematicDirections) {
    group(
      'direction ${direction.letter} (${direction.name}) meets WCAG AA',
      () {
        final p = direction.palette;
        final grounds = {
          'void': p.void_,
          'surface': p.surface,
          'raised': p.raised,
        };
        final texts = {
          'textPrimary': p.textPrimary,
          'textSecondary': p.textSecondary,
          for (final g in direction.grades) '${g.name} key': g.key,
        };
        for (final ground in grounds.entries) {
          for (final text in texts.entries) {
            test('${text.key} on ${ground.key}', () {
              expect(
                contrastRatio(text.value, ground.value),
                greaterThanOrEqualTo(wcagAaNormalText),
              );
            });
          }
        }
        for (final ink in {
          'ink': p.ink,
          'inkSoft': p.inkSoft,
          'redPen': p.redPen,
        }.entries) {
          test('${ink.key} on the dossier paper', () {
            expect(
              contrastRatio(ink.value, p.paper),
              greaterThanOrEqualTo(wcagAaNormalText),
            );
          });
        }
        test('every type style uses a colour from a tested pair', () {
          final type = direction.type;
          final tested = {...texts.values, p.ink, p.inkSoft, p.redPen};
          for (final style in [
            type.eyebrow,
            type.titleCard,
            type.display,
            type.body,
            type.subtitle,
            type.speaker,
            type.choice,
            type.label,
            type.score,
            type.stamp,
            type.note,
          ]) {
            expect(tested, contains(style.color));
          }
        });
      },
    );
  }
}
