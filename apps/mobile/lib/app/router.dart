import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/dev/sound_board_routes.dart';
import '../features/dev_catalog/dev_catalog_routes.dart';
import '../features/intro/character_screen.dart';
import '../features/mission/mission_screen.dart';
import '../features/onboarding/home_gate.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/recall/recall_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/title/wrong_floor_screen.dart';
import '../features/tower/tower_screen.dart';

/// Route paths. Notification deep links (brief §8) resolve to these.
///
/// Every screen you reach from the tower is the tower's child (brief 20), so `context.go` builds
/// a real back stack and the system back button returns to the tower instead of closing the
/// app. The tower itself, the title and onboarding are roots: back there asks "press back again
/// to exit" (`BackToExit`). The old top-level paths redirect, so deep links still open with the
/// tower underneath.
abstract final class Routes {
  static const String home = '/';
  static const String intro = '/intro';
  static const String onboarding = '/onboarding';

  /// The Tower; [lit] is the mission just finished, whose room lights up.
  static String tower({int? lit}) =>
      lit == null ? _towerPath : '$_towerPath?$_litParam=$lit';
  static const String _towerPath = '/tower';
  static const String _litParam = 'lit';

  static const String progress = '$_towerPath/$_progress';
  static const String settings = '$_towerPath/$_settings';
  static const String character = '$_towerPath/$_character';

  /// The Recall Room (brief 21).
  static const String recall = '$_towerPath/$_recall';

  /// A mission by campaign number: `/tower/mission/1`.
  static String mission(int number) => '$_towerPath/$_mission/$number';

  static const String _progress = 'progress';
  static const String _settings = 'settings';
  static const String _character = 'character';
  static const String _mission = 'mission';
  static const String _recall = 'recall';
}

/// Dev tools (`/dev/...`) exist in debug and profile builds only. In a release build this is a
/// compile-time `false`, so the routes aren't registered and their code is tree-shaken out.
const bool devRoutesEnabled = !kReleaseMode;

/// The app's routes. [devRoutes] is a parameter so a test can prove the release set. Dev
/// tools are one line each.
List<RouteBase> appRoutes({bool devRoutes = devRoutesEnabled}) => [
  GoRoute(path: Routes.home, builder: (context, state) => const HomeGate()),
  // The welcome cards went in brief 20 (onboarding explains the game); old links land there.
  GoRoute(path: Routes.intro, redirect: (context, state) => Routes.onboarding),
  GoRoute(
    path: Routes.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: Routes._towerPath,
    builder: (context, state) => TowerScreen(
      lit: int.tryParse(state.uri.queryParameters[Routes._litParam] ?? ''),
    ),
    routes: [
      GoRoute(
        path: Routes._progress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: Routes._settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes._character,
        builder: (context, state) => const CharacterScreen(),
      ),
      GoRoute(
        path: '${Routes._mission}/:number',
        builder: (context, state) => MissionScreen(
          // A bad number reaches the mission screen's locked-door state, not a crash.
          number: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: Routes._recall,
        builder: (context, state) => const RecallScreen(),
      ),
    ],
  ),
  // The paths before brief 20, for old deep links and notifications.
  for (final child in [Routes._progress, Routes._settings, Routes._character])
    GoRoute(
      path: '/$child',
      redirect: (context, state) => '${Routes._towerPath}/$child',
    ),
  GoRoute(
    path: '/${Routes._mission}/:number',
    redirect: (context, state) =>
        Routes.mission(int.tryParse(state.pathParameters['number'] ?? '') ?? 0),
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
