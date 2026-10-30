import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every text pair Morning Office uses, held to WCAG AA for body text (4.5:1), including the
/// grade keys: they set small text (the speaker's name, eyebrows, numerals), not only large.
/// Text over colour is tested too: an answer card at its warmest (the raised surface mixed
/// halfway into the grade's tint), and a line on the speech panel over the interviewer.
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

  const grounds = {
    'void': BrandColors.void_,
    'surface': BrandColors.surface,
    'surfaceRaised': BrandColors.surfaceRaised,
  };
  final texts = {
    'textPrimary': BrandColors.textPrimary,
    'textSecondary': BrandColors.textSecondary,
    for (final g in ChapterGrade.values) '${g.name} key': g.key,
  };
  const paperInks = {
    'ink': BrandColors.ink,
    'inkSoft': BrandColors.inkSoft,
    'redPen': BrandColors.redPen,
  };

  // The most an answer card (locked) or a button (pressed) warms toward the tint.
  const warmestCard = 0.5;

  // `SpeechPanel`: void at 94% over whatever is behind the line.
  const panelAlpha = 0.94;

  group('every text on every surface', () {
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

  group('text over colour: choice text and numeral on the warmest card', () {
    for (final g in ChapterGrade.values) {
      test(g.name, () {
        final face = Color.lerp(
          BrandColors.surfaceRaised,
          g.tint,
          warmestCard,
        )!;
        expect(
          contrastRatio(BrandColors.textPrimary, face),
          greaterThanOrEqualTo(wcagAaNormalText),
        );
        expect(
          contrastRatio(g.key, face),
          greaterThanOrEqualTo(wcagAaNormalText),
        );
      });
    }
  });

  test('text over colour: a line on the speech panel over any cast colour', () {
    final under = [
      for (final c in [BrandCast.priya, BrandCast.marcus, BrandCast.lena]) ...[
        c.skin,
        c.hair,
        c.outer,
        c.inner,
        c.accent,
      ],
      BrandCast.feature,
      for (final g in ChapterGrade.values) ...[g.key, g.tint],
    ];
    for (final colour in under) {
      final panel = Color.alphaBlend(
        BrandColors.void_.withValues(alpha: panelAlpha),
        colour,
      );
      for (final text in texts.entries) {
        expect(
          contrastRatio(text.value, panel),
          greaterThanOrEqualTo(wcagAaNormalText),
          reason: '${text.key} on the panel over $colour',
        );
      }
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

  test('white on every key (Material text on a filled accent)', () {
    for (final g in ChapterGrade.values) {
      expect(
        contrastRatio(BrandColors.surfaceRaised, g.key),
        greaterThanOrEqualTo(wcagAaNormalText),
        reason: g.name,
      );
    }
  });

  test('every type style defaults to a colour from a tested pair', () {
    final tested = {...texts.values, ...paperInks.values};
    for (final style in BrandType.all) {
      expect(tested, contains(style.color), reason: '$style');
    }
  });

  test('the default accent in the type ramp is the lobby key', () {
    expect(BrandType.eyebrow.color, ChapterGrade.lobby.key);
    expect(BrandType.speaker.color, ChapterGrade.lobby.key);
  });
}
