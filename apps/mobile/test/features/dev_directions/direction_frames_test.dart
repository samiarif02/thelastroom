import 'package:brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/dev_directions/dev_directions_routes.dart';
import 'package:the_last_room/features/dev_directions/direction_studio.dart';
import 'package:the_last_room/features/dev_directions/mission_one.dart';
import 'package:the_last_room/features/dev_directions/shared/typewriter_text.dart';

/// Long enough for every frame's choreography to finish (the slowest is about 9 s: the
/// Boardroom scene's typewriter plus its 2.2 s dolly).
const Duration _settle = Duration(seconds: 14);
const Duration _step = Duration(milliseconds: 250);

Future<void> _pumpFrame(
  WidgetTester tester, {
  required DirectionStudio studio,
  required DirectionFrame frame,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize =
      const Size(375, 667) * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation:
        '${DevDirectionsRoutes.picker}/${studio.direction.id}?frame=${frame.name}',
    routes: appRoutes(),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(375, 667),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: MaterialApp.router(theme: BrandTheme.dark(), routerConfig: router),
    ),
  );
  // Pump through the whole choreography in steps, so a layout that overflows at any moment
  // (not only the last one) fails the test.
  for (var elapsed = Duration.zero; elapsed < _settle; elapsed += _step) {
    await tester.pump(_step);
  }
}

void main() {
  test('there is a studio for each of the three directions', () {
    expect(DirectionStudio.all.map((s) => s.direction.letter), ['A', 'B', 'C']);
  });

  for (final studio in DirectionStudio.all) {
    final d = studio.direction;
    group('${d.letter} ${d.name}', () {
      for (final frame in DirectionFrame.values) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('${frame.label} fits 375×667 at ${scale}x text', (
            tester,
          ) async {
            await _pumpFrame(
              tester,
              studio: studio,
              frame: frame,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }

      testWidgets('the scene ends on the three answer cards', (tester) async {
        await _pumpFrame(tester, studio: studio, frame: DirectionFrame.scene);
        for (final answer in MissionOne.answers) {
          expect(find.text(answer), findsOneWidget);
        }
      });

      testWidgets('a tap completes the typewriter line', (tester) async {
        tester.view.physicalSize =
            const Size(375, 667) * tester.view.devicePixelRatio;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          initialLocation:
              '${DevDirectionsRoutes.picker}/${d.id}?frame=scene&chrome=off',
          routes: appRoutes(),
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: BrandTheme.dark(), routerConfig: router),
        );
        // Through the letterbox and into the line, then tap until the line is complete.
        await tester.pump(const Duration(milliseconds: 2400));
        await tester.tapAt(const Offset(187, 200));
        await tester.pump();
        final line = tester.widget<TypewriterText>(find.byType(TypewriterText));
        expect(line.characters, MissionOne.line.length);
        for (var i = 0; i < 40; i++) {
          await tester.pump(_step);
        }
      });

      testWidgets('reduced motion lands every frame in its final state', (
        tester,
      ) async {
        for (final frame in DirectionFrame.values) {
          await _pumpFrame(
            tester,
            studio: studio,
            frame: frame,
            reduceMotion: true,
          );
          expect(tester.takeException(), isNull);
          if (frame == DirectionFrame.scene) {
            expect(find.text(MissionOne.answers.first), findsOneWidget);
          }
        }
      });
    });
  }
}
