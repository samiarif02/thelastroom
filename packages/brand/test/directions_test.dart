import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The owner's font pairs (brief 03), one per direction, all bundled in this package.
void main() {
  const pairs = {
    'night-glass': ('InstrumentSerif', 'Geist'),
    'concrete-noir': ('BigShouldersDisplay', 'InterTight'),
    'boardroom': ('CormorantGaramond', 'Manrope'),
  };
  const banned = ['Playfair', 'Bebas', 'Montserrat', 'Poppins', 'Roboto'];

  String family(TextStyle s) =>
      s.fontFamily!.replaceFirst('packages/brand/', '');

  test('there are three directions, A to C, with unique ids', () {
    expect(cinematicDirections.map((d) => d.letter), ['A', 'B', 'C']);
    expect(cinematicDirections.map((d) => d.id).toSet(), hasLength(3));
  });

  for (final d in cinematicDirections) {
    group('${d.letter} ${d.name}', () {
      final styles = [
        d.type.eyebrow,
        d.type.titleCard,
        d.type.display,
        d.type.body,
        d.type.subtitle,
        d.type.speaker,
        d.type.choice,
        d.type.label,
        d.type.score,
        d.type.stamp,
        d.type.note,
      ];

      test('uses only its own bundled pair, from the brand package', () {
        final (display, body) = pairs[d.id]!;
        for (final s in styles) {
          expect(s.fontFamily, startsWith('packages/brand/'));
          expect([display, body], contains(family(s)));
        }
        expect(family(d.type.titleCard), display);
        expect(family(d.type.body), body);
        for (final s in styles) {
          for (final b in banned) {
            expect(family(s), isNot(contains(b)));
          }
        }
      });

      test('scores use tabular figures', () {
        expect(
          d.type.score.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      });

      test('has the three chapter grades in order', () {
        expect(d.grades.map((g) => g.name), [
          'Lobby',
          'Pressure',
          'Final round',
        ]);
      });
    });
  }
}
