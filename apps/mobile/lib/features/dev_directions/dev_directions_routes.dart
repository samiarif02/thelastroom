import 'package:go_router/go_router.dart';

import 'direction_stage_screen.dart';
import 'direction_studio.dart';
import 'directions_picker_screen.dart';

/// The `/dev/directions` routes. Registered only in debug and profile builds (see router.dart).
abstract final class DevDirectionsRoutes {
  static const String picker = '/dev/directions';

  static final List<RouteBase> routes = [
    GoRoute(
      path: picker,
      builder: (context, state) => const DirectionsPickerScreen(),
      routes: [
        GoRoute(
          path: ':id',
          redirect: (context, state) =>
              DirectionStudio.byId(state.pathParameters['id']!) == null
              ? picker
              : null,
          builder: (context, state) => DirectionStageScreen(
            studio: DirectionStudio.byId(state.pathParameters['id']!)!,
            frame: DirectionFrame.parse(state.uri.queryParameters['frame']),
            chrome: state.uri.queryParameters['chrome'] != 'off',
          ),
        ),
      ],
    ),
  ];
}
