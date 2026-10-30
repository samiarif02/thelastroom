import 'package:go_router/go_router.dart';

import 'sound_board_screen.dart';

/// `/dev/sound`. Registered only in debug and profile builds (see router.dart).
abstract final class SoundBoardRoutes {
  static const String board = '/dev/sound';

  static final List<RouteBase> routes = [
    GoRoute(path: board, builder: (context, state) => const SoundBoardScreen()),
  ];
}
