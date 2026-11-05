import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/dev/sound_board_routes.dart';
import '../features/dev_catalog/dev_catalog_routes.dart';
import '../features/intro/character_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/mission/mission_screen.dart';
import '../features/onboarding/home_gate.dart';
import '../features/onboarding/how_it_works_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/progress/chapter_report_screen.dart';
import '../features/progress/past_result_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/progression/floor_cleared_screen.dart';
import '../features/recall/recall_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/title/wrong_floor_screen.dart';
import '../features/tower/all_chapters_screen.dart';
import '../features/tower/tower_screen.dart';
import '../ui/daylight/daylight_route.dart';

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

  /// The Chapter 1 report (brief 24): after Mission 7, or from "Your file".
  static const String report = '$_towerPath/$_progress/$_report';

  /// A played room's last result (brief 48), from Your file: `/tower/progress/room/4`.
  static String result(int number) => '$_towerPath/$_progress/$_room/$number';
  static const String settings = '$_towerPath/$_settings';

  /// "How it works" again (issue 75), from Settings: the explainer without the questions.
  static const String howItWorks = '$_towerPath/$_settings/$_howItWorks';
  static const String character = '$_towerPath/$_character';

  /// Every chapter, floor by floor, from "View all chapters" under the tower.
  static const String chapters = '$_towerPath/$_chapters';

  /// The Recall Room (brief 21).
  static const String recall = '$_towerPath/$_recall';

  /// The leaderboard (issue 72), a tab.
  static const String leaderboard = '$_towerPath/$_leaderboard';

  /// Floor cleared (brief 46): the reward, the first time a floor's last room is finished.
  static String floorCleared(int floor) => '$_towerPath/$_floor/$floor';

  /// A mission by campaign number: `/tower/mission/1`.
  static String mission(int number) => '$_towerPath/$_mission/$number';

  static const String _progress = 'progress';
  static const String _report = 'report';
  static const String _room = 'room';
  static const String _settings = 'settings';
  static const String _howItWorks = 'how-it-works';
  static const String _character = 'character';
  static const String _mission = 'mission';
  static const String _recall = 'recall';
  static const String _leaderboard = 'leaderboard';
  static const String _floor = 'floor';
  static const String _chapters = 'chapters';
}

/// Dev tools (`/dev/...`) exist in debug and profile builds only. In a release build this is a
/// compile-time `false`, so the routes aren't registered and their code is tree-shaken out.
const bool devRoutesEnabled = !kReleaseMode;

/// The app's routes. [devRoutes] is a parameter so a test can prove the release set. Dev
/// tools are one line each.
List<RouteBase> appRoutes({bool devRoutes = devRoutesEnabled}) => [
  GoRoute(
    path: Routes.home,
    pageBuilder: (context, state) =>
        daylightPage(state, const HomeGate(), DaylightTransition.through),
  ),
  // The welcome cards went in brief 20 (onboarding explains the game); old links land there.
  GoRoute(path: Routes.intro, redirect: (context, state) => Routes.onboarding),
  GoRoute(
    path: Routes.onboarding,
    pageBuilder: (context, state) => daylightPage(
      state,
      const OnboardingScreen(),
      DaylightTransition.through,
    ),
  ),
  GoRoute(
    path: Routes._towerPath,
    pageBuilder: (context, state) => daylightPage(
      state,
      TowerScreen(
        lit: int.tryParse(state.uri.queryParameters[Routes._litParam] ?? ''),
      ),
      DaylightTransition.through,
    ),
    routes: [
      GoRoute(
        path: Routes._progress,
        // A tab (Skills): fade-through.
        pageBuilder: (context, state) => daylightPage(
          state,
          const ProgressScreen(),
          DaylightTransition.through,
        ),
        routes: [
          GoRoute(
            path: Routes._report,
            pageBuilder: (context, state) =>
                daylightPage(state, const ChapterReportScreen()),
          ),
          GoRoute(
            path: '${Routes._room}/:number',
            // The Candidate assessment plays its own entrance: only the ground fades in.
            pageBuilder: (context, state) => daylightPage(
              state,
              PastResultScreen(
                // A bad number reaches the result's "not played" state, not a crash.
                number: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
              ),
              DaylightTransition.ground,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes._settings,
        // A tab (You): fade-through.
        pageBuilder: (context, state) => daylightPage(
          state,
          const SettingsScreen(),
          DaylightTransition.through,
        ),
        routes: [
          GoRoute(
            path: Routes._howItWorks,
            pageBuilder: (context, state) =>
                daylightPage(state, const HowItWorksScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes._chapters,
        pageBuilder: (context, state) =>
            daylightPage(state, const AllChaptersScreen()),
      ),
      GoRoute(
        path: Routes._character,
        pageBuilder: (context, state) =>
            daylightPage(state, const CharacterScreen()),
      ),
      GoRoute(
        path: '${Routes._mission}/:number',
        // Through the door: the room grows out of the door it was opened from.
        pageBuilder: (context, state) => daylightPage(
          state,
          MissionScreen(
            // A bad number reaches the mission screen's locked-door state, not a crash.
            number: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
          ),
          DaylightTransition.door,
        ),
      ),
      GoRoute(
        path: Routes._recall,
        // A tab (Recall): fade-through.
        pageBuilder: (context, state) => daylightPage(
          state,
          const RecallScreen(),
          DaylightTransition.through,
        ),
      ),
      GoRoute(
        path: Routes._leaderboard,
        // A tab (Leaderboard): fade-through.
        pageBuilder: (context, state) => daylightPage(
          state,
          const LeaderboardScreen(),
          DaylightTransition.through,
        ),
      ),
      GoRoute(
        path: '${Routes._floor}/:floor',
        // The reward choreographs its own 2.4 s: only the ground fades in.
        pageBuilder: (context, state) => daylightPage(
          state,
          FloorClearedScreen(
            floor: int.tryParse(state.pathParameters['floor'] ?? '') ?? 1,
          ),
          DaylightTransition.ground,
        ),
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

/// Every screen's page: the Daylight [transition] (route transitions, brief 50). A room's
/// door rides in `extra` ([DoorOrigin]).
Page<void> daylightPage(
  GoRouterState state,
  Widget child, [
  DaylightTransition transition = DaylightTransition.push,
]) => DaylightPage<void>(
  key: state.pageKey,
  name: state.name ?? state.path,
  arguments: <String, String>{
    ...state.pathParameters,
    ...state.uri.queryParameters,
  },
  restorationId: state.pageKey.value,
  transition: transition,
  door: transition == DaylightTransition.door
      ? DoorOrigin.from(state.extra)
      : null,
  child: child,
);

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
