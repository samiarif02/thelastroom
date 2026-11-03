import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/router.dart' show daylightPage;
import 'package:the_last_room/ui/daylight/daylight_kit.dart';
import 'package:the_last_room/ui/daylight/daylight_route.dart';
import 'package:the_last_room/ui/daylight/daylight_sheet.dart';

/// Brief 50 (the owner: "animations on the back button as well… a premium look"): every route
/// arrives with a Daylight transition and back plays its exact reverse; a room grows out of its
/// door; reduced motion is a short fade; back tiles nudge before they act; the swipe-back
/// scrubs the same reverse transition.
void main() {
  const size = Size(400, 800);
  const below = Key('below');
  const above = Key('above');
  const door = Rect.fromLTWH(40, 500, 48, 72);

  /// A tiny app: `/` (below) and its child `/b` (above), [kind] on the child. The child's top
  /// bar goes back to `/` the way the app's screens do.
  Future<GoRouter> boot(
    WidgetTester tester, {
    DaylightTransition kind = DaylightTransition.push,
    bool reduceMotion = false,
    bool canPop = true,
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => daylightPage(
            state,
            const DaylightGround(child: SizedBox.expand(key: below)),
            DaylightTransition.through,
          ),
          routes: [
            GoRoute(
              path: 'b',
              pageBuilder: (context, state) => daylightPage(
                state,
                PopScope<Object?>(
                  canPop: canPop,
                  child: DaylightGround(
                    key: above,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: DaylightTopBar(
                        leadingIcon: PhosphorBold.arrowLeft,
                        leadingLabel: 'Back',
                        onLeading: () => router.go('/'),
                      ),
                    ),
                  ),
                ),
                kind,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: reduceMotion),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// Pumps zero-time frames until the route above is in the tree (go_router parses first).
  Future<void> arrive(WidgetTester tester) async {
    for (var i = 0; i < 5 && find.byKey(above).evaluate().isEmpty; i++) {
      await tester.pump();
    }
    expect(find.byKey(above), findsOneWidget);
  }

  DaylightPageRoute<Object?> top(WidgetTester tester) =>
      ModalRoute.of(tester.element(find.byKey(above)))!
          as DaylightPageRoute<Object?>;

  double xOf(WidgetTester tester, Key key) =>
      tester.getTopLeft(find.byKey(key)).dx;

  group('push and back', () {
    testWidgets(
      'push slides in from the trailing edge; the screen below drifts away',
      (tester) async {
        final router = await boot(tester);
        router.go('/b');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final early = xOf(tester, above);
        expect(early, greaterThan(0));
        expect(early, lessThanOrEqualTo(DaylightRouteMotion.shift));
        expect(xOf(tester, below), lessThan(0));
        await tester.pump(const Duration(milliseconds: 120));
        expect(xOf(tester, above), lessThan(early));
        await tester.pumpAndSettle();
        expect(xOf(tester, above), 0);
        expect(top(tester).transition, DaylightTransition.push);
        expect(top(tester).transitionDuration, DaylightMotion.page);
      },
    );

    testWidgets(
      'back is the exact reverse: out to the trailing edge, the one below returns',
      (tester) async {
        final router = await boot(tester);
        router.go('/b');
        await tester.pumpAndSettle();
        router.go('/');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final early = xOf(tester, above);
        expect(early, greaterThan(0));
        expect(xOf(tester, below), lessThan(0));
        await tester.pump(const Duration(milliseconds: 120));
        expect(xOf(tester, above), greaterThan(early));
        await tester.pumpAndSettle();
        expect(find.byKey(above), findsNothing);
        expect(xOf(tester, below), 0);
      },
    );

    testWidgets('the system back gives the same reverse transition', (
      tester,
    ) async {
      final router = await boot(tester);
      router.go('/b');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(xOf(tester, above), greaterThan(0));
      expect(xOf(tester, below), lessThan(0));
      await tester.pumpAndSettle();
      expect(find.byKey(above), findsNothing);
    });

    testWidgets('fade-through: no slide, the new screen grows from 0.98', (
      tester,
    ) async {
      final router = await boot(tester, kind: DaylightTransition.through);
      router.go('/b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(xOf(tester, below), 0);
      final width =
          tester.getBottomRight(find.byKey(above)).dx -
          tester.getTopLeft(find.byKey(above)).dx;
      expect(
        width,
        greaterThanOrEqualTo(size.width * DaylightRouteMotion.throughScale),
      );
      expect(width, lessThan(size.width));
      await tester.pumpAndSettle();
      expect(top(tester).transitionDuration, DaylightMotion.page);
    });

    testWidgets('reduced motion: a 150 ms cross-fade, nothing moves', (
      tester,
    ) async {
      final router = await boot(
        tester,
        kind: DaylightTransition.door,
        reduceMotion: true,
      );
      router.go('/b', extra: const DoorOrigin(door));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(top(tester).reduced, isTrue);
      expect(top(tester).transitionDuration, DaylightMotion.reducedPage);
      expect(xOf(tester, above), 0);
      expect(xOf(tester, below), 0);
      expect(find.byType(ClipPath), findsNothing);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(above),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));
      await tester.pump(DaylightMotion.reducedPage);
      expect(top(tester).animation!.isCompleted, isTrue);
    });

    testWidgets('the Candidate assessment route: only a short fade', (
      tester,
    ) async {
      final router = await boot(tester, kind: DaylightTransition.ground);
      router.go('/b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(xOf(tester, above), 0);
      expect(xOf(tester, below), 0);
      expect(
        top(tester).transitionDuration,
        lessThanOrEqualTo(const Duration(milliseconds: 200)),
      );
      await tester.pump(DaylightMotion.ground);
      expect(top(tester).animation!.isCompleted, isTrue);
    });
  });

  group('through the door', () {
    Rect clip(WidgetTester tester) {
      final box = tester.renderObject<RenderClipPath>(
        find.ancestor(of: find.byKey(above), matching: find.byType(ClipPath)),
      );
      return box.clipper!.getClip(box.size).getBounds();
    }

    testWidgets(
      'the room grows out of the door it was opened from, and back into it',
      (tester) async {
        final router = await boot(tester, kind: DaylightTransition.door);
        router.go('/b', extra: const DoorOrigin(door));
        await arrive(tester);
        // The first frame: the arch is the door.
        expect(clip(tester), rectMoreOrLessEquals(door, epsilon: 0.5));
        expect(top(tester).transitionDuration, DaylightMotion.door);
        await tester.pump(const Duration(milliseconds: 150));
        final mid = clip(tester);
        expect(mid.contains(door.center), isTrue);
        expect(mid.width, greaterThan(door.width));
        await tester.pumpAndSettle();
        // Open: the arch no longer clips the room.
        expect(
          tester
              .widget<ClipPath>(
                find.ancestor(
                  of: find.byKey(above),
                  matching: find.byType(ClipPath),
                ),
              )
              .clipBehavior,
          Clip.none,
        );

        // Back: the room shrinks into the same door.
        router.go('/');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        final leaving = clip(tester).width;
        await tester.pump(const Duration(milliseconds: 250));
        expect(clip(tester).width, lessThan(leaving));
        expect(clip(tester).contains(door.center), isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(above), findsNothing);
      },
    );

    testWidgets('no door given: it opens from a door mid-screen', (
      tester,
    ) async {
      final router = await boot(tester, kind: DaylightTransition.door);
      router.go('/b');
      await arrive(tester);
      expect(
        clip(tester).center,
        offsetMoreOrLessEquals(size.center(Offset.zero)),
      );
      expect(clip(tester).size, DaylightRouteMotion.defaultDoor);
    });

    test('the arch ends over the whole screen, corners included', () {
      final arch = archPath(archAt(1, door, size));
      for (final corner in [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height - 1),
        Offset(size.width, size.height - 1),
        size.center(Offset.zero),
      ]) {
        expect(arch.contains(corner), isTrue, reason: '$corner');
      }
      expect(archAt(0, door, size), door);
    });

    test('a door survives the browser history (JSON in extra)', () {
      const origin = DoorOrigin(door);
      expect(DoorOrigin.from(origin.toJson()), origin);
      expect(DoorOrigin.from(origin), origin);
      expect(DoorOrigin.from('nonsense'), isNull);
    });

    testWidgets('a tapped door tells its screen where it is', (tester) async {
      await boot(tester);
      final ctx = tester.element(find.byKey(below));
      DoorTapped(const DoorOrigin(door)).dispatch(ctx);
      expect(DaylightPageRoute.takeDoor(ctx), const DoorOrigin(door));
      // Taken once.
      expect(DaylightPageRoute.takeDoor(ctx), isNull);
    });
  });

  testWidgets('a tip measuring its target waits for the route to settle', (
    tester,
  ) async {
    final router = await boot(tester);
    var below0 = false;
    unawaited(
      routeSettled(tester.element(find.byKey(below)))
          .then((_) => below0 = true),
    );
    await tester.pump();
    expect(below0, isTrue);
    router.go('/b');
    await arrive(tester);
    var arrived = false;
    var belowSettled = false;
    unawaited(
      routeSettled(tester.element(find.byKey(above)))
          .then((_) => arrived = true),
    );
    unawaited(
      routeSettled(tester.element(find.byKey(below, skipOffstage: false)))
          .then((_) => belowSettled = true),
    );
    await tester.pump(DaylightMotion.page ~/ 2);
    expect(arrived, isFalse);
    await tester.pumpAndSettle();
    expect(arrived, isTrue);
    // The screen below stays covered: it settles only once the one above has gone.
    expect(belowSettled, isFalse);
    router.go('/');
    await tester.pumpAndSettle();
    expect(belowSettled, isTrue);
  });

  group('back controls', () {
    Offset iconAt(WidgetTester tester) =>
        tester.getTopLeft(find.byIcon(PhosphorBold.arrowLeft));

    testWidgets(
      'the back tile nudges its arrow left with a light haptic, then pops',
      (tester) async {
        final haptics = <Object?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final router = await boot(tester);
        router.go('/b');
        await tester.pumpAndSettle();
        final rest = iconAt(tester);
        await tester.tap(find.bySemanticsLabel('Back'));
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        await tester.pump();
        await tester.pump(DaylightMotion.nudge ~/ 2);
        // Mid-nudge: the arrow has moved left, and the screen hasn't gone yet.
        expect(iconAt(tester).dx, lessThan(rest.dx));
        expect(
          iconAt(tester).dx,
          greaterThanOrEqualTo(rest.dx - IconTile.nudgeDistance),
        );
        expect(router.state.uri.path, '/b');
        await tester.pump(DaylightMotion.nudge);
        expect(router.state.uri.path, '/');
        await tester.pumpAndSettle();
        expect(find.byKey(above), findsNothing);
      },
    );

    testWidgets('a second tap during the nudge does not act twice', (
      tester,
    ) async {
      var taps = 0;
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: IconTile(
              icon: PhosphorBold.arrowLeft,
              semanticLabel: 'Back',
              nudge: AxisDirection.left,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(IconTile));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byType(IconTile));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('reduced motion: the back tile acts at once', (tester) async {
      final router = await boot(tester, reduceMotion: true);
      router.go('/b');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      expect(router.state.uri.path, '/');
    });
  });

  group('predictive back (Android 14+)', () {
    Future<void> gesture(
      WidgetTester tester,
      String method, [
      double? progress,
    ]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.backGesture.name,
      SystemChannels.backGesture.codec.encodeMethodCall(
        MethodCall(method, <String, Object?>{
          'touchOffset': <double>[5, 400],
          'progress': progress ?? 0,
          'swipeEdge': 0,
        }),
      ),
      (_) {},
    );

    testWidgets('the swipe scrubs the reverse transition; release pops', (
      tester,
    ) async {
      final router = await boot(tester);
      router.go('/b');
      await tester.pumpAndSettle();
      await gesture(tester, 'startBackGesture', 0);
      await tester.pump();
      await gesture(tester, 'updateBackGestureProgress', 0.5);
      await tester.pump();
      // Half way: the screen behind is previewed, the top one half way out.
      expect(top(tester).animation!.value, closeTo(0.5, 0.01));
      expect(xOf(tester, above), closeTo(DaylightRouteMotion.shift / 2, 1));
      expect(find.byKey(below), findsOneWidget);
      await gesture(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.byKey(above), findsNothing);
      expect(router.state.uri.path, '/');
    });

    testWidgets('a cancelled swipe springs back', (tester) async {
      final router = await boot(tester);
      router.go('/b');
      await tester.pumpAndSettle();
      await gesture(tester, 'startBackGesture', 0);
      await gesture(tester, 'updateBackGestureProgress', 0.3);
      await tester.pump();
      expect(top(tester).animation!.value, closeTo(0.7, 0.01));
      await gesture(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(xOf(tester, above), 0);
      expect(router.state.uri.path, '/b');
    });

    testWidgets('a screen that asks before leaving is not swiped away', (
      tester,
    ) async {
      final router = await boot(tester, canPop: false);
      router.go('/b');
      await tester.pumpAndSettle();
      await gesture(tester, 'startBackGesture', 0);
      await gesture(tester, 'updateBackGestureProgress', 0.5);
      await tester.pump();
      expect(top(tester).animation!.value, 1);
      expect(xOf(tester, above), 0);
    });
  });

  group('sheets', () {
    testWidgets('a sheet rises a touch past its rest, then settles', (
      tester,
    ) async {
      final router = await boot(tester);
      final ctx = tester.element(find.byKey(below));
      expect(router.state.uri.path, '/');
      showDaylightSheet<void>(
        ctx,
        label: 'Floor 1',
        builder: (_) => const SizedBox(height: 200, key: Key('sheet')),
      ).ignore();
      await tester.pump();
      final tops = <double>[];
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        tops.add(tester.getTopLeft(find.byKey(const Key('sheet'))).dy);
      }
      await tester.pumpAndSettle();
      final rest = tester.getTopLeft(find.byKey(const Key('sheet'))).dy;
      expect(tops.reduce((a, b) => a < b ? a : b), lessThan(rest - 0.5));
      // The white runs on below its foot, so the settle opens no gap.
      expect(
        find.descendant(
          of: find.byType(DaylightSheet),
          matching: find.byWidgetPredicate(
            (w) => w is Positioned && w.bottom == -DaylightSheet.skirt,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
