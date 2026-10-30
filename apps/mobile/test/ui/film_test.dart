import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  group('letterbox', () {
    double barHeight(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(Letterbox),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .height;

    testWidgets('open at 0, 13% bars at 1', (tester) async {
      await pumpKit(tester, const Letterbox(t: 0));
      expect(barHeight(tester), 0);
      await pumpKit(tester, const Letterbox(t: 1));
      expect(barHeight(tester), closeTo(667 * Letterbox.defaultFraction, 0.01));
    });

    testWidgets('reduced motion fades full bars instead of sliding', (
      tester,
    ) async {
      await pumpKit(tester, const Letterbox(t: 0.4), reduceMotion: true);
      expect(barHeight(tester), closeTo(667 * Letterbox.defaultFraction, 0.01));
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.4);
    });

    testWidgets('the animated letterbox slides in and reports when settled', (
      tester,
    ) async {
      var settled = 0;
      Widget bars(bool shown) =>
          AnimatedLetterbox(shown: shown, onSettled: () => settled++);
      await pumpKit(tester, bars(false));
      await pumpKit(tester, bars(true));
      await tester.pump(BrandMotion.letterbox ~/ 2);
      expect(barHeight(tester), inExclusiveRange(0, 667 * 0.13));
      await tester.pump(BrandMotion.letterbox);
      expect(barHeight(tester), closeTo(667 * 0.13, 0.01));
      expect(settled, 1);
    });

    test('content clears the bars by barHeight', () {
      expect(Letterbox.barHeight(1000, 0.5), 65);
    });
  });

  group('film overlay', () {
    testWidgets(
      'lays vignette and grain over the child, and lets taps through',
      (tester) async {
        var taps = 0;
        await pumpKit(
          tester,
          FilmOverlay(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(RepaintBoundary), findsWidgets);
        await tester.tapAt(const Offset(180, 300));
        expect(taps, 1);
      },
    );

    testWidgets('no grain and no vignette draws only the child', (
      tester,
    ) async {
      await pumpKit(
        tester,
        const FilmOverlay(grain: 0, vignette: 0, child: Text('frame')),
      );
      expect(find.byType(IgnorePointer), findsNothing);
      expect(find.text('frame'), findsOneWidget);
    });
  });

  group('timeline', () {
    testWidgets('fires each cue once, in order, then finishes', (tester) async {
      final fired = <String>[];
      await pumpKit(
        tester,
        Timeline(
          duration: const Duration(seconds: 1),
          cues: [
            (at: 0.25, fire: () => fired.add('a')),
            (at: 0.75, fire: () => fired.add('b')),
          ],
          onFinished: () => fired.add('end'),
          builder: (context, t, _) => const SizedBox(),
        ),
      );
      await pumpThrough(tester, const Duration(milliseconds: 1200));
      expect(fired, ['a', 'b', 'end']);
    });

    testWidgets('reduced motion: final state, no cues, still finishes', (
      tester,
    ) async {
      final fired = <String>[];
      double? seen;
      await pumpKit(
        tester,
        Timeline(
          duration: const Duration(seconds: 1),
          cues: [(at: 0.5, fire: () => fired.add('a'))],
          onFinished: () => fired.add('end'),
          builder: (context, t, _) {
            seen = t;
            return const SizedBox();
          },
        ),
        reduceMotion: true,
      );
      await tester.pump(BrandMotion.reducedMotionFade);
      expect(seen, 1);
      expect(fired, ['end']);
    });
  });

  test('cue eases inside its window and clamps outside it', () {
    expect(cue(0.1, 0.2, 0.6), 0);
    expect(cue(0.4, 0.2, 0.6), closeTo(0.5, 1e-9));
    expect(cue(0.9, 0.2, 0.6), 1);
    expect(mix(10, 20, 0.25), 12.5);
  });
}
