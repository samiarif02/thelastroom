import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/leaderboard/leaderboard_report.dart';
import 'package:the_last_room/features/leaderboard/leaderboard_board.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/progression/progression_store.dart';

import '../../core/backend/fakes.dart';
import '../mission/mission_harness.dart';

/// A board row as the server returns it.
RemoteLeaderboardRow row(
  int rank,
  String? name,
  String tag, {
  required int week,
  required int total,
  int streak = 0,
  bool me = false,
}) => RemoteLeaderboardRow(
  rank: rank,
  displayName: name,
  tag: tag,
  totalXp: total,
  weekXp: week,
  streakWeeks: streak,
  isMe: me,
);

/// This week: eleven players ahead of the caller (Sami, #12, 40 XP behind Ali).
final List<RemoteLeaderboardRow> weekBoard = [
  row(1, 'Maya', '1204', week: 410, total: 1580, streak: 5),
  row(2, 'Jon', '7731', week: 365, total: 2640, streak: 3),
  row(3, 'Noor', '0458', week: 300, total: 3810, streak: 8),
  row(4, null, '3316', week: 260, total: 720, streak: 1),
  row(5, 'Theo', '9902', week: 240, total: 460),
  row(6, 'Ines', '5127', week: 220, total: 1310, streak: 2),
  row(7, 'Kofi', '6640', week: 205, total: 980, streak: 1),
  row(8, 'Lea', '2283', week: 190, total: 2210),
  row(9, 'Ravi', '8815', week: 175, total: 640, streak: 2),
  row(10, 'Maya', '4470', week: 160, total: 300),
  row(11, 'Ali', '4821', week: 139, total: 1150, streak: 1),
  row(12, 'Sami', '3920', week: 100, total: 940, streak: 2, me: true),
];

final List<RemoteLeaderboardRow> allTimeBoard = [
  row(1, 'Noor', '0458', week: 300, total: 3810, streak: 8),
  row(2, 'Jon', '7731', week: 365, total: 2640, streak: 3),
  row(3, 'Lea', '2283', week: 190, total: 2210),
  row(4, 'Maya', '1204', week: 410, total: 1580, streak: 5),
  row(5, 'Ines', '5127', week: 220, total: 1310, streak: 2),
  row(6, 'Ali', '4821', week: 139, total: 1150, streak: 1),
  row(7, 'Kofi', '6640', week: 205, total: 980, streak: 1),
  row(8, 'Sami', '3920', week: 100, total: 940, streak: 2, me: true),
];

/// A new week: only the caller is on it, with nothing yet.
final List<RemoteLeaderboardRow> emptyWeek = [
  row(1, 'Sami', '3920', week: 0, total: 940, me: true),
];

/// Pins the progression clock to Wednesday 4 November 2026, 10:00 UTC.
final DateTime boardNow = DateTime.utc(2026, 11, 4, 10);

/// The app at the leaderboard with a fake server: keys on and a signed-in guest unless
/// [backend] is false. [report] seeds "Show me on the leaderboard".
Future<MissionRig> bootBoard(
  WidgetTester tester, {
  FakeBackend? server,
  bool backend = true,
  bool signedIn = true,
  InMemoryLeaderboardCache? cache,
  LeaderboardReport report = const LeaderboardReport(totalXp: 940),
  int recallXp = 940,
  Size size = MissionRig.phone,
  double textScale = 1,
  bool reduceMotion = true,
  String location = Routes.leaderboard,
}) async {
  final rig = MissionRig(tester);
  rig.overrides.addAll([
    if (backend) envProvider.overrideWithValue(keyedEnv),
    backendProvider.overrideWithValue(server ?? FakeBackend()),
    leaderboardCacheProvider.overrideWithValue(
      cache ?? InMemoryLeaderboardCache(),
    ),
    leaderboardReportStoreProvider.overrideWithValue(
      InMemoryLeaderboardReportStore(report),
    ),
    // The banner's XP: Recall XP alone, so no attempts are needed.
    progressionStoreProvider.overrideWithValue(
      InMemoryProgressionStore(ProgressionRecord(recallXp: recallXp)),
    ),
    progressionClockProvider.overrideWithValue(() => boardNow),
    // No device database here: nothing to flush before the fetch.
    syncWorkerProvider.overrideWithValue(null),
  ]);
  await rig.boot(
    location,
    size: size,
    textScale: textScale,
    reduceMotion: reduceMotion,
  );
  if (signedIn && backend) {
    rig.container
        .read(sessionProvider.notifier)
        .signedIn(const GuestSession(userId: FakeBackend.guestId));
  }
  await tester.pump();
  return rig;
}
