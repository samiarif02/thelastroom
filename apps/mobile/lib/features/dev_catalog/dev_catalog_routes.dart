import 'package:go_router/go_router.dart';

import 'catalog_entries.dart';
import 'catalog_screen.dart';
import 'catalog_stage_screen.dart';

/// The `/dev/catalog` routes. Registered only in debug and profile builds (see router.dart).
abstract final class DevCatalogRoutes {
  static const String catalog = '/dev/catalog';

  static final List<RouteBase> routes = [
    GoRoute(
      path: catalog,
      builder: (context, state) => const CatalogScreen(),
      routes: [
        GoRoute(
          path: ':id',
          redirect: (context, state) =>
              CatalogEntries.byId(state.pathParameters['id']!) == null
              ? catalog
              : null,
          builder: (context, state) => CatalogStageScreen(
            entry: CatalogEntries.byId(state.pathParameters['id']!)!,
            shot: state.uri.queryParameters['shot'],
            chrome: state.uri.queryParameters['chrome'] != 'off',
          ),
        ),
      ],
    ),
  ];
}
