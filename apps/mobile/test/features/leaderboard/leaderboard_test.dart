import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/leaderboard/leaderboard_report.dart';
import 'package:the_last_room/features/leaderboard/board_rows.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_board.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_screen.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_states.dart';
import 'package:the_last_room/features/leaderboard/league_banner.dart';
import 'package:the_last_room/features/settings/leaderboard_visibility_section.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../../core/backend/fakes.dart';
import 'leaderboard_fixtures.dart';

Board board(List<RemoteLeaderboardRow> rows, [LeaderboardScope? scope]) =>
    Board(
      scope: scope ?? LeaderboardScope.week,
      entries: [for (final r in rows) BoardEntry.fromRemote(r)],
      fetchedAt: boardNow,
    );

void main() {
  group('names', () {
    test('a first name with its tag; no name is "Candidate" and the tag', () {
      final b = board(weekBoard);
      expect(b.entries.first.label, 'Maya · #1204');
      expect(b.entries[3].label, 'Candidate 3316');
    });

    test('two Mayas stay apart by their tags', () {
      final mayas = board(weekBoard).entries
          .where((e) => e.name == 'Maya')
          .map((e) => e.label);
      expect(mayas, ['Maya · #1204', 'Maya · #4470']);
    });

    test('a name typed with a full stop is shown without it', () {
      final e = BoardEntry.fromRemote(
        row(1, 'Ali.', '4821', week: 1, total: 1),
      );
      expect(e.label, 'Ali · #4821');
    });
  });

  group('the board', () {
    test('the podium is the first three; the rest follow, the caller last', () {
      final b = board(weekBoard);
      expect(b.podium.map((e) => e.rank), [1, 2, 3]);
      expect(b.rest.first.rank, 4);
      expect(b.rest.last.isMe, isTrue);
      expect(b.me!.rank, 12);
    });

    test('"40 XP to pass Ali": strictly more than the player above', () {
      final b = board(weekBoard);
      expect(YouRow.climbLine(b, b.me!), '40 XP to pass Ali');
    });

    test('at the top: hold it; with nothing yet: play a room', () {
      final top = board([
        row(1, 'Noor', '0458', week: 300, total: 3810, me: true),
      ]);
      expect(YouRow.climbLine(top, top.me!), YouRow.topLine);
      final empty = board(emptyWeek);
      expect(empty.isEmpty, isTrue);
      expect(YouRow.climbLine(empty, empty.me!), YouRow.startLine);
    });

    test('outside the top N the target is the last one listed', () {
      final b = board([
        row(1, 'Maya', '1204', week: 410, total: 1580),
        row(57, 'Sami', '3920', week: 100, total: 940, me: true),
      ]);
      expect(YouRow.climbLine(b, b.me!), '311 XP to pass #1');
    });

    test('a cached board reads back the same', () {
      final b = board(weekBoard);
      final back = Board.fromJson(b.toJson())!;
      expect(back.fetchedAt, b.fetchedAt);
      expect(
        [for (final e in back.entries) e.toJson()],
        [for (final e in b.entries) e.toJson()],
      );
      expect(Board.fromJson({'v': 0}), isNull);
    });
  });

  group('the screen', () {
    testWidgets('no backend: a calm explainer, the league still shown', (
      tester,
    ) async {
      final rig = await bootBoard(tester, backend: false);
      await rig.until(find.text(BoardNotice.noBackendTitle));
      expect(find.text('Silver league'), findsOneWidget);
      expect(find.text(LeagueBanner.toNext(260, League.gold)), findsOneWidget);
      expect(
        rig.analytics.events.map((e) => e.event),
        contains(AnalyticsEvent.leaderboardOpened),
      );
    });

    testWidgets('live: the podium, the list and the pinned row', (
      tester,
    ) async {
      final server = FakeBackend()
        ..boards[LeaderboardScope.week] = weekBoard
        ..boards[LeaderboardScope.allTime] = allTimeBoard;
      final rig = await bootBoard(tester, server: server);
      await rig.until(find.text(YouRow.headline(12)));
      expect(find.text('40 XP to pass Ali'), findsOneWidget);
      expect(find.text('Maya'), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('^Rank 4, Candidate 3316')),
        findsOneWidget,
      );
      expect(server.boardFetches, [LeaderboardScope.week]);

      await tester.tap(find.text(LeaderboardScreen.allTab));
      await rig.until(find.text(YouRow.headline(8)));
      expect(server.boardFetches, [
        LeaderboardScope.week,
        LeaderboardScope.allTime,
      ]);
      final opened = [
        for (final e in rig.analytics.events)
          if (e.event == AnalyticsEvent.leaderboardOpened) e.wire['tab'],
      ];
      expect(opened, ['week', 'allTime']);
    });

    testWidgets('offline: the last board, "as of" when it was fetched', (
      tester,
    ) async {
      final cache = InMemoryLeaderboardCache(
        boards: {LeaderboardScope.week: board(weekBoard)},
      );
      final server = FakeBackend()..online = false;
      final rig = await bootBoard(tester, server: server, cache: cache);
      await rig.until(find.textContaining('as of'));
      expect(find.text(YouRow.headline(12)), findsOneWidget);
    });

    testWidgets('offline with nothing cached: try again', (tester) async {
      final server = FakeBackend()..online = false;
      final rig = await bootBoard(tester, server: server);
      await rig.until(find.text(BoardNotice.offlineTitle));
      server
        ..online = true
        ..boards[LeaderboardScope.week] = weekBoard;
      await tester.ensureVisible(find.text(BoardNotice.retry));
      await tester.tap(find.text(BoardNotice.retry));
      await rig.until(find.text(YouRow.headline(12)));
    });

    testWidgets('a new week: be the first on the board', (tester) async {
      final server = FakeBackend()..boards[LeaderboardScope.week] = emptyWeek;
      final rig = await bootBoard(tester, server: server);
      await rig.until(find.text(BoardNotice.emptyTitle(LeaderboardScope.week)));
      expect(find.text(BoardNotice.play), findsOneWidget);
      expect(find.text(YouRow.startLine), findsOneWidget);
    });

    testWidgets('hidden: "You\'re hidden" on the pinned row', (tester) async {
      final server = FakeBackend()..boards[LeaderboardScope.week] = weekBoard;
      final rig = await bootBoard(
        tester,
        server: server,
        report: const LeaderboardReport(visible: false, totalXp: 940),
      );
      await rig.until(find.text(YouRow.hiddenTag));
    });

    testWidgets('2x text: nothing overflows', (tester) async {
      final server = FakeBackend()..boards[LeaderboardScope.week] = weekBoard;
      final rig = await bootBoard(tester, server: server, textScale: 2);
      await rig.until(find.text(YouRow.headline(12)));
      await rig.run(const Duration(seconds: 1));
    });

    testWidgets('the count-up starts from the XP seen last time', (
      tester,
    ) async {
      final cache = InMemoryLeaderboardCache()
        ..seenScores[LeaderboardScope.week] = 60;
      final server = FakeBackend()..boards[LeaderboardScope.week] = weekBoard;
      final rig = await bootBoard(
        tester,
        server: server,
        cache: cache,
        reduceMotion: false,
      );
      await rig.until(find.text(YouRow.headline(12)));
      await rig.run(const Duration(seconds: 2));
      expect(find.text('100 XP'), findsWidgets);
      expect(cache.seenScores[LeaderboardScope.week], 100);
    });
  });
  group('Settings', () {
    testWidgets('"Show me on the leaderboard": on by default, off is tracked', (
      tester,
    ) async {
      final rig = await bootBoard(tester, location: Routes.settings);
      await rig.until(find.text(LeaderboardVisibilitySection.toggle));
      expect(find.text(LeaderboardVisibilitySection.onLine), findsOneWidget);
      await tester.ensureVisible(
        find.text(LeaderboardVisibilitySection.toggle),
      );
      await tester.tap(find.text(LeaderboardVisibilitySection.toggle));
      await rig.until(find.text(LeaderboardVisibilitySection.offLine));
      final store = rig.container.read(leaderboardReportStoreProvider);
      expect((await store.load()).visible, isFalse);
      final changed = [
        for (final e in rig.analytics.events)
          if (e.event == AnalyticsEvent.leaderboardVisibilityChanged) e.wire,
      ];
      expect(changed, [
        {'visible': false},
      ]);
    });
  });

  testWidgets('the tower\'s fourth tab opens the leaderboard', (tester) async {
    final rig = await bootBoard(
      tester,
      backend: false,
      location: Routes.tower(),
    );
    await rig.until(find.text(TowerScreen.leaderboardTab));
    await tester.tap(find.text(TowerScreen.leaderboardTab));
    await rig.until(find.text(BoardNotice.noBackendTitle));
  });
}
