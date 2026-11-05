import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../leaderboard/leaderboard_controller.dart';

/// "Show me on the leaderboard" (issue 72), on by default. Off, nobody else sees the player;
/// they still see the board and their own rank. Never an email: only the first name and a tag.
class LeaderboardVisibilitySection extends ConsumerWidget {
  const LeaderboardVisibilitySection({super.key});

  static const String heading = 'Leaderboard';
  static const String toggle = 'Show me on the leaderboard';
  static const String onLine =
      'Other players see your first name, a 4-digit tag and your XP. Never your email.';
  static const String offLine =
      'You’re hidden from other players. You still see the board and your own rank.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(leaderboardVisibleProvider).value ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(heading, style: DaylightType.heading6),
        ),
        const SizedBox(height: DaylightSpace.s4),
        SwitchRow(
          label: toggle,
          value: visible,
          onChanged: (v) =>
              unawaited(ref.read(leaderboardActionsProvider).setVisible(v)),
        ),
        Text(
          visible ? onLine : offLine,
          style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
        ),
      ],
    );
  }
}
