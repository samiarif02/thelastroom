import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/dev_catalog/catalog_entries.dart';
import 'package:the_last_room/features/dev_catalog/catalog_screen.dart';
import 'package:the_last_room/features/dev_catalog/catalog_stage_screen.dart';
import 'package:the_last_room/features/dev_catalog/dev_catalog_routes.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/title/wrong_floor_screen.dart';
import 'package:the_last_room/ui/film_kit.dart';

Iterable<String> _paths(List<RouteBase> routes) sync* {
  for (final r in routes) {
    if (r is GoRoute) yield r.path;
    yield* _paths(r.routes);
  }
}

const Size _phone = Size(375, 667);
const Duration _step = Duration(milliseconds: 100);

Future<void> _pumpAt(
  WidgetTester tester,
  String location, {
  bool devRoutes = true,
  double textScale = 1,
}) async {
  tester.view.physicalSize = _phone * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: appRoutes(devRoutes: devRoutes),
    errorBuilder: routeErrorBuilder,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(
          size: _phone,
          textScaler: TextScaler.linear(textScale),
        ),
        child: WidgetsApp.router(
          color: BrandColors.void_,
          routerConfig: router,
          builder: (context, child) => DefaultTextStyle(
            style: BrandType.body,
            child: AmbientClock(child: child!),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The pill scrolls sideways on a phone: bring the control into view, then tap it.
Future<void> _tapControl(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();
}

/// Scrolls the catalog's list (not the controls pill) until [name] shows.
Future<void> _scrollTo(WidgetTester tester, String name) =>
    tester.scrollUntilVisible(
      find.text(name),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

void main() {
  test('dev routes are on exactly when this is not a release build', () {
    expect(devRoutesEnabled, !kReleaseMode);
  });

  test('a release build registers no /dev route', () {
    expect(
      _paths(appRoutes(devRoutes: false)).where((p) => p.startsWith('/dev')),
      isEmpty,
    );
  });

  test('debug and profile builds register /dev/catalog', () {
    expect(_paths(appRoutes()), contains(DevCatalogRoutes.catalog));
  });

  test('the prototype /dev/directions is gone', () {
    expect(_paths(appRoutes()).where((p) => p.contains('directions')), isEmpty);
  });

  test('every entry and state has a unique id', () {
    final ids = CatalogEntries.all.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final e in CatalogEntries.all) {
      expect(e.shots, isNotEmpty, reason: e.id);
      final shots = e.shots.map((s) => s.id).toList();
      expect(shots.toSet(), hasLength(shots.length), reason: e.id);
    }
  });

  testWidgets('in a release build /dev/catalog is the wrong floor', (
    tester,
  ) async {
    await _pumpAt(tester, DevCatalogRoutes.catalog, devRoutes: false);
    expect(find.byType(CatalogScreen), findsNothing);
    expect(find.byType(WrongFloorScreen), findsOneWidget);
  });

  testWidgets('/dev/catalog lists every component', (tester) async {
    await _pumpAt(tester, DevCatalogRoutes.catalog);
    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(find.text(CatalogScreen.heading), findsOneWidget);
    for (final e in CatalogEntries.all) {
      await _scrollTo(tester, e.name);
      expect(find.text(e.name), findsOneWidget);
    }
  });

  testWidgets('a component opens from the list, and back returns', (
    tester,
  ) async {
    await _pumpAt(tester, DevCatalogRoutes.catalog);
    await tester.tap(find.text('Title card'));
    await tester.pump();
    await tester.pump(BrandMotion.cinematic);
    expect(find.byType(CatalogStageScreen), findsOneWidget);
    expect(find.byType(TitleScreen), findsOneWidget);
    await _tapControl(tester, '‹');
    expect(find.byType(CatalogScreen), findsOneWidget);
  });

  testWidgets('an unknown component falls back to the list', (tester) async {
    await _pumpAt(tester, '${DevCatalogRoutes.catalog}/nope');
    expect(find.byType(CatalogScreen), findsOneWidget);
  });

  testWidgets('the toggles reach the component: reduced motion, 2x, grade', (
    tester,
  ) async {
    await _pumpAt(tester, '${DevCatalogRoutes.catalog}/states?shot=offline');
    MediaQueryData shown() =>
        MediaQuery.of(tester.element(find.byType(SceneState)));
    expect(shown().disableAnimations, isFalse);
    expect(shown().textScaler, TextScaler.noScaling);

    await _tapControl(tester, 'STILL');
    await _tapControl(tester, '2X');
    expect(shown().disableAnimations, isTrue);
    expect(shown().textScaler, const TextScaler.linear(2));

    await _tapControl(tester, 'LOBBY');
    expect(
      tester.widget<SceneState>(find.byType(SceneState)).grade,
      ChapterGrade.pressure,
    );
  });

  testWidgets('hide clears the controls; a long press brings them back', (
    tester,
  ) async {
    await _pumpAt(tester, '${DevCatalogRoutes.catalog}/brass');
    await _tapControl(tester, 'HIDE');
    expect(find.text('REPLAY'), findsNothing);
    await tester.longPress(find.byType(CatalogStageScreen));
    await tester.pump();
    expect(find.text('REPLAY'), findsOneWidget);
  });

  // Every state of every component, run all the way through at 1x and 2x text and under
  // reduced motion: nothing overflows at any moment.
  for (final entry in CatalogEntries.all) {
    for (final shot in entry.shots) {
      for (final (label, scale, still) in const [
        ('1x', 1.0, false),
        ('2x', 2.0, false),
        ('reduced motion', 1.0, true),
      ]) {
        testWidgets('${entry.id}/${shot.id} plays through at $label', (
          tester,
        ) async {
          tester.view.physicalSize = _phone * tester.view.devicePixelRatio;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: _phone,
                textScaler: TextScaler.linear(scale),
                disableAnimations: still,
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: DefaultTextStyle(
                  style: BrandType.body,
                  child: AmbientClock(child: shot.build(ChapterGrade.lobby)),
                ),
              ),
            ),
          );
          for (var e = Duration.zero; e < shot.settle; e += _step) {
            await tester.pump(_step);
            expect(tester.takeException(), isNull, reason: 'at $e');
          }
        });
      }
    }
  }
}
