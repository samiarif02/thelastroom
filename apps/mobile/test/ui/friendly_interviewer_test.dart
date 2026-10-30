import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/mission/scene/mission_set.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

/// Brief 16: a friendly interviewer drawn in code, with at least five expressions and an idle;
/// Priya, Marcus and Lena distinct; reduced motion stops the idle; the face stays inside the
/// box the mission's subtitles keep clear of.
void main() {
  test('five expressions, each a different face', () {
    final shapes = InterviewerExpression.values.map(FaceShape.of).toList();
    expect(shapes, hasLength(greaterThanOrEqualTo(5)));
    expect(shapes.toSet(), hasLength(shapes.length));
  });

  test('the idle blinks, and a still frame is never mid-blink', () {
    expect(FaceGesture.blink(0), 1);
    final closes = [for (var t = 0.0; t < 9; t += 0.01) FaceGesture.blink(t)]
        .where((o) => o < 0.5);
    expect(closes, isNotEmpty);
  });

  test('a nod dips and comes back', () {
    expect(FaceGesture.nodDip(0), 0);
    expect(FaceGesture.nodDip(1), 0);
    expect(FaceGesture.nodDip(0.25), greaterThan(0));
  });

  test('Priya, Marcus and Lena are distinct', () {
    final cast = FriendlyFigure.byId.values.toList();
    expect(cast.map((f) => f.id), containsAll(['priya', 'marcus', 'lena']));
    for (var i = 0; i < cast.length; i++) {
      for (var j = i + 1; j < cast.length; j++) {
        final a = cast[i].colors;
        final b = cast[j].colors;
        expect(a.skin, isNot(b.skin));
        expect(a.hair, isNot(b.hair));
        expect(a.outer, isNot(b.outer));
        expect(
          cast[i].hairFront().getBounds(),
          isNot(cast[j].hairFront().getBounds()),
        );
      }
    }
  });

  test("every head stays inside the mission's face box", () {
    for (final f in FriendlyFigure.byId.values) {
      final head = FriendlyFigure.faceRect
          .expandToInclude(
            f.hairBack().getBounds().isEmpty
                ? FriendlyFigure.faceRect
                : f.hairBack().getBounds(),
          )
          .expandToInclude(f.hairFront().getBounds())
          // The ears.
          .expandToInclude(
            Rect.fromLTRB(
              FriendlyFigure.faceCenter.dx -
                  FriendlyFigure.faceRx -
                  FriendlyFigure.earRadius,
              FriendlyFigure.earY - FriendlyFigure.earRadius,
              FriendlyFigure.faceCenter.dx +
                  FriendlyFigure.faceRx +
                  FriendlyFigure.earRadius,
              FriendlyFigure.earY + FriendlyFigure.earRadius,
            ),
          );
      expect(
        MissionSet.faceInDesign.contains(head.topLeft) &&
            MissionSet.faceInDesign.contains(head.bottomRight),
        isTrue,
        reason: '${f.id}: $head',
      );
    }
  });

  double clockOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(FriendlyInterviewer),
        matching: find.byType(CustomPaint),
      ),
    );
    return (paint.painter! as FriendlyPainter).clock!.value;
  }

  Widget priya() => Center(
    child: SizedBox(
      width: 200,
      child: FriendlyInterviewer(
        figure: FriendlyFigure.priya,
        semanticLabel: 'Priya',
      ),
    ),
  );

  testWidgets('the idle runs, and reduced motion stops it', (tester) async {
    await pumpKit(tester, priya());
    await tester.pump(const Duration(seconds: 2));
    expect(clockOf(tester), greaterThan(0));

    // The clock stops where it is: no breath, no blink, no sway from here on.
    await pumpKit(tester, priya(), reduceMotion: true);
    final stopped = clockOf(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(clockOf(tester), stopped);
  });

  testWidgets('a change of expression eases, and is instant under reduced '
      'motion', (tester) async {
    Widget face(InterviewerExpression e) =>
        FriendlyInterviewer(figure: FriendlyFigure.marcus, expression: e);
    await pumpKit(tester, face(InterviewerExpression.neutral));
    await pumpKit(tester, face(InterviewerExpression.hmm));
    await tester.pump(BrandMotion.quick ~/ 2);
    FriendlyPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(FriendlyInterviewer),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as FriendlyPainter;
    expect(painter().ease.value, inExclusiveRange(0, 1));
    await tester.pump(BrandMotion.quick);
    expect(painter().ease.value, 1);

    await pumpKit(tester, face(InterviewerExpression.nod), reduceMotion: true);
    expect(painter().ease.value, 1);
    expect(painter().nod.value, 0);
  });

  testWidgets('a scene\'s interviewer is the friendly person', (tester) async {
    await pumpKit(
      tester,
      const Center(
        child: SizedBox(
          width: 200,
          child: InterviewerSilhouette(figure: SilhouetteFigure.lena),
        ),
      ),
    );
    final friendly = tester.widget<FriendlyInterviewer>(
      find.byType(FriendlyInterviewer),
    );
    expect(friendly.figure, same(FriendlyFigure.lena));
  });
}
