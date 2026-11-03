import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

/// The way out of a room that doesn't need a back gesture (brief 24, no dead ends): Chrome and
/// iOS have no system back button, so the top bar's close tile opens the same "Leave the
/// interview?" sheet as Android's back. Daylight's raised icon tile (40 in a 48 target).
class LeaveControl extends StatelessWidget {
  const LeaveControl({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const String label = 'Leave the interview';
  static const double size = DaylightSize.hit;

  @override
  Widget build(BuildContext context) => IconTile(
    icon: PhosphorBold.x,
    semanticLabel: label,
    onPressed: onPressed,
  );
}
