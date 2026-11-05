import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../core/backend/remote_rows.dart';
import '../../ui/daylight/daylight_kit.dart';
import 'count_up.dart';
import 'leaderboard_board.dart';
import 'league_badge.dart';

/// The top three on plinths (2nd, 1st, 3rd), each in the cast's arch with their league badge,
/// and Priya cheering them on. 1st stands tallest on the honey plinth; sparkles pop in round
/// them (still under reduced motion).
class Podium extends StatelessWidget {
  const Podium({super.key, required this.board});

  final Board board;

  static const String cheerWeek =
      'Look at this week’s climbers. One room puts you up there.';
  static const String cheerAll =
      'The tower’s best so far. Every room you play adds up.';
  static const String cheerer = 'Priya · recruiter';

  @override
  Widget build(BuildContext context) {
    final top = board.podium;
    // 2nd, 1st, 3rd: the winner in the middle.
    final order = [
      if (top.length > 1) top[1],
      top.first,
      if (top.length > 2) top[2],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const ArchPortrait(
              person: CastPeople.priya,
              expression: CastExpression.smile,
              width: 56,
              height: 68,
              ground: DaylightColors.honeyTint,
              idle: false,
            ),
            const SizedBox(width: DaylightSpace.s8),
            Expanded(
              child: SpeechBubble(
                line: board.scope == LeaderboardScope.week
                    ? cheerWeek
                    : cheerAll,
                speaker: cheerer,
                tail: BubbleTail.left,
                lineStyle: DaylightType.body4,
                flat: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final e in order)
              Expanded(
                child: _Step(entry: e, scope: board.scope),
              ),
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.entry, required this.scope});

  final BoardEntry entry;
  final LeaderboardScope scope;

  static const List<double> _plinth = [76, 56, 44];
  static const List<double> _arch = [84, 68, 68];
  static const double _archRatio = 1.2;
  static const double _badge = 28;

  @override
  Widget build(BuildContext context) {
    final place = (entry.rank - 1).clamp(0, 2);
    final first = place == 0;
    final c = entry.league.colours;
    final width = _arch[place];
    final xp = entry.score(scope);
    return Semantics(
      container: true,
      label:
          '${_ordinal(entry.rank)} place, ${entry.label}${entry.isMe ? ', you' : ''}, '
          '${entry.league.label}, ${groupThousands(xp)} XP',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: _badge / 2),
                  child: SizedBox(
                    width: width,
                    height: width * _archRatio,
                    child: ArchFrame(
                      ground: c.tint,
                      border: first ? DaylightSpace.s4 : DaylightSpace.s2,
                      borderColor: first ? DaylightColors.honey : c.base,
                      child: Center(
                        child: Text(
                          entry.name.characters.first.toUpperCase(),
                          style:
                              (first
                                      ? DaylightType.heading3
                                      : DaylightType.heading4)
                                  .copyWith(color: c.deep),
                        ),
                      ),
                    ),
                  ),
                ),
                LeagueBadge(league: entry.league, size: _badge, label: false),
                if (first) ...const [
                  Positioned(top: -6, left: -10, child: _Sparkle(size: 18)),
                  Positioned(
                    top: 18,
                    right: -14,
                    child: _Sparkle(size: 14, delay: 1),
                  ),
                  Positioned(
                    top: -14,
                    right: 4,
                    child: _Sparkle(size: 12, delay: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: DaylightSpace.s8),
            Text(
              entry.isMe ? '${entry.name} (you)' : entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: DaylightType.title3,
            ),
            Text(
              entry.hasName ? '#${entry.tag}' : entry.tag,
              style: DaylightType.tabular(DaylightType.caption4)
                  .copyWith(color: DaylightColors.ink2),
            ),
            const SizedBox(height: DaylightSpace.s4),
            Tag(
              label: '${groupThousands(xp)} XP',
              tone: first ? TagTone.honeySolid : TagTone.honey,
            ),
            const SizedBox(height: DaylightSpace.s8),
            Container(
              height: _plinth[place],
              width: double.infinity,
              decoration: BoxDecoration(
                color: first ? DaylightColors.honey : DaylightColors.sand,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DaylightRadius.card),
                ),
                boxShadow: DaylightElevation.edgeOf(
                  first ? DaylightColors.honeyEdge : DaylightColors.sand2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.rank}',
                style: DaylightType.tabular(DaylightType.heading4).copyWith(
                  color: first ? DaylightColors.onHoney : DaylightColors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ordinal(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
}

/// A honey sparkle that pops in after [delay] staggers (and is simply there under reduced
/// motion): the podium's flourish.
class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, this.delay = 0});

  final double size;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      PhosphorFill.sparkle,
      size: size,
      color: DaylightColors.honey,
    );
    if (MediaQuery.disableAnimationsOf(context)) return icon;
    final wait = DaylightMotion.stagger * (delay + 2);
    final total = DaylightMotion.move + wait;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        wait.inMicroseconds / total.inMicroseconds,
        1,
        curve: DaylightMotion.settle,
      ),
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: icon,
    );
  }
}
