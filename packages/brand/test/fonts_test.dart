import 'dart:io';
import 'dart:typed_data';

import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Daylight's pair (direction.md, "Type"): Bricolage Grotesque for display, Geist for reading,
/// bundled in this package as the variable fonts Google Fonts ships. The film pair (Cormorant
/// Garamond + Manrope) is held to its old rules until the last film screen is restyled.
void main() {
  const banned = [
    'InstrumentSerif',
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

  group('Daylight', () {
    final styles = DaylightType.all;

    test(
      'every named style resolves to a bundled family, from this package',
      () {
        for (final MapEntry(key: name, value: s) in styles.entries) {
          expect(s.fontFamily, startsWith('packages/brand/'), reason: name);
          expect(
            [DaylightFonts.display, DaylightFonts.text],
            contains(family(s)),
            reason: name,
          );
          for (final b in banned) {
            expect(family(s), isNot(contains(b)), reason: name);
          }
        }
      },
    );

    test('headings are Bricolage, everything read is Geist', () {
      for (final MapEntry(key: name, value: s) in styles.entries) {
        expect(
          family(s),
          name.startsWith('Heading')
              ? DaylightFonts.display
              : DaylightFonts.text,
          reason: name,
        );
      }
    });

    test('every size is a Tailwind step with its line height', () {
      final steps = {
        12.0,
        14.0,
        16.0,
        18.0,
        20.0,
        24.0,
        30.0,
        36.0,
        48.0,
        60.0,
      };
      final lines = {
        12.0: {16.0},
        14.0: {20.0},
        16.0: {24.0},
        18.0: {28.0},
        20.0: {28.0},
        24.0: {32.0},
        30.0: {36.0},
        36.0: {40.0},
        48.0: {48.0},
      };
      for (final MapEntry(key: name, value: s) in styles.entries) {
        final size = s.fontSize!;
        expect(steps, contains(size), reason: name);
        final line = size * s.height!;
        expect(line, closeTo(line.roundToDouble(), 0.001), reason: name);
        expect(lines[size], contains(line.roundToDouble()), reason: name);
      }
    });

    test('weights are set on the wght axis, and never past bold', () {
      for (final MapEntry(key: name, value: s) in styles.entries) {
        final wght = s.fontVariations!.firstWhere((v) => v.axis == 'wght');
        expect(wght.value, s.fontWeight!.value.toDouble(), reason: name);
        expect(wght.value, lessThanOrEqualTo(700), reason: name);
        expect(s.fontStyle, isNot(FontStyle.italic), reason: name);
      }
    });

    test(
      'display styles set the optical size to the font size, at normal width',
      () {
        for (final MapEntry(key: name, value: s) in styles.entries) {
          if (family(s) != DaylightFonts.display) continue;
          final axes = {for (final v in s.fontVariations!) v.axis: v.value};
          expect(axes['opsz'], s.fontSize, reason: name);
          expect(axes['wdth'], DaylightFonts.displayWidth, reason: name);
          expect(s.letterSpacing, lessThan(0), reason: '$name tracks in');
        }
      },
    );

    test('tabular adds lining, tabular figures', () {
      expect(
        DaylightType.tabular(DaylightType.heading2).fontFeatures,
        containsAll(DaylightType.figures),
      );
    });

    test('the bundled files are the variable fonts, with their licences', () {
      for (final (file, axes) in const [
        (
          'fonts/bricolage_grotesque/BricolageGrotesque-Variable.ttf',
          ['wght', 'opsz', 'wdth'],
        ),
        ('fonts/geist/Geist-Variable.ttf', ['wght']),
      ]) {
        final bytes = File(file).readAsBytesSync();
        expect(_tables(bytes), contains('fvar'), reason: file);
        final fvar = _axes(bytes);
        expect(fvar, containsAll(axes), reason: file);
        expect(
          File('${File(file).parent.path}/OFL.txt').readAsStringSync(),
          contains('SIL Open Font License'),
        );
      }
    });
  });

  group('film (until the last film screen is restyled)', () {
    const pair = ['CormorantGaramond', 'Manrope'];

    test('every style uses the film pair, from the brand package', () {
      for (final s in BrandType.all) {
        expect(s.fontFamily, startsWith('packages/brand/'));
        expect(pair, contains(family(s)));
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
      expect(BrandType.speaker.fontFeatures, [
        const FontFeature.enable('smcp'),
      ]);
    });
  });

  test('the chapter grades run lobby, pressure, final round', () {
    expect(ChapterGrade.values.map((g) => g.label), [
      'Lobby',
      'Pressure',
      'Final round',
    ]);
  });
}

/// The table tags in a TrueType file's directory.
List<String> _tables(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final count = data.getUint16(4);
  return [
    for (var i = 0; i < count; i++)
      String.fromCharCodes(bytes.sublist(12 + i * 16, 16 + i * 16)),
  ];
}

/// The axis tags in the `fvar` table.
List<String> _axes(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final count = data.getUint16(4);
  for (var i = 0; i < count; i++) {
    final at = 12 + i * 16;
    if (String.fromCharCodes(bytes.sublist(at, at + 4)) != 'fvar') continue;
    final offset = data.getUint32(at + 8);
    final axesOffset = data.getUint16(offset + 4);
    final axisCount = data.getUint16(offset + 8);
    final axisSize = data.getUint16(offset + 10);
    return [
      for (var a = 0; a < axisCount; a++)
        String.fromCharCodes(
          bytes.sublist(
            offset + axesOffset + a * axisSize,
            offset + axesOffset + a * axisSize + 4,
          ),
        ),
    ];
  }
  return const [];
}
