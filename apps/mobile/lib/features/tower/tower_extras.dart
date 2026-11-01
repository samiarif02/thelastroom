import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/film_kit.dart';
import '../recall/recall_controller.dart';

/// The top of the building (brief §9): the last room, always in sight, out of reach for now.
class LastRoomCard extends StatelessWidget {
  const LastRoomCard({super.key});

  static const String title = 'The Last Room';
  static const String line = 'The offer is decided here.';
  static const String kicker = 'THE TOP FLOOR';

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.finalRound;
    return _FeatureCard(
      colors: [grade.deeper, BrandVivid.night],
      glow: grade.glow,
      kicker: kicker,
      title: title,
      line: line,
      trailing: LockGlyph(color: BrandVivid.onDeepSoft, size: 22),
    );
  }
}

/// The Recall Room (brief 21) on the tower: opens the room, with today's due count.
class RecallRoomCard extends ConsumerWidget {
  const RecallRoomCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RecallRoomCardView(
    due: ref.watch(recallDueCountProvider).value ?? 0,
    onTap: () => context.go(Routes.recall),
  );
}

/// The Recall Room's card as drawn: lit with a due count when cards are waiting, calm when
/// every card is resting. The catalog shows it with a fixed count.
class RecallRoomCardView extends StatelessWidget {
  const RecallRoomCardView({super.key, required this.due, this.onTap});

  final int due;
  final VoidCallback? onTap;

  static const String title = 'Recall Room';
  static const String line =
      'One minute to beat the traps you fell for, before they catch you again.';
  static const String caughtUp = 'All caught up';

  static String dueKicker(int due) =>
      due == 1 ? '1 CARD DUE' : '$due CARDS DUE';

  static const double _badge = 40;

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.pressure;
    final waiting = due > 0;
    final kicker = waiting ? dueKicker(due) : caughtUp.toUpperCase();
    return Pressable(
      label: '$title. $kicker',
      onTap: onTap,
      child: _FeatureCard(
        colors: grade.cardGradient,
        glow: waiting ? BrandVivid.accent : grade.glow,
        kicker: kicker,
        title: title,
        line: line,
        trailing: SizedBox.square(
          dimension: _badge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: waiting ? BrandVivid.accent : BrandVivid.hairline(),
            ),
            child: Center(
              child: Text(
                '$due',
                style: BrandVividType.row.copyWith(
                  color: waiting ? BrandVivid.onAccent : BrandVivid.onDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.colors,
    required this.glow,
    required this.kicker,
    required this.title,
    required this.line,
    required this.trailing,
  });

  final List<Color> colors;
  final Color glow;
  final String kicker;
  final String title;
  final String line;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title. $kicker. $line',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(BrandSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: BrandVivid.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: BrandVividType.kicker.copyWith(color: glow),
                ),
                const SizedBox(height: 2),
                Text(title, style: BrandVividType.title),
                const SizedBox(height: BrandSpace.xs),
                Text(line, style: BrandVividType.body),
              ],
            ),
          ),
          const SizedBox(width: BrandSpace.md),
          trailing,
        ],
      ),
    ),
  );
}
