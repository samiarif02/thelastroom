import 'package:brand/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Daylight's text rules (direction.md, "Colour"), every pair a widget sets as text held to
/// WCAG AA for body text (4.5:1). A pair that isn't here isn't allowed as text.
void main() {
  void holds(String text, Color fg, String ground, Color bg) => test(
    '$text on $ground',
    () => expect(contrastRatio(fg, bg), greaterThanOrEqualTo(wcagAaNormalText)),
  );

  group('ink on the grounds', () {
    const grounds = {
      'paper': DaylightColors.paper,
      'sand': DaylightColors.sand,
      'raised': DaylightColors.raised,
      'honeyTint': DaylightColors.honeyTint,
      'trapTint': DaylightColors.trapTint,
      'recallTint': DaylightColors.recallTint,
      'recallSoft': DaylightColors.recallSoft,
    };
    for (final g in grounds.entries) {
      holds('ink', DaylightColors.ink, g.key, g.value);
      holds('ink2', DaylightColors.ink2, g.key, g.value);
    }
  });

  group('meaning', () {
    holds('onHoney', DaylightColors.onHoney, 'honey', DaylightColors.honey);
    holds(
      'honeyInk',
      DaylightColors.honeyInk,
      'honeyTint',
      DaylightColors.honeyTint,
    );
    holds('honey', DaylightColors.honey, 'dusk', DaylightColors.dusk);
    for (final (name, bg) in const [
      ('trapTint', DaylightColors.trapTint),
      ('paper', DaylightColors.paper),
      ('raised', DaylightColors.raised),
    ]) {
      holds('trap', DaylightColors.trap, name, bg);
    }
    holds(
      'recall',
      DaylightColors.recall,
      'recallTint',
      DaylightColors.recallTint,
    );
    holds('recall', DaylightColors.recall, 'raised', DaylightColors.raised);
    holds('white', DaylightColors.raised, 'recall', DaylightColors.recall);
    holds(
      'recallDeep',
      DaylightColors.recallDeep,
      'recallSoft',
      DaylightColors.recallSoft,
    );
  });

  for (final (i, f) in DaylightFloors.all.indexed) {
    group('floor ${i + 1}', () {
      holds('white', DaylightColors.raised, 'base', f.base);
      holds('on', f.on, 'base', f.base);
      holds('white', DaylightColors.raised, 'deep', f.deep);
      holds('on', f.on, 'deep', f.deep);
      holds('deep', f.deep, 'tint', f.tint);
      holds('deep', f.deep, 'soft', f.soft);
      holds('deep', f.deep, 'white', DaylightColors.raised);
      holds('base', f.base, 'white', DaylightColors.raised);
      holds('ink', DaylightColors.ink, 'tint', f.tint);
      holds('ink2', DaylightColors.ink2, 'tint', f.tint);
      holds('ink', DaylightColors.ink, 'soft', f.soft);
    });
  }

  group('what the rules forbid really fails', () {
    test('soft text on a floor is under AA (use on or white)', () {
      expect(
        contrastRatio(DaylightFloors.three.soft, DaylightFloors.three.base),
        lessThan(wcagAaNormalText),
      );
    });
    test('ink3 is never text on paper', () {
      expect(
        contrastRatio(DaylightColors.ink3, DaylightColors.paper),
        lessThan(wcagAaNormalText),
      );
    });
  });

  test('every chapter grade has its floor, in order', () {
    expect(ChapterGrade.values.map((g) => g.floor), DaylightFloors.all);
  });

  test('saturation stays under 80% (main\'s sunflower was 100%)', () {
    final colours = [
      DaylightColors.honey,
      DaylightColors.trap,
      DaylightColors.recall,
      for (final f in DaylightFloors.all) ...[f.base, f.deep],
    ];
    for (final colour in colours) {
      expect(HSLColor.fromColor(colour).saturation, lessThan(0.8));
    }
  });
}
