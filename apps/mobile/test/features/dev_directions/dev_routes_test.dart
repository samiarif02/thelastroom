import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/dev_directions/dev_directions_routes.dart';
import 'package:the_last_room/features/dev_directions/directions_picker_screen.dart';

Iterable<String> _paths(List<RouteBase> routes) sync* {
  for (final r in routes) {
    if (r is GoRoute) yield r.path;
    yield* _paths(r.routes);
  }
}

Future<void> _pumpAt(
  WidgetTester tester,
  List<RouteBase> routes,
  String location,
) async {
  final router = GoRouter(initialLocation: location, routes: routes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: BrandTheme.dark(), routerConfig: router),
  );
  await tester.pump();
}

void main() {
  test('dev routes are on exactly when this is not a release build', () {
    expect(devRoutesEnabled, !kReleaseMode);
  });

  test('a release build registers no /dev route', () {
    final paths = _paths(appRoutes(devRoutes: false)).toList();
    expect(paths, isNot(contains(DevDirectionsRoutes.picker)));
    expect(paths.where((p) => p.startsWith('/dev')), isEmpty);
  });

  test('debug and profile builds register /dev/directions', () {
    expect(_paths(appRoutes()), contains(DevDirectionsRoutes.picker));
  });

  testWidgets('in a release build /dev/directions does not open the picker', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      appRoutes(devRoutes: false),
      DevDirectionsRoutes.picker,
    );
    expect(find.byType(DirectionsPickerScreen), findsNothing);
  });

  testWidgets('in a debug build /dev/directions opens the picker', (
    tester,
  ) async {
    await _pumpAt(tester, appRoutes(), DevDirectionsRoutes.picker);
    expect(find.byType(DirectionsPickerScreen), findsOneWidget);
    expect(find.text(DirectionsPickerScreen.heading), findsOneWidget);
  });

  testWidgets('an unknown direction id falls back to the picker', (
    tester,
  ) async {
    await _pumpAt(tester, appRoutes(), '${DevDirectionsRoutes.picker}/nope');
    expect(find.byType(DirectionsPickerScreen), findsOneWidget);
  });
}
