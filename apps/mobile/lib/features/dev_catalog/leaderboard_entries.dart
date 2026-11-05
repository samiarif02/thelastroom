import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../core/backend/remote_rows.dart';
import '../leaderboard/board_rows.dart';
import '../leaderboard/leaderboard_board.dart';
import '../leaderboard/league_badge.dart';
import '../leaderboard/league_banner.dart';
import '../leaderboard/podium.dart';
import 'catalog_entry.dart';
import 'daylight_backdrop.dart';

/// The leaderboard's pieces (issue 72): the five league badges, the league banner, the podium,
/// a ranked row and the caller's pinned row.
abstract final class LeaderboardEntries {
  static final CatalogEntry board = CatalogEntry(
    id: 'daylight-leaderboard',
    name: 'Leaderboard',
    note:
        'LeagueBadge (Bronze to Diamond), LeagueBanner, Podium, BoardRow, YouRow: the '
        'leaderboard tab.',
    shots: [
      CatalogShot(
        id: 'leagues',
        label: 'Leagues and rows',
        build: (_) => const _Leagues(),
      ),
      CatalogShot(id: 'podium', label: 'Podium', build: (_) => _Podium()),
    ],
  );
}

BoardEntry _entry(
  int rank,
  String? name,
  String tag,
  int week,
  int total, {
  int streak = 0,
  bool me = false,
}) => BoardEntry(
  rank: rank,
  firstName: name,
  tag: tag,
  totalXp: total,
  weekXp: week,
  streakWeeks: streak,
  isMe: me,
);

final Board _sample = Board(
  scope: LeaderboardScope.week,
  entries: [
    _entry(1, 'Maya', '1204', 410, 1580, streak: 5),
    _entry(2, 'Jon', '7731', 365, 2640, streak: 3),
    _entry(3, 'Noor', '0458', 300, 3810, streak: 8),
    _entry(11, 'Ali', '4821', 139, 1150, streak: 1),
    _entry(12, 'Sami', '3920', 100, 940, streak: 2, me: true),
  ],
  fetchedAt: DateTime.utc(2026, 11, 4, 10),
);

class _Leagues extends StatelessWidget {
  const _Leagues();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    children: [
      const CatalogLabel('League badges'),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final l in League.values)
            Column(
              children: [
                LeagueBadge(league: l, size: 40),
                const SizedBox(height: DaylightSpace.s4),
                Text(l.title, style: DaylightType.caption4),
              ],
            ),
        ],
      ),
      const CatalogLabel('League banner'),
      const LeagueBanner(totalXp: 940),
      const CatalogLabel('Rows: a player, and yours pinned'),
      BoardRow(entry: _sample.entries[3], scope: LeaderboardScope.week),
      YouRow(board: _sample, me: _sample.me!, hidden: true),
    ],
  );
}

class _Podium extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CatalogPaper(children: [Podium(board: _sample)]);
}
