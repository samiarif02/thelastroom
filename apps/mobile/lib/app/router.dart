import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dev_catalog/dev_catalog_routes.dart';
import '../features/intro/character_screen.dart';
import '../features/intro/intro_screen.dart';
import '../features/intro/title_gate.dart';
import '../features/mission/mission_screen.dart';
import '../features/title/wrong_floor_screen.dart';

/// Route paths. Notification deep links (brief §8) resolve to these.
abstract final class Routes {
  static const String home = '/';
  static const String intro = '/intro';
  static const String character = '/character';

  /// A mission by campaign number: `/mission/1`.
  static String mission(int number) => '/mission/$number';
  static const String _missionPattern = '/mission/:number';
}

/// Dev tools (`/dev/...`) exist in debug and profile builds only. In a release build this is a
/// compile-time `false`, so the routes aren't registered and their code is tree-shaken out.
const bool devRoutesEnabled = !kReleaseMode;

/// The app's routes. [devRoutes] is a parameter so a test can prove the release set. Dev
/// tools are one line each.
List<RouteBase> appRoutes({bool devRoutes = devRoutesEnabled}) => [
  GoRoute(path: Routes.home, builder: (context, state) => const TitleGate()),
  GoRoute(path: Routes.intro, builder: (context, state) => const IntroScreen()),
  GoRoute(
    path: Routes.character,
    builder: (context, state) => const CharacterScreen(),
  ),
  GoRoute(
    path: Routes._missionPattern,
    builder: (context, state) => MissionScreen(
      // A bad number reaches the mission screen's locked-door state, not a crash.
      number: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
    ),
  ),
  if (devRoutes) ...DevCatalogRoutes.routes,
];

/// What an unknown address shows: the cinematic error state, never the stock page.
Widget routeErrorBuilder(BuildContext context, GoRouterState state) =>
    const WrongFloorScreen();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: appRoutes(),
    errorBuilder: routeErrorBuilder,
  );
  ref.onDispose(router.dispose);
  return router;
});
