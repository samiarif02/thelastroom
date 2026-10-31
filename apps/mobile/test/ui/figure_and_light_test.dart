import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  group('the interviewer', () {
    test('there is a figure for each interviewer', () {
      expect(
        SilhouetteFigure.byId.keys,
        containsAll(['priya', 'marcus', 'lena']),
      );
    });

    test('the idle is deterministic, gentle and bounded', () {
      for (var s = 0.0; s < 60; s += 0.37) {
        final p = FaceGesture.pose(s);
        expect(p.breath.abs(), lessThanOrEqualTo(1));
        expect(p.turn.abs(), lessThanOrEqualTo(1));
        expect(FaceGesture.pose(s), p);
      }
      // It really moves: the head is somewhere else ten seconds on.
      expect(
        FaceGesture.pose(3).turn,
        isNot(closeTo(FaceGesture.pose(13).turn, 0.05)),
      );
    });

    for (final figure in SilhouetteFigure.byId.values) {
      for (final grade in ChapterGrade.values) {
        testWidgets('${figure.id} idles in the ${grade.label} grade', (
          tester,
        ) async {
          await pumpKit(
            tester,
            Center(
              child: SizedBox(
                width: 200,
                child: InterviewerSilhouette(figure: figure, grade: grade),
              ),
            ),
          );
          await pumpThrough(tester, const Duration(seconds: 2));
          expect(
            tester.getSize(find.byType(InterviewerSilhouette)).aspectRatio,
            closeTo(SilhouetteFigure.aspectRatio, 0.01),
          );
        });
      }
    }

    testWidgets('a labelled interviewer is announced as an image', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpKit(
        tester,
        const Center(
          child: SizedBox(
            width: 120,
            child: InterviewerSilhouette(
              figure: SilhouetteFigure.priya,
              semanticLabel: 'Priya, the recruiter',
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Priya, the recruiter'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('idle off: the painter has no clock to repaint on', (
      tester,
    ) async {
      await pumpKit(
        tester,
        const Center(
          child: SizedBox(
            width: 120,
            child: InterviewerSilhouette(
              figure: SilhouetteFigure.marcus,
              idle: false,
            ),
          ),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(InterviewerSilhouette),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as FriendlyPainter).clock, isNull);
    });
  });

  group('light', () {
    test('the lamp flickers gently, never out', () {
      var low = 1.0;
      var high = 0.0;
      for (var s = 0.0; s < 120; s += 0.05) {
        final f = lampFlicker(s);
        low = f < low ? f : low;
        high = f > high ? f : high;
      }
      expect(low, greaterThanOrEqualTo(0.82));
      expect(high, lessThanOrEqualTo(1));
      expect(high - low, greaterThan(0.02));
    });

    for (final lit in [true, false]) {
      testWidgets('the banker\'s lamp draws ${lit ? 'lit' : 'dark'}', (
        tester,
      ) async {
        await pumpKit(
          tester,
          Center(
            child: SizedBox(width: 140, child: BankersLamp(lit: lit)),
          ),
        );
        await pumpThrough(tester, const Duration(milliseconds: 500));
        expect(
          tester.getSize(find.byType(BankersLamp)).aspectRatio,
          closeTo(BankersLamp.aspectRatio, 0.01),
        );
      });
    }

    testWidgets('the spotlight pool and its dust let taps through', (
      tester,
    ) async {
      var taps = 0;
      await pumpKit(
        tester,
        Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
            const Positioned.fill(child: Spotlight(dust: true)),
          ],
        ),
      );
      await pumpThrough(tester, const Duration(milliseconds: 500));
      expect(find.byType(Dust), findsOneWidget);
      await tester.tapAt(const Offset(100, 300));
      expect(taps, 1);
    });

    testWidgets('bokeh breathes without throwing', (tester) async {
      await pumpKit(
        tester,
        Bokeh(colors: [ChapterGrade.lobby.key, ChapterGrade.lobby.tint]),
      );
      await pumpThrough(tester, const Duration(seconds: 1));
    });
  });
}
