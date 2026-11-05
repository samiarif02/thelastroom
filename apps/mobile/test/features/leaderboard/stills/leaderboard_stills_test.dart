import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/leaderboard/leaderboard_report.dart';
import 'package:the_last_room/features/leaderboard/board_rows.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_board.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_controller.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_screen.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_states.dart';
import 'package:the_last_room/features/settings/leaderboard_visibility_section.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../../../core/backend/fakes.dart';
import '../leaderboard_fixtures.dart';

/// The leaderboard (#72) in the real app at a 390 × 844 phone: the podium, the list with the
/// pinned row, all time, a new week, offline, no backend, hidden, loading, 2x text, the tab bar
/// and the Settings switch. With `WRITE_STILLS=1` each is saved at 2x in `.pr-screenshots/72/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const phone = Size(390, 844);

  Future<void> still(WidgetTester tester, String name) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & (phone * dpr),
        pixelRatio: pixelRatio / dpr,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/72/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  FakeBackend live() => FakeBackend()
    ..boards[LeaderboardScope.week] = weekBoard
    ..boards[LeaderboardScope.allTime] = allTimeBoard;

  testWidgets('the board, live', (tester) async {
    final rig = await bootBoard(tester, server: live(), size: phone);
    await rig.until(find.text(YouRow.headline(12)));
    await still(tester, '01-week-podium-league-banner');

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -900),
    );
    await still(tester, '02-week-list-your-row');

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 2000),
    );
    await tester.tap(find.text(LeaderboardScreen.allTab));
    await rig.until(find.text(YouRow.headline(8)));
    await still(tester, '03-all-time');
  });

  testWidgets('a new week, empty', (tester) async {
    final server = FakeBackend()..boards[LeaderboardScope.week] = emptyWeek;
    final rig = await bootBoard(tester, server: server, size: phone);
    await rig.until(find.text(BoardNotice.emptyTitle(LeaderboardScope.week)));
    await still(tester, '04-empty-week');
  });

  testWidgets('offline, with the last board', (tester) async {
    final cache = InMemoryLeaderboardCache(
      boards: {
        LeaderboardScope.week: Board(
          scope: LeaderboardScope.week,
          entries: [for (final r in weekBoard) BoardEntry.fromRemote(r)],
          fetchedAt: DateTime(2026, 11, 3, 14, 5),
        ),
      },
    );
    final rig = await bootBoard(
      tester,
      server: FakeBackend()..online = false,
      cache: cache,
      size: phone,
    );
    await rig.until(find.textContaining('as of'));
    await still(tester, '05-offline-as-of');
  });

  testWidgets('offline, nothing cached', (tester) async {
    final rig = await bootBoard(
      tester,
      server: FakeBackend()..online = false,
      size: phone,
    );
    await rig.until(find.text(BoardNotice.offlineTitle));
    await still(tester, '06-offline-nothing-cached');
  });

  testWidgets('no backend', (tester) async {
    final rig = await bootBoard(tester, backend: false, size: phone);
    await rig.until(find.text(BoardNotice.noBackendTitle));
    await still(tester, '07-no-backend');
  });

  testWidgets('hidden', (tester) async {
    final rig = await bootBoard(
      tester,
      server: live(),
      report: const LeaderboardReport(visible: false, totalXp: 940),
      size: phone,
    );
    await rig.until(find.text(YouRow.hiddenTag));
    await still(tester, '08-hidden');
  });

  testWidgets('loading', (tester) async {
    final rig = await bootBoard(
      tester,
      server: _Hanging()..boards[LeaderboardScope.week] = weekBoard,
      size: phone,
    );
    await rig.until(find.bySemanticsLabel(BoardSkeleton.label));
    await still(tester, '09-loading');
    // The fetch's time limit runs out, then the board says it can't be reached.
    await tester.pump(LeaderboardTiming.fetch);
    await rig.until(find.text(BoardNotice.offlineTitle));
  });

  testWidgets('2x text', (tester) async {
    final rig = await bootBoard(
      tester,
      server: live(),
      size: phone,
      textScale: 2,
    );
    await rig.until(find.text(YouRow.headline(12)));
    await still(tester, '10-2x-text');
  });

  testWidgets('the tab bar', (tester) async {
    final rig = await bootBoard(
      tester,
      backend: false,
      size: phone,
      location: Routes.tower(),
    );
    await rig.until(find.text(TowerScreen.leaderboardTab));
    await still(tester, '11-tab-bar');
  });

  testWidgets('the Settings switch', (tester) async {
    final rig = await bootBoard(
      tester,
      backend: false,
      size: phone,
      location: Routes.settings,
    );
    await rig.until(find.text(LeaderboardVisibilitySection.toggle));
    await tester.ensureVisible(find.text(LeaderboardVisibilitySection.toggle));
    await still(tester, '12-settings-switch');
  });
}

/// A server whose board never answers: the loading skeleton stays.
class _Hanging extends FakeBackend {
  @override
  Future<List<RemoteLeaderboardRow>> fetchLeaderboard(
    LeaderboardScope scope, {
    int limit = leaderboardSize,
  }) => Completer<List<RemoteLeaderboardRow>>().future;
}
