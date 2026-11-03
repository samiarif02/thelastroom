import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../recall/recall_controller.dart';

/// The Recall Room on the tower (brief 21), from the due count.
class RecallRoomCard extends ConsumerWidget {
  const RecallRoomCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RecallRoomCardView(
    due: ref.watch(recallDueCountProvider).value ?? 0,
    onTap: () => context.go(Routes.recall),
  );
}

/// The Recall card as drawn (direction.md §1, mockup `01b`): the recall tint, r24, the room's
/// host in an arch, "Recall Room · due today", how many notes and how long; calm when every
/// note is resting. The whole card is the button. The catalog shows it with a fixed count.
class RecallRoomCardView extends StatelessWidget {
  const RecallRoomCardView({super.key, required this.due, this.onTap});

  final int due;
  final VoidCallback? onTap;

  static const String title = 'Recall Room';
  static const String caughtUp = 'All caught up';
  static const String restingLine =
      'Priya will leave a note when something needs another look.';

  static String dueKicker(int due) => '$title · due today';
  static String dueTitle(int due) =>
      due == 1 ? '1 note is waiting' : '$due notes are waiting';

  /// About a minute for every two notes, never "0 minutes".
  static String minutes(int due) {
    final m = (due / 2).ceil();
    return m <= 1
        ? 'About a minute, before they catch you again.'
        : 'About $m minutes, before they catch you again.';
  }

  static const double _face = 48;
  static const double _faceHeight = 56;
  static const double _arrow = 20;

  @override
  Widget build(BuildContext context) {
    final waiting = due > 0;
    final kicker = waiting ? dueKicker(due) : '$title · $caughtUp';
    final head = waiting ? dueTitle(due) : caughtUp;
    final line = waiting ? minutes(due) : restingLine;
    return Tactile(
      label: '$kicker. $head. $line',
      onTap: onTap,
      style: TactileStyle(
        face: DaylightColors.recallTint,
        edge: waiting ? DaylightColors.recallSoft : DaylightColors.recallTint,
        radius: BorderRadius.circular(DaylightRadius.panel),
        depth: waiting ? DaylightSize.edge : 0,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DaylightSpace.s12,
          DaylightSpace.s12,
          DaylightSpace.s16,
          DaylightSpace.s12,
        ),
        child: Row(
          children: [
            const ArchPortrait(
              person: CastPeople.priya,
              expression: CastExpression.smile,
              width: _face,
              height: _faceHeight,
              ground: DaylightColors.recallSoft,
              idle: false,
            ),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: DaylightType.caption3.copyWith(
                      color: DaylightColors.recall,
                    ),
                  ),
                  const SizedBox(height: DaylightSpace.s2),
                  Text(head, style: DaylightType.body1),
                  Text(
                    line,
                    style: DaylightType.body6.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            if (waiting) ...[
              const SizedBox(width: DaylightSpace.s8),
              const Icon(
                PhosphorBold.arrowRight,
                size: _arrow,
                color: DaylightColors.recall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
