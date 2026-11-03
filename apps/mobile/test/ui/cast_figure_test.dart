import 'package:brand/brand.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/mission/scene/mission_set.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

/// The Daylight cast (direction.md, "Characters"): four people, seven expressions, an idle
/// that reduced motion stops, a 300 ms blend between expressions, and the scenes that predate
/// Daylight showing the new faces where the old ones were.
void main() {
  group('idle', () {
    test('a blink every 4–6 s, 120 ms long, and open at 0', () {
      expect(CastIdle.blink(0), 1);
      final starts = <double>[];
      var shut = false;
      for (var t = 0.0; t < 60; t += 0.005) {
        final closing = CastIdle.blink(t) < 0.5;
        if (closing && !shut) starts.add(t);
        shut = closing;
      }
      expect(starts.length, greaterThanOrEqualTo(10));
      for (var i = 1; i < starts.length; i++) {
        expect(starts[i] - starts[i - 1], inInclusiveRange(3.95, 6.05));
      }
      // Not a metronome.
      final gaps = {
        for (var i = 1; i < starts.length; i++)
          ((starts[i] - starts[i - 1]) * 10).round(),
      };
      expect(gaps.length, greaterThan(2));
    });

    test('a nod goes down 4 and comes back', () {
      expect(CastIdle.nodDip(0), 0);
      expect(CastIdle.nodDip(0.5), closeTo(CastIdle.nodDepth, 1e-9));
      expect(CastIdle.nodDip(1), 0);
    });

    test('the talking mouth opens and closes a syllable at a time', () {
      final values = [for (var t = 0.0; t < 1; t += 0.01) CastIdle.flap(t)];
      expect(
        values.reduce((a, b) => a < b ? a : b),
        closeTo(CastIdle.flapClosed, 0.05),
      );
      expect(values.reduce((a, b) => a > b ? a : b), closeTo(1, 0.01));
    });
  });

  group('paths', () {
    test('every cast path parses, and draws', () {
      final paths = <String>[
        for (final p in CastPeople.all)
          for (final s in [...p.back, ...p.clothes, ...p.front])
            if (s is CastPath) s.d,
        for (final e in CastEyes.values)
          for (final s in CastFeatures.eye(e, CastFeatures.eyeLeftX))
            if (s is CastPath) s.d,
        for (final m in CastMouth.values)
          for (final s in CastFeatures.mouth(m))
            if (s is CastPath) s.d,
        CastBody.head.d,
        CastBody.torso.d,
      ];
      for (final d in paths) {
        expect(CastPathData.parse(d).commands, isNotEmpty, reason: d);
        expect(CastPathData.pathOf(d).getBounds().isEmpty, isFalse, reason: d);
      }
    });

    test('the open eyes morph into each other; a smile cross-fades', () {
      List<CastPathData> eye(CastEyes e) => [
        for (final s in CastFeatures.eye(e, CastFeatures.eyeLeftX))
          if (s is CastPath) CastPathData.parse(s.d),
      ];
      expect(
        eye(CastEyes.open).single.matches(eye(CastEyes.wide).single),
        isTrue,
      );
      expect(
        eye(CastEyes.open).single.matches(eye(CastEyes.up).single),
        isTrue,
      );
      final mid = CastPathData.lerp(
        eye(CastEyes.open).single,
        eye(CastEyes.wide).single,
        0.5,
      );
      expect(mid.commands.first.points.first.dx, closeTo(84 - 6.7, 1e-9));
    });

    test('an unsupported command is a clear error', () {
      expect(
        () => CastPathData.parse('M0 0 A1 1 0 0 1 2 2'),
        throwsFormatException,
      );
    });
  });

  group('controller', () {
    test('mission cues map to expressions', () {
      expect(CastController.forCue(CastCue.questionShown), CastExpression.talk);
      expect(CastController.forCue(CastCue.choosing), CastExpression.listening);
      expect(CastController.forCue(CastCue.pickSound), CastExpression.nod);
      expect(CastController.forCue(CastCue.pickWeak), CastExpression.hmm);
      expect(
        CastController.forCue(CastCue.awaitingScore),
        CastExpression.thinking,
      );
      expect(
        CastController.forCue(CastCue.debriefStrong),
        CastExpression.smile,
      );
    });

    test('a nod settles back to listening', () {
      fakeAsync((async) {
        final c = CastController()..on(CastCue.pickSound);
        expect(c.value, CastExpression.nod);
        async.elapse(CastController.nodHold);
        expect(c.value, CastExpression.listening);
        c
          ..on(CastCue.pickSound)
          ..on(CastCue.pickWeak);
        async.elapse(CastController.nodHold);
        expect(c.value, CastExpression.hmm, reason: 'a newer cue wins');
        c.dispose();
      });
    });
  });

  CastPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(CastFigure),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as CastPainter;

  Widget figure(CastExpression e, {bool idle = true}) => Center(
    child: SizedBox.square(
      dimension: 200,
      child: CastFigure(person: CastPeople.marcus, expression: e, idle: idle),
    ),
  );

  testWidgets('the idle runs, and reduced motion stops it', (tester) async {
    await pumpKit(tester, figure(CastExpression.neutral));
    await tester.pump(const Duration(seconds: 2));
    expect(painterOf(tester).clock!.value, greaterThan(0));

    await pumpKit(tester, figure(CastExpression.neutral), reduceMotion: true);
    expect(painterOf(tester).clock, isNull);
  });

  testWidgets('a change of expression blends over 300 ms, and is instant under '
      'reduced motion', (tester) async {
    await pumpKit(tester, figure(CastExpression.neutral));
    await pumpKit(tester, figure(CastExpression.hmm));
    await tester.pump(DaylightMotion.colour ~/ 2);
    expect(painterOf(tester).blend.value, inExclusiveRange(0, 1));
    expect(painterOf(tester).from, CastExpression.neutral.pose);
    await tester.pump(DaylightMotion.colour);
    expect(painterOf(tester).blend.value, 1);

    await pumpKit(tester, figure(CastExpression.nod), reduceMotion: true);
    expect(painterOf(tester).blend.value, 1);
    expect(painterOf(tester).nod.value, 0);
    expect(painterOf(tester).nodMoves, isFalse);
  });

  testWidgets('a nod dips the head and brings it back', (tester) async {
    await pumpKit(tester, figure(CastExpression.listening));
    await pumpKit(tester, figure(CastExpression.nod));
    await tester.pump(DaylightMotion.nod ~/ 2);
    expect(painterOf(tester).nod.value, inExclusiveRange(0, 1));
    await tester.pump(DaylightMotion.nod);
    expect(painterOf(tester).nod.value, 1);
  });

  testWidgets('every person draws every expression, blends included', (
    tester,
  ) async {
    for (final person in CastPeople.all) {
      for (final e in CastExpression.values) {
        await pumpKit(
          tester,
          Center(
            child: SizedBox.square(
              dimension: 160,
              child: CastFigure(person: person, expression: e),
            ),
          ),
        );
        await tester.pump(DaylightMotion.colour ~/ 3);
        expect(
          tester.takeException(),
          isNull,
          reason: '${person.id} ${e.name}',
        );
      }
    }
  });

  group('the scenes that predate Daylight', () {
    testWidgets('a scene\'s interviewer is the Daylight cast member', (
      tester,
    ) async {
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
      expect(
        tester.widget<CastFigure>(find.byType(CastFigure)).person,
        same(CastPeople.lena),
      );
    });

    test('every scene id has a person, Sam included', () {
      for (final id in SilhouetteFigure.byId.keys) {
        expect(FriendlyFigure.of(id).person.id, id);
      }
    });

    test('the face sits inside the box the subtitles keep clear of', () {
      // The head, ears and hair span x 49…151 and y 15…136 on the grid (Lena's bun is the top).
      const s = FriendlyFigure.gridScale;
      const top = FriendlyFigure.gridTop;
      final face = const Rect.fromLTRB(56, 31, 145, 136).translate(0, 0);
      final inBox = Rect.fromLTRB(
        face.left * s,
        face.top * s + top,
        face.right * s,
        face.bottom * s + top,
      );
      final keepClear = MissionSet.faceInDesign.inflate(2);
      expect(keepClear.contains(inBox.topLeft), isTrue);
      expect(keepClear.contains(inBox.bottomRight), isTrue);
      expect(FriendlyFigure.faceCenter.dy, closeTo(45, 1));
    });
  });
}
