import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/dev/sound_board_routes.dart';
import '../features/dev_catalog/dev_catalog_routes.dart';
import '../features/intro/character_screen.dart';
import '../features/intro/intro_screen.dart';
import '../features/mission/mission_screen.dart';
import '../features/onboarding/home_gate.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/title/wrong_floor_screen.dart';
import '../features/tower/tower_screen.dart';

/// Route paths. Notification deep links (brief §8) resolve to these.
abstract final class Routes {
  static const String home = '/';
  static const String intro = '/intro';
  static const String character = '/character';
  static const String onboarding = '/onboarding';
  static const String progress = '/progress';

  /// The Tower; [lit] is the mission just finished, whose room lights up.
  static String tower({int? lit}) =>
      lit == null ? _towerPath : '$_towerPath?$_litParam=$lit';
  static const String _towerPath = '/tower';
  static const String _litParam = 'lit';

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
  GoRoute(path: Routes.home, builder: (context, state) => const HomeGate()),
  GoRoute(path: Routes.intro, builder: (context, state) => const IntroScreen()),
  GoRoute(
    path: Routes.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: Routes._towerPath,
    builder: (context, state) => TowerScreen(
      key: ValueKey(state.uri),
      lit: int.tryParse(state.uri.queryParameters[Routes._litParam] ?? ''),
    ),
  ),
  GoRoute(
    path: Routes.progress,
    builder: (context, state) => const ProgressScreen(),
  ),
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
  if (devRoutes) ...SoundBoardRoutes.routes,
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
