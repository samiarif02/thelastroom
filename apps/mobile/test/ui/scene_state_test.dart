import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'harness.dart';

void main() {
  final kinds = <String, SceneState Function(VoidCallback?)>{
    'loading': (_) => const SceneState.loading(),
    'empty': (tap) => SceneState.empty(actionLabel: 'Begin', onAction: tap),
    'offline': (tap) => SceneState.offline(onAction: tap),
    'error': (tap) => SceneState.error(onAction: tap),
  };

  for (final MapEntry(key: name, value: build) in kinds.entries) {
    for (final size in const [Size(320, 568), Size(375, 667)]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets(
          '$name fits ${size.width.toInt()} wide at ${scale}x text, all the way in',
          (tester) async {
            await pumpKit(tester, build(() {}), size: size, textScale: scale);
            await pumpThrough(tester, BrandMotion.cinematic);
            expect(find.byType(SceneState), findsOneWidget);
          },
        );
      }
    }
  }

  testWidgets('offline says the lights are out and progress is safe', (
    tester,
  ) async {
    await pumpKit(tester, const SceneState.offline());
    await tester.pump(BrandMotion.cinematic);
    expect(find.text('The lights are out.'), findsOneWidget);
    expect(find.text('Your progress is safe on this device.'), findsOneWidget);
  });

  testWidgets('offline turns the tower dark; the others leave lights on', (
    tester,
  ) async {
    for (final (state, lit) in [
      (const SceneState.offline(), false),
      (const SceneState.loading(), true),
      (const SceneState.empty(), true),
      (const SceneState.error(), true),
    ]) {
      await pumpKit(tester, state);
      expect(
        tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((p) => p.painter)
                .whereType<TowerPainter>()
                .single
                .lit >
            0,
        lit,
        reason: state.kind.name,
      );
    }
  });

  testWidgets('loading has a rule, not a spinner, and no button', (
    tester,
  ) async {
    await pumpKit(tester, const SceneState.loading());
    await tester.pump(BrandMotion.cinematic);
    expect(find.byType(LoadingRule), findsOneWidget);
    expect(find.byType(BrassButton), findsNothing);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('the action shows only with a callback, and takes a tap', (
    tester,
  ) async {
    await pumpKit(tester, const SceneState.error());
    expect(find.byType(BrassButton), findsNothing);

    var taps = 0;
    await pumpKit(tester, SceneState.error(onAction: () => taps++));
    await tester.pump(BrandMotion.cinematic);
    expect(find.text(SceneState.retryLabel), findsOneWidget);
    await tester.tap(find.byType(BrassButton));
    expect(taps, 1);
  });

  testWidgets('the title is a header screen readers hear when it changes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, const SceneState.offline());
    await tester.pump(BrandMotion.cinematic);
    expect(
      tester.getSemantics(find.text(SceneState.offlineTitle)),
      isSemantics(isHeader: true, isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets(
    'under reduced motion it is in at once and the rule holds still',
    (tester) async {
      await pumpKit(tester, const SceneState.loading(), reduceMotion: true);
      await tester.pump(BrandMotion.reducedMotionFade);
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(SceneState),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 1);
      expect(tester.takeException(), isNull);
    },
  );

  group('BrassButton', () {
    Widget button({VoidCallback? onTap}) => Center(
      child: BrassButton(label: 'Back to the lobby', onTap: onTap),
    );

    for (final scale in const [1.0, 2.0]) {
      testWidgets('is a 44 pt target at ${scale}x text', (tester) async {
        await pumpKit(tester, button(onTap: () {}), textScale: scale);
        final size = tester.getSize(find.byType(BrassButton));
        expect(size.height, greaterThanOrEqualTo(BrandSpace.minTarget));
        expect(size.width, greaterThanOrEqualTo(BrandSpace.minTarget));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a tap calls back; without a callback it is disabled', (
      tester,
    ) async {
      var taps = 0;
      await pumpKit(tester, button(onTap: () => taps++));
      await tester.tap(find.byType(BrassButton));
      expect(taps, 1);

      final handle = tester.ensureSemantics();
      await pumpKit(tester, button());
      expect(
        tester.getSemantics(find.byType(BrassButton)),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Back to the lobby',
        ),
      );
      handle.dispose();
    });
  });
}
