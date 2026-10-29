import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dev_directions/dev_directions_routes.dart';
import '../features/placeholder/placeholder_screen.dart';

/// Route paths. Notification deep links (brief §8) resolve to these.
abstract final class Routes {
  static const String home = '/';
}

/// Dev tools (`/dev/...`) exist in debug and profile builds only. In a release build this is a
/// compile-time `false`, so the routes aren't registered and their code is tree-shaken out.
const bool devRoutesEnabled = !kReleaseMode;

/// The app's routes. [devRoutes] is a parameter so a test can prove the release set.
List<RouteBase> appRoutes({bool devRoutes = devRoutesEnabled}) => [
  GoRoute(
    path: Routes.home,
    builder: (context, state) => const PlaceholderScreen(),
  ),
  if (devRoutes) ...DevDirectionsRoutes.routes,
];

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(initialLocation: Routes.home, routes: appRoutes());
  ref.onDispose(router.dispose);
  return router;
});
