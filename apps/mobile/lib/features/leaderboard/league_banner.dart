import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'count_up.dart';
import 'league_badge.dart';

/// The top of the board: the player's league (by total XP, from this device, so it shows with
/// no backend and offline), the bar to the next one and what's left ("260 XP to Gold").
class LeagueBanner extends StatelessWidget {
  const LeagueBanner({super.key, required this.totalXp, this.seenXp});

  final int totalXp;

  /// The total when they last looked; the figure counts up from it.
  final int? seenXp;

  static const String kicker = 'Your league';
  static const double _badge = 56;

  static String toNext(int xp, League next) =>
      '${groupThousands(xp)} XP to ${next.title}';
  static const String top =
      'The top league. Every XP from here is a new record.';

  @override
  Widget build(BuildContext context) {
    final league = leagueFor(totalXp);
    final c = league.colours;
    final next = league.next;
    final left = xpToNextLeague(totalXp);
    final line = next == null || left == null ? top : toNext(left, next);
    return Semantics(
      container: true,
      label: '$kicker: ${league.label}, ${groupThousands(totalXp)} XP. $line',
      excludeSemantics: true,
      child: DaylightPanel(
        color: c.tint,
        edge: c.base,
        child: Row(
          children: [
            LeagueBadge(league: league, size: _badge, label: false),
            const SizedBox(width: DaylightSpace.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: DaylightType.caption3.copyWith(color: c.deep),
                  ),
                  const SizedBox(height: DaylightSpace.s2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: DaylightSpace.s8,
                    children: [
                      Text(league.label, style: DaylightType.heading5),
                      CountUp(
                        from: seenXp,
                        to: totalXp,
                        suffix: ' XP',
                        style: DaylightType.title3.copyWith(color: c.deep),
                      ),
                    ],
                  ),
                  const SizedBox(height: DaylightSpace.s8),
                  ProgressTrack(
                    value: leagueProgress(totalXp),
                    fill: c.base,
                    track: DaylightColors.raised,
                  ),
                  const SizedBox(height: DaylightSpace.s8),
                  Text(
                    line,
                    style: DaylightType.body6.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
