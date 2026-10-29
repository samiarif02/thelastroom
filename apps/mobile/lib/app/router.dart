import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/placeholder/placeholder_screen.dart';

/// Route paths. Notification deep links (brief §8) resolve to these.
abstract final class Routes {
  static const String home = '/';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const PlaceholderScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
