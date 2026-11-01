import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The vivid layer's text rules (brief 17), held to WCAG AA for body text (4.5:1) in **every
/// theme** (brief 28): the text colours on the sky and every card, glow and the accent only on
/// the sky and a chapter's deeper shade, ink on the accent.
void main() {
  for (final t in VividThemes.all) {
    group(t.name, () {
      final grounds = {
        'skyTop': t.skyTop,
        'skyMid': t.skyMid,
        'skyLow': t.skyLow,
        'night': t.night,
        'locked': t.locked,
      };
      final chapters = {
        for (final g in ChapterGrade.values) g.name: t.chapter(g),
      };
      final cards = {
        for (final c in chapters.entries) ...{
          '${c.key} deep': c.value.deep,
          '${c.key} deeper': c.value.deeper,
        },
      };
      final darkGrounds = {
        ...grounds,
        for (final c in chapters.entries) '${c.key} deeper': c.value.deeper,
      };

      void holds(String text, Color fg, String ground, Color bg) => test(
        '$text on $ground',
        () => expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(wcagAaNormalText),
        ),
      );

      for (final ground in {...grounds, ...cards}.entries) {
        holds('onDeep', t.onDeep, ground.key, ground.value);
        holds('onDeepSoft', t.onDeepSoft, ground.key, ground.value);
      }
      for (final ground in darkGrounds.entries) {
        holds('accent', t.accent, ground.key, ground.value);
        for (final c in chapters.entries) {
          holds('${c.key} glow', c.value.glow, ground.key, ground.value);
        }
      }
      holds('onAccent', t.onAccent, 'accent', t.accent);
      holds('onAccent', t.onAccent, 'accentPressed', t.accentPressed);

      test('every chapter has its own colour', () {
        expect(chapters.values.map((c) => c.deep).toSet(), hasLength(3));
      });
    });
  }

  test('themes have unique ids, and an unknown id is the default', () {
    final ids = VividThemes.all.map((t) => t.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(VividThemes.byId('nope'), VividThemes.eveningForest);
    expect(VividThemes.byId(null), VividThemes.eveningForest);
    expect(VividThemes.byId('ocean-night'), VividThemes.oceanNight);
  });

  test('the tokens follow the current theme', () {
    addTearDown(() => BrandVivid.current = VividThemes.eveningForest);
    BrandVivid.current = VividThemes.sunsetCity;
    expect(BrandVivid.accent, VividThemes.sunsetCity.accent);
    expect(ChapterGrade.pressure.deep, VividThemes.sunsetCity.pressure.deep);
    expect(BrandVividType.hero.color, VividThemes.sunsetCity.onDeep);
  });

  test('the vivid type is bundled Manrope, titles in ExtraBold', () {
    for (final s in BrandVividType.all) {
      expect(s.fontFamily, 'packages/${BrandFonts.package}/${BrandFonts.sans}');
    }
    expect(BrandVividType.hero.fontWeight, FontWeight.w800);
    expect(BrandVividType.button.fontWeight, FontWeight.w800);
  });
}
