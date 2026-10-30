import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  const line = 'Tell me why this one caught your eye.';

  int shown(WidgetTester tester) =>
      tester.widget<TypewriterText>(find.byType(TypewriterText)).characters;

  testWidgets('onCharacter fires for every character, in order', (
    tester,
  ) async {
    final typed = <(String, int)>[];
    var completed = 0;
    await pumpKit(
      tester,
      TypewriterSubtitle(
        speaker: 'Priya',
        line: line,
        onCharacter: (c, i) => typed.add((c, i)),
        onComplete: () => completed++,
      ),
    );
    await pumpThrough(
      tester,
      BrandMotion.perCharacter * (line.length + 4),
      step: BrandMotion.perCharacter,
    );
    expect(typed.map((e) => e.$2), List.generate(line.length, (i) => i));
    expect(typed.map((e) => e.$1).join(), line);
    expect(completed, 1);
    expect(shown(tester), line.length);
  });

  testWidgets('the speaker is set in the grade key, small caps', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const TypewriterSubtitle(
        speaker: 'Marcus',
        line: line,
        grade: ChapterGrade.pressure,
        play: false,
      ),
    );
    final speaker = tester.widget<Text>(find.text('Marcus'));
    expect(speaker.style!.color, ChapterGrade.pressure.key);
    expect(speaker.style!.fontFeatures, BrandType.speaker.fontFeatures);
  });

  testWidgets(
    'the controller completes the line; skipped characters stay silent',
    (tester) async {
      final controller = TypewriterController();
      addTearDown(controller.dispose);
      final typed = <int>[];
      var completed = 0;
      await pumpKit(
        tester,
        TypewriterSubtitle(
          speaker: 'Priya',
          line: line,
          controller: controller,
          onCharacter: (_, i) => typed.add(i),
          onComplete: () => completed++,
        ),
      );
      await tester.pump(BrandMotion.perCharacter * 5);
      final before = typed.length;
      expect(before, greaterThan(0));
      controller.complete();
      await tester.pump();
      await tester.pump(BrandMotion.perCharacter * line.length);
      expect(shown(tester), line.length);
      expect(typed.length, before);
      expect(controller.isComplete, isTrue);
      expect(completed, 1);
    },
  );

  testWidgets('a tap on the subtitle completes it', (tester) async {
    await pumpKit(
      tester,
      const Center(
        child: TypewriterSubtitle(speaker: 'Priya', line: line),
      ),
    );
    await tester.pump(BrandMotion.perCharacter * 3);
    await tester.tap(find.byType(TypewriterSubtitle));
    await tester.pump();
    expect(shown(tester), line.length);
  });

  testWidgets('reduced motion: the whole line at once, no typing sound', (
    tester,
  ) async {
    final typed = <int>[];
    var completed = 0;
    await pumpKit(
      tester,
      TypewriterSubtitle(
        speaker: 'Priya',
        line: line,
        onCharacter: (_, i) => typed.add(i),
        onComplete: () => completed++,
      ),
      reduceMotion: true,
    );
    await tester.pump(BrandMotion.reducedMotionFade);
    expect(shown(tester), line.length);
    expect(typed, isEmpty);
    expect(completed, 1);
  });

  testWidgets('a new line restarts the typewriter', (tester) async {
    Widget subtitle(String l) => TypewriterSubtitle(speaker: 'Priya', line: l);
    await pumpKit(tester, subtitle(line));
    await tester.pump(BrandMotion.perCharacter * (line.length + 2));
    await pumpKit(tester, subtitle('And what did you do?'));
    await tester.pump(BrandMotion.perCharacter * 2);
    expect(shown(tester), lessThan('And what did you do?'.length));
  });

  testWidgets('screen readers get the whole line', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(
      tester,
      const TypewriterSubtitle(speaker: 'Priya', line: line),
    );
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(line))), findsOneWidget);
    handle.dispose();
  });
}
