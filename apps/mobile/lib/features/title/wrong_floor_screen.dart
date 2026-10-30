import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/film_kit.dart';

/// An address with no room behind it (an old deep link, a typo on the web): the error state,
/// with the way back to the lobby. Replaces go_router's stock "Page Not Found".
class WrongFloorScreen extends StatelessWidget {
  const WrongFloorScreen({super.key});

  static const String eyebrow = 'WRONG FLOOR';
  static const String title = 'There is no room here.';
  static const String message =
      'This door doesn’t lead anywhere. Your progress is safe on this device.';
  static const String action = 'Back to the lobby';

  @override
  Widget build(BuildContext context) => SceneState.error(
    eyebrow: eyebrow,
    title: title,
    message: message,
    actionLabel: action,
    onAction: () => context.go(Routes.home),
  );
}
