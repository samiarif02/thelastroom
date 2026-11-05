import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../core/backend/remote_rows.dart';
import '../../ui/daylight/daylight_kit.dart';
import 'count_up.dart';
import 'leaderboard_board.dart';
import 'league_badge.dart';

/// The ranked list after the podium: rank, name and tag, league badge, XP, streak. The
/// caller's own row is honey. One white card, rows split by a sand rule.
class BoardList extends StatelessWidget {
  const BoardList({super.key, required this.board, required this.entries});

  final Board board;
  final List<BoardEntry> entries;

  @override
  Widget build(BuildContext context) => DaylightPanel(
    padding: const EdgeInsets.symmetric(vertical: DaylightSpace.s8),
    child: Column(
      children: [
        for (final (i, e) in entries.indexed) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DaylightSpace.s16),
              child: SizedBox(
                height: 1,
                width: double.infinity,
                child: ColoredBox(color: DaylightColors.sand),
              ),
            ),
          BoardRow(entry: e, scope: board.scope),
        ],
      ],
    ),
  );
}

/// One player on the list. Screen readers hear it as one line: "Rank 4, Ali · #4821, Gold
/// league, 120 XP, 3 weeks in a row".
class BoardRow extends StatelessWidget {
  const BoardRow({super.key, required this.entry, required this.scope});

  final BoardEntry entry;
  final LeaderboardScope scope;

  static const double _rank = 32;

  static String spoken(BoardEntry e, LeaderboardScope scope) =>
      'Rank ${e.rank}, ${e.label}${e.isMe ? ', you' : ''}, ${e.league.label}, '
      '${groupThousands(e.score(scope))} XP'
      '${e.streakWeeks > 0 ? ', ${streakWords(e.streakWeeks)}' : ''}';

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: spoken(entry, scope),
    excludeSemantics: true,
    child: Container(
      color: entry.isMe ? DaylightColors.honeyTint : null,
      constraints: const BoxConstraints(minHeight: DaylightSize.hit + 8),
      padding: const EdgeInsets.symmetric(
        horizontal: DaylightSpace.s16,
        vertical: DaylightSpace.s8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _rank,
            child: Text(
              '${entry.rank}',
              style: DaylightType.tabular(DaylightType.title2)
                  .copyWith(color: DaylightColors.ink2),
            ),
          ),
          LeagueBadge(league: entry.league, label: false),
          const SizedBox(width: DaylightSpace.s12),
          Expanded(child: _NameTag(entry: entry)),
          const SizedBox(width: DaylightSpace.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${groupThousands(entry.score(scope))} XP',
                style: DaylightType.tabular(DaylightType.title3),
              ),
              if (entry.streakWeeks > 0) ...[
                const SizedBox(height: DaylightSpace.s2),
                StreakTag(weeks: entry.streakWeeks),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class _NameTag extends StatelessWidget {
  const _NameTag({required this.entry});

  final BoardEntry entry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        entry.isMe ? '${entry.name} (you)' : entry.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: DaylightType.title3,
      ),
      Text(
        '${entry.hasName ? '#' : ''}${entry.tag} · ${entry.league.title}',
        style: DaylightType.tabular(DaylightType.caption4)
            .copyWith(color: DaylightColors.ink2),
      ),
    ],
  );
}

/// "3 weeks in a row" for screen readers.
String streakWords(int weeks) =>
    weeks == 1 ? '1 week in a row' : '$weeks weeks in a row';

/// The weeks-in-a-row streak: a flame and the count ("3 wk"), honey on honey tint.
class StreakTag extends StatelessWidget {
  const StreakTag({super.key, required this.weeks});

  final int weeks;

  @override
  Widget build(BuildContext context) =>
      Tag(label: '$weeks wk', icon: PhosphorFill.fire, tone: TagTone.honey);
}

/// The caller's own row, pinned under the board: "You're #12 · 40 XP to pass Ali", their XP
/// counting up from what they saw last time, and "You're hidden" when they switched the board
/// off.
class YouRow extends StatelessWidget {
  const YouRow({
    super.key,
    required this.board,
    required this.me,
    required this.hidden,
    this.seenBefore,
  });

  final Board board;
  final BoardEntry me;
  final bool hidden;
  final int? seenBefore;

  static String headline(int rank) => 'You’re #$rank';
  static const String notYet = 'Not on the board yet';
  static const String hiddenTag = 'You’re hidden';
  static const String topLine = 'Top of the board. Hold it.';
  static const String startLine = 'Play a room to get on the board';

  /// What it takes to climb: "40 XP to pass Ali".
  static String climbLine(Board board, BoardEntry me) {
    final mine = me.score(board.scope);
    if (mine == 0) return startLine;
    final above = board.above;
    if (above == null) return topLine;
    final gap = xpToPass(mine: mine, above: above.score(board.scope));
    final who = above.rank == me.rank - 1 ? above.name : '#${above.rank}';
    return '${groupThousands(gap)} XP to pass $who';
  }

  /// Above this text scale the figures move under the words.
  static const double _roomyScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final line = climbLine(board, me);
    final xp = me.score(board.scope);
    // With no XP on this board there's no real place to boast about.
    final head = xp == 0 ? notYet : headline(me.rank);
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= _roomyScale;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(head, style: DaylightType.heading6),
            if (hidden)
              const Tag(label: hiddenTag, icon: PhosphorBold.eyeSlash),
          ],
        ),
        const SizedBox(height: DaylightSpace.s2),
        Text(
          line,
          style: DaylightType.body6.copyWith(color: DaylightColors.honeyInk),
        ),
      ],
    );
    final figures = Wrap(
      direction: roomy ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: roomy
          ? WrapCrossAlignment.end
          : WrapCrossAlignment.center,
      spacing: DaylightSpace.s4,
      children: [
        CountUp(
          from: seenBefore,
          to: xp,
          suffix: ' XP',
          style: DaylightType.title2,
        ),
        if (me.streakWeeks > 0) StreakTag(weeks: me.streakWeeks),
      ],
    );
    return Semantics(
      container: true,
      label:
          '$head, ${groupThousands(xp)} XP. $line.'
          '${hidden ? ' $hiddenTag from other players.' : ''}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DaylightColors.honeyTint,
          borderRadius: BorderRadius.circular(DaylightRadius.panel),
          boxShadow: [
            ...DaylightElevation.edgeOf(DaylightColors.honeyEdge),
            ...DaylightElevation.lift,
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DaylightSpace.s16,
            DaylightSpace.s12,
            DaylightSpace.s16,
            DaylightSpace.s12,
          ),
          child: roomy
              ? Row(
                  children: [
                    LeagueBadge(league: me.league, size: 36, label: false),
                    const SizedBox(width: DaylightSpace.s12),
                    Expanded(child: words),
                    const SizedBox(width: DaylightSpace.s8),
                    figures,
                  ],
                )
              // Large text: the words take the full width, the figures go under them.
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    words,
                    const SizedBox(height: DaylightSpace.s8),
                    figures,
                  ],
                ),
        ),
      ),
    );
  }
}
