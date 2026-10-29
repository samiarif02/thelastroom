import 'package:engine/engine.dart';
import 'package:test/test.dart';

void main() {
  group('DimensionScores', () {
    const scores = DimensionScores(
      relevance: 0,
      specificity: 1,
      structure: 2,
      adaptability: 3,
    );

    test('indexes every dimension', () {
      expect(Dimension.values.map((d) => scores[d]), [0, 1, 2, 3]);
    });

    test('accepts 0–3 and rejects anything outside it', () {
      expect(scores.isInRange, isTrue);
      const tooHigh = DimensionScores(
        relevance: 4,
        specificity: 0,
        structure: 0,
        adaptability: 0,
      );
      const negative = DimensionScores(
        relevance: 0,
        specificity: 0,
        structure: -1,
        adaptability: 0,
      );
      expect(tooHigh.isInRange, isFalse);
      expect(negative.isInRange, isFalse);
    });
  });

  group('Flag', () {
    test('wire names are unique snake_case', () {
      final names = Flag.values.map((f) => f.wireName).toList();
      expect(names.toSet(), hasLength(names.length));
      for (final name in names) {
        expect(RegExp(r'^[a-z]+(_[a-z]+)*$').hasMatch(name), isTrue);
      }
    });

    test('no flag lowers adaptability, which only follow-up replies earn', () {
      expect(
        Flag.values.map((f) => f.lowers),
        isNot(contains(Dimension.adaptability)),
      );
    });
  });

  group('CalendarDay', () {
    test('adds days across a month end and a daylight-saving change', () {
      expect(CalendarDay(2026, 10, 24).addDays(7), CalendarDay(2026, 10, 31));
      expect(CalendarDay(2026, 10, 29).addDays(7), CalendarDay(2026, 11, 5));
      expect(CalendarDay(2026, 12, 31).addDays(1).toString(), '2027-01-01');
    });

    test('orders days', () {
      final today = CalendarDay(2026, 10, 29);
      expect(today.isBefore(today.addDays(1)), isTrue);
      expect(today.compareTo(today.addDays(-1)), greaterThan(0));
    });
  });

  test('Leitner intervals are 1, 3 and 7 days (FR-40)', () {
    expect(LeitnerBox.values.map((b) => b.intervalDays), [1, 3, 7]);
  });

  test('every skill has a unique wire name', () {
    final names = Skill.values.map((s) => s.wireName).toSet();
    expect(names, hasLength(Skill.values.length));
  });
}
