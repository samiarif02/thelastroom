import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  const close = CameraShot(
    scale: 1.75,
    focus: Alignment(0, -0.02),
    target: Alignment(0, -0.36),
  );
  const backClose = CameraShot(scale: 1.18, focus: Alignment(0, -0.2));
  const layers = [
    CameraLayer(
      child: SizedBox.expand(key: Key('back')),
      close: backClose,
    ),
    CameraLayer(
      child: SizedBox.expand(key: Key('front')),
      close: close,
    ),
  ];

  test('a shot lerps between its framings', () {
    final mid = CameraShot.lerp(CameraShot.wide, close, 0.5);
    expect(mid.scale, closeTo(1.375, 1e-9));
    expect(CameraShot.lerp(CameraShot.wide, close, 1), close);
    expect(CameraShot.lerp(CameraShot.wide, close, 0), CameraShot.wide);
  });

  testWidgets('the rig frames every layer, back to front', (tester) async {
    await pumpKit(tester, const CameraRig(t: 0.5, layers: layers));
    final framed = tester.widgetList<Framed>(find.byType(Framed)).toList();
    expect(framed, hasLength(2));
    // Parallax: the far layer has travelled less than the near one.
    expect(framed.first.shot.scale, lessThan(framed.last.shot.scale));
  });

  testWidgets('reduced motion cross-fades the framings instead of moving', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const CameraRig(t: 0.3, layers: layers),
      reduceMotion: true,
    );
    final shots = tester
        .widgetList<Framed>(find.byType(Framed))
        .map((f) => f.shot)
        .toList();
    expect(shots, [CameraShot.wide, backClose, CameraShot.wide, close]);
  });

  testWidgets('the dolly pushes in over 2.2 s and reports both ends', (
    tester,
  ) async {
    final beats = <String>[];
    Widget dolly(bool closeUp) => DollyCamera(
      closeUp: closeUp,
      layers: layers,
      onPushStart: () => beats.add('start'),
      onPushEnd: () => beats.add('end'),
    );
    await pumpKit(tester, dolly(false));
    await pumpKit(tester, dolly(true));
    await tester.pump(BrandMotion.dolly ~/ 2);
    final mid = tester.widgetList<Framed>(find.byType(Framed)).last.shot;
    expect(mid.scale, inExclusiveRange(1, close.scale));
    expect(beats, ['start']);
    await tester.pump(BrandMotion.dolly);
    expect(tester.widgetList<Framed>(find.byType(Framed)).last.shot, close);
    expect(beats, ['start', 'end']);
  });

  group('hard cut', () {
    const black = Key('black');
    Finder blackFrame() => find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == BrandColors.void_,
    );

    testWidgets('a new shot cuts through one black frame', (tester) async {
      var cuts = 0;
      Widget cut(String shot) => HardCut(
        shot: shot,
        onCut: () => cuts++,
        child: Text(shot, key: black),
      );
      await pumpKit(tester, cut('wide'));
      expect(blackFrame(), findsNothing);
      await pumpKit(tester, cut('close'));
      expect(cuts, 1);
      expect(blackFrame(), findsOneWidget);
      expect(find.text('close'), findsOneWidget);
      // The black frame's clock starts on the next frame, then holds for 1/24 s.
      await tester.pump();
      await tester.pump(BrandMotion.hardCut * 2);
      await tester.pump();
      expect(blackFrame(), findsNothing);
    });

    testWidgets('reduced motion cross-fades instead of cutting to black', (
      tester,
    ) async {
      var cuts = 0;
      Widget cut(String shot) =>
          HardCut(shot: shot, onCut: () => cuts++, child: Text(shot));
      await pumpKit(tester, cut('wide'), reduceMotion: true);
      await pumpKit(tester, cut('close'), reduceMotion: true);
      expect(cuts, 1);
      expect(blackFrame(), findsNothing);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      await tester.pump();
      await tester.pump(BrandMotion.reducedMotionFade * 2);
      await tester.pump();
      expect(find.text('wide'), findsNothing);
    });

    testWidgets('the same shot does not cut', (tester) async {
      var cuts = 0;
      await pumpKit(
        tester,
        HardCut(shot: 1, onCut: () => cuts++, child: const Text('a')),
      );
      await pumpKit(
        tester,
        HardCut(shot: 1, onCut: () => cuts++, child: const Text('b')),
      );
      expect(cuts, 0);
    });
  });
}
