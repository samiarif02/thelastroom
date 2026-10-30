import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dev_catalog/dev_catalog_routes.dart';
import '../features/title/title_screen.dart';
import '../features/title/wrong_floor_screen.dart';

/// Route paths. Notification deep links (brief §8) resolve to these.
abstract final class Routes {
  static const String home = '/';
}

/// Dev tools (`/dev/...`) exist in debug and profile builds only. In a release build this is a
/// compile-time `false`, so the routes aren't registered and their code is tree-shaken out.
const bool devRoutesEnabled = !kReleaseMode;

/// The app's routes. [devRoutes] is a parameter so a test can prove the release set. Dev
/// tools are one line each.
List<RouteBase> appRoutes({bool devRoutes = devRoutesEnabled}) => [
  GoRoute(path: Routes.home, builder: (context, state) => const TitleScreen()),
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
