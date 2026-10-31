import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The vivid layer's text rules (brief 17, `BrandVivid`), held to WCAG AA for body text
/// (4.5:1): white and soft white on the sky and every card, glow and the accent only on the
/// sky and a grade's deeper shade, ink on the accent.
void main() {
  const sky = {
    'skyTop': BrandVivid.skyTop,
    'skyMid': BrandVivid.skyMid,
    'skyLow': BrandVivid.skyLow,
    'night': BrandVivid.night,
    'locked': BrandVivid.locked,
  };
  final cards = {
    for (final g in ChapterGrade.values) ...{
      '${g.name} deep': g.deep,
      '${g.name} deeper': g.deeper,
    },
  };
  final darkGrounds = {
    ...sky,
    for (final g in ChapterGrade.values) '${g.name} deeper': g.deeper,
  };

  void holds(String text, Color fg, String ground, Color bg) => test(
    '$text on $ground',
    () => expect(contrastRatio(fg, bg), greaterThanOrEqualTo(wcagAaNormalText)),
  );

  group('white and soft white on the sky and every card', () {
    for (final ground in {...sky, ...cards}.entries) {
      holds('onDeep', BrandVivid.onDeep, ground.key, ground.value);
      holds('onDeepSoft', BrandVivid.onDeepSoft, ground.key, ground.value);
    }
  });

  group('glow and the accent on the sky and the deeper shades', () {
    for (final ground in darkGrounds.entries) {
      holds('accent', BrandVivid.accent, ground.key, ground.value);
      for (final g in ChapterGrade.values) {
        holds('${g.name} glow', g.glow, ground.key, ground.value);
      }
    }
  });

  test('ink on the accent, resting and pressed', () {
    expect(
      contrastRatio(BrandVivid.onAccent, BrandVivid.accent),
      greaterThanOrEqualTo(wcagAaNormalText),
    );
    expect(
      contrastRatio(BrandVivid.onAccent, BrandVivid.accentPressed),
      greaterThanOrEqualTo(wcagAaNormalText),
    );
  });

  test('every chapter has its own colour', () {
    final deeps = ChapterGrade.values.map((g) => g.deep).toSet();
    expect(deeps, hasLength(ChapterGrade.values.length));
  });

  test('the vivid type is bundled Manrope, titles in ExtraBold', () {
    for (final s in BrandVividType.all) {
      expect(s.fontFamily, 'packages/${BrandFonts.package}/${BrandFonts.sans}');
    }
    expect(BrandVividType.hero.fontWeight, FontWeight.w800);
    expect(BrandVividType.button.fontWeight, FontWeight.w800);
  });
}
