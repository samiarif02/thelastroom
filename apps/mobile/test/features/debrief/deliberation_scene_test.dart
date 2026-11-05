import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/debrief/deliberation_scene.dart';

import '../../ui/harness.dart';

Widget _scene(DeliberationKind kind) => Center(
  child: Padding(
    padding: const EdgeInsets.all(DaylightSpace.s24),
    child: DeliberationScene(person: CastPeople.priya, kind: kind),
  ),
);

double _almost(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(DeliberationScene.almost),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('cycles reading, weighing, writing in the interviewer\'s name', (
    tester,
  ) async {
    await pumpKit(tester, _scene(DeliberationKind.reading));
    final steps = DeliberationScene.steps('Priya', DeliberationKind.reading);
    expect(steps.first, 'Priya is reading your answer…');
    expect(find.text(steps[0]), findsOneWidget);
    expect(find.text(DeliberationScene.readingLine), findsOneWidget);
    expect(_almost(tester), 0);
    final seen = <String>{};
    await pumpThrough(
      tester,
      DeliberationScene.period,
      eachFrame: () {
        for (final s in steps) {
          if (find.text(s).evaluate().isNotEmpty) seen.add(s);
        }
      },
    );
    expect(seen, steps.toSet());
    // Past ~4 s: "Almost there…", so it can't feel stuck.
    expect(_almost(tester), 1);
  });

  testWidgets(
    'reduced motion: one still frame with the words, still announced',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpKit(
        tester,
        _scene(DeliberationKind.listening),
        reduceMotion: true,
      );
      await tester.pump();
      // Nothing runs: no frame is asked for.
      expect(tester.binding.hasScheduledFrame, isFalse);
      final first = DeliberationScene.steps(
        'Priya',
        DeliberationKind.listening,
      ).first;
      expect(find.text(first), findsOneWidget);
      expect(find.text(DeliberationScene.listeningLine), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^${DeliberationScene.announce}')),
        findsOneWidget,
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^${DeliberationScene.announce}')),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
      await pumpThrough(tester, DeliberationScene.period);
      // The words hold; only "Almost there…" joins them.
      expect(find.text(first), findsOneWidget);
      expect(_almost(tester), 1);
      semantics.dispose();
    },
  );

  testWidgets('fits a small phone at 2x text', (tester) async {
    await pumpKit(
      tester,
      SingleChildScrollView(child: _scene(DeliberationKind.reading)),
      size: const Size(320, 568),
      textScale: 2,
    );
    await pumpThrough(tester, DeliberationScene.period);
  });
}
