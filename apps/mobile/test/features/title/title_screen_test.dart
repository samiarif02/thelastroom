import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/features/title/daylight_title.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/tower/tower_door.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';

void main() {
  Future<void> boot(
    WidgetTester tester, {
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize =
        const Size(375, 667) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: const ProviderScope(child: TheLastRoomApp()),
      ),
    );
    // The cast breathes, so the frame never settles: pump through the title.
    for (var e = Duration.zero; e < DaylightTitle.length * 2; e += _step) {
      await tester.pump(_step);
      expect(tester.takeException(), isNull);
    }
  }

  testWidgets('a first launch opens on the Daylight title, the tower lit', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.byType(DaylightGround), findsWidgets);
    // The four interviewers arrive in their arches.
    expect(find.byType(ArchPortrait), findsNWidgets(CastPeople.all.length));
    expect(find.text(TitleScreen.title), findsOneWidget);
    expect(find.text(TitleScreen.tagline), findsOneWidget);
    expect(tester.widget<TitleTower>(find.byType(TitleTower)).lit, 1);
    // The rooms are the tower's own doors: 21, floor 1 and 2 lit, Sam's waiting at the top.
    final doors = tester.widgetList<TowerDoor>(find.byType(TowerDoor)).toList();
    expect(doors, hasLength(TitleTowerPainter.across * 3));
    expect(doors.where((d) => d.state == DoorState.lit), hasLength(14));
    expect(doors.where((d) => d.state == DoorState.waiting), hasLength(1));
    expect(doors.where((d) => d.lighting == 1), hasLength(15));
  });

  testWidgets('the doors light floor by floor, Sam\'s last', (tester) async {
    expect(TitleTower.doorLighting(0, 0), 0);
    // Halfway: floor 1 is lit, floor 2 is on its way, Sam's is still closed.
    expect(TitleTower.doorLighting(0, 0.5), 1);
    expect(TitleTower.doorLighting(6, 0.5), 1);
    expect(TitleTower.doorLighting(13, 0.5), 0);
    expect(TitleTower.doorLighting(14, 0.9), 0);
    expect(TitleTower.doorLighting(14, 1), 1);
  });

  testWidgets('the doors stand inside the tower at phone widths', (
    tester,
  ) async {
    for (final width in [360.0, 375.0, 411.0]) {
      final size = Size(width, width * 0.8);
      final layout = TitleTowerLayout.of(size);
      final doorH = layout.doorWidth * TowerDoor.aspect;
      expect(layout.doorWidth, greaterThanOrEqualTo(20));
      for (final door in layout.doors) {
        expect(door.at.dx, greaterThanOrEqualTo(layout.left));
        expect(
          door.at.dx + layout.doorWidth,
          lessThanOrEqualTo(layout.left + layout.bodyWidth),
        );
        expect(door.at.dy, greaterThanOrEqualTo(layout.floorsTop));
        expect(
          door.at.dy + doorH,
          lessThanOrEqualTo(size.height - layout.street),
        );
      }
    }
  });

  testWidgets('the title lasts about a second and a half', (tester) async {
    expect(DaylightTitle.length, lessThanOrEqualTo(const Duration(seconds: 2)));
  });

  testWidgets('under reduced motion it shows its last frame at once', (
    tester,
  ) async {
    await boot(tester, reduceMotion: true);
    expect(tester.widget<TitleTower>(find.byType(TitleTower)).lit, 1);
  });

  testWidgets('text inherits the brand style, not the debug fallback', (
    tester,
  ) async {
    await boot(tester);
    // Without a DefaultTextStyle ancestor Flutter draws a yellow double underline.
    final style = DefaultTextStyle.of(
      tester.element(find.text(TitleScreen.tagline)),
    ).style;
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(style.fontFamily, DaylightType.body3.fontFamily);
  });

  testWidgets('the title survives 2x text without overflow', (tester) async {
    await boot(tester, textScale: 2);
    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets('the name is announced as a header', (tester) async {
    final handle = tester.ensureSemantics();
    await boot(tester);
    expect(
      tester.getSemantics(find.text(TitleScreen.title)),
      isSemantics(isHeader: true),
    );
    handle.dispose();
  });
}

const Duration _step = Duration(milliseconds: 100);
