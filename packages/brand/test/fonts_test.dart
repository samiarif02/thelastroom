import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// D4 (owner, 2026-10-30): Cormorant Garamond + Manrope, bundled in this package. The losing
/// pairs from brief 03 are gone.
void main() {
  const pair = ['CormorantGaramond', 'Manrope'];
  const banned = [
    'InstrumentSerif',
    'Geist',
    'BigShouldersDisplay',
    'InterTight',
    'Playfair',
    'Bebas',
    'Montserrat',
    'Poppins',
    'Roboto',
  ];

  String family(TextStyle s) =>
      s.fontFamily!.replaceFirst('packages/brand/', '');

  test('every style uses the bundled pair, from the brand package', () {
    for (final s in BrandType.all) {
      expect(s.fontFamily, startsWith('packages/brand/'));
      expect(pair, contains(family(s)));
      for (final b in banned) {
        expect(family(s), isNot(contains(b)));
      }
    }
    expect(family(BrandType.titleCard), BrandFonts.display);
    expect(family(BrandType.body), BrandFonts.sans);
  });

  test('scores use tabular lining figures', () {
    expect(
      BrandType.score.fontFeatures,
      containsAll(const [
        FontFeature.tabularFigures(),
        FontFeature.liningFigures(),
      ]),
    );
  });

  test('the speaker is set in small caps', () {
    expect(BrandType.speaker.fontFeatures, [const FontFeature.enable('smcp')]);
  });

  test('the chapter grades run lobby, pressure, final round', () {
    expect(ChapterGrade.values.map((g) => g.label), [
      'Lobby',
      'Pressure',
      'Final round',
    ]);
  });
}
