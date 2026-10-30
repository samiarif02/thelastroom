import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  const answer =
      "I've used Northstar's tools for two years. The problem you're solving is the one I keep "
      'running into.';

  Widget card(AnswerCardState state, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.all(BrandSpace.lg),
    child: Align(
      alignment: Alignment.topCenter,
      child: AnswerCard(
        numeral: AnswerCard.numeralFor(1),
        text: answer,
        state: state,
        onTap: onTap,
      ),
    ),
  );

  test('numerals are italic roman, with a point', () {
    expect([0, 1, 2].map(AnswerCard.numeralFor), ['i.', 'ii.', 'iii.']);
  });

  for (final state in AnswerCardState.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${state.name} renders at ${scale}x text, 44 pt or taller', (
        tester,
      ) async {
        await pumpKit(tester, card(state), textScale: scale);
        await tester.pump(BrandMotion.standard);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(AnswerCard)).height,
          greaterThanOrEqualTo(BrandSpace.minTarget),
        );
        expect(find.text(answer), findsOneWidget);
      });
    }
  }

  testWidgets('idle, focused and selected cards take a tap', (tester) async {
    for (final state in [
      AnswerCardState.idle,
      AnswerCardState.focused,
      AnswerCardState.selected,
    ]) {
      var taps = 0;
      await pumpKit(tester, card(state, onTap: () => taps++));
      await tester.tap(find.byType(AnswerCard));
      expect(taps, 1, reason: state.name);
    }
  });

  testWidgets('locked and disabled cards ignore a tap', (tester) async {
    for (final state in [AnswerCardState.locked, AnswerCardState.disabled]) {
      var taps = 0;
      await pumpKit(tester, card(state, onTap: () => taps++));
      await tester.tap(find.byType(AnswerCard), warnIfMissed: false);
      expect(taps, 0, reason: state.name);
    }
  });

  testWidgets('screen readers hear a button, its state and its words', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, card(AnswerCardState.selected, onTap: () {}));
    expect(
      tester.getSemantics(find.byType(AnswerCard)),
      matchesSemantics(
        label: 'ii. $answer',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    await pumpKit(tester, card(AnswerCardState.disabled, onTap: () {}));
    expect(
      tester.getSemantics(find.byType(AnswerCard)),
      matchesSemantics(
        label: 'ii. $answer',
        isButton: true,
        hasEnabledState: true,
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the five states look different from each other', (tester) async {
    final looks = <String>{};
    for (final state in AnswerCardState.values) {
      await pumpKit(tester, card(state));
      await tester.pump(BrandMotion.standard);
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      looks.add('${box.decoration}|${opacity.opacity}');
    }
    expect(looks, hasLength(AnswerCardState.values.length));
  });
}
