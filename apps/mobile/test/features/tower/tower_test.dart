import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/debrief/debrief_view.dart';
import 'package:the_last_room/features/intro/character_screen.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/tower/elevator.dart';
import 'package:the_last_room/features/tower/tower_rooms.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../mission/mission_harness.dart';
import 'played_attempt.dart';

void main() {
  group('rooms (pure)', () {
    test('a new player: Mission 1 is current, the rest locked', () {
      final rooms = towerRooms(missions, const []);
      expect(rooms.first.state, RoomState.current);
      expect(rooms.skip(1).map((r) => r.state), everyElement(RoomState.locked));
    });

    test('after Missions 1 and 2: both done with their best, 3 current', () {
      final m1 = missions[0];
      final m2 = missions[1];
      final weak = playedAttempt(m1, pick: 2);
      final strong = playedAttempt(m1, attempt: 2);
      final rooms = towerRooms(missions, [weak, strong, playedAttempt(m2)]);
      expect(rooms.map((r) => r.state).toList(), [
        RoomState.done,
        RoomState.done,
        RoomState.current,
        ...List.filled(4, RoomState.locked),
      ]);
      final best = weak.score.total > strong.score.total ? weak : strong;
      expect(rooms[0].best, best.score.total);
      expect(rooms[1].best, playedAttempt(m2).score.total);
    });

    test('any score unlocks the next room', () {
      final rooms = towerRooms(missions, [playedAttempt(missions[0], pick: 2)]);
      expect(rooms[1].state, RoomState.current);
    });
  });

  String roomLabel(Mission m, RoomState state, [int? best]) => switch (state) {
    RoomState.done =>
      'Mission ${m.number}, ${m.title}. Done, best score $best. Tap to play again.',
    RoomState.current => 'Mission ${m.number}, ${m.title}. Enter.',
    RoomState.locked => 'Mission ${m.number}, ${m.title}. Locked.',
  };

  testWidgets('the Tower shows done, current and locked after Missions 1–2', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    final a1 = playedAttempt(missions[0]);
    final a2 = playedAttempt(missions[1]);
    await rig.progress.recordAttempt(a1);
    await rig.progress.recordAttempt(a2);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    const m = missions;
    for (final (label, _) in [
      (roomLabel(m[0], RoomState.done, a1.score.total), 0),
      (roomLabel(m[1], RoomState.done, a2.score.total), 1),
      (roomLabel(m[2], RoomState.current), 2),
      (roomLabel(m[3], RoomState.locked), 3),
      (roomLabel(m[6], RoomState.locked), 6),
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    // Chapters 2 and 3 tease their titles; the last room is always in sight.
    expect(find.textContaining('UNDER PRESSURE'), findsOneWidget);
    expect(find.textContaining('THE FINAL ROUND'), findsOneWidget);
    expect(
      find.textContaining(chapters[1].missionTitles.first),
      findsOneWidget,
    );
    expect(find.textContaining(TowerScreen.lastRoom.toUpperCase()), findsOne);
    expect(rig.analytics.only(AnalyticsEvent.towerOpened).wire, {
      'missions_done': 2,
      'after_mission': false,
    });
    expect(rig.sounds.count('towerOpened'), 1);
  });

  testWidgets('finishing a mission lights its room and unlocks the next', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    final m1 = missions[0];
    // The path Mission 1's own end-to-end test plays.
    await rig.play(
      1,
      beats: const [
        'm01_open_role_fit',
        'm01_evidence_team_did',
        'm01_land_bring_habit',
      ],
      reply: 'm01_reply_part_led_it',
    );
    await rig.settleDossier();
    final total = rig.state(1).score!.total;
    final back = find.text(DebriefView.continueLabel.toUpperCase());
    await tester.ensureVisible(back);
    await tester.tap(back);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(seconds: 1));
    expect(
      find.bySemanticsLabel(roomLabel(m1, RoomState.done, total)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(roomLabel(missions[1], RoomState.current)),
      findsOneWidget,
    );
    expect(find.text(TowerScreen.litNotice(m1)), findsOneWidget);
    expect(
      rig.analytics.only(AnalyticsEvent.towerOpened).wire['after_mission'],
      isTrue,
    );
  });

  testWidgets('entering a room: the elevator, then the mission', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.progress.recordAttempt(playedAttempt(missions[0]));
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await tester.tap(
      find.bySemanticsLabel(roomLabel(missions[1], RoomState.current)),
    );
    await tester.pump();
    expect(find.byType(Elevator), findsOneWidget);
    expect(rig.sounds.count('roomEntered'), 1);
    expect(rig.sounds.count('elevator'), 1);
    expect(rig.analytics.only(AnalyticsEvent.roomEntered).wire, {
      'mission_id': missions[1].id,
      'replay': false,
    });
    await rig.until(find.byType(MissionPlayer));
    expect(rig.state(2).mission, missions[1]);
  });

  testWidgets('a brand-new player meets the practice CV before Mission 1', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await tester.tap(
      find.bySemanticsLabel(roomLabel(missions[0], RoomState.current)),
    );
    await rig.until(find.byType(CharacterScreen));
  });

  testWidgets('a locked room says what opens it, and plays its sound', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    final locked = find.bySemanticsLabel(
      roomLabel(missions[2], RoomState.locked),
    );
    await tester.ensureVisible(locked);
    await tester.tap(locked);
    await tester.pump();
    expect(find.text(TowerScreen.lockedNotice(missions[1])), findsOneWidget);
    expect(rig.sounds.count('lockedRoomTapped'), 1);
    expect(find.byType(Elevator), findsNothing);
    await rig.run(const Duration(seconds: 4));
    expect(find.text(TowerScreen.lockedNotice(missions[1])), findsNothing);
  });

  testWidgets('the file opens from the Tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await tester.tap(find.text(TowerScreen.progress.toUpperCase()));
    await rig.until(find.byType(ProgressScreen));
    expect(rig.analytics.only(AnalyticsEvent.progressReportViewed).wire, {
      'source': 'tower',
    });
  });

  for (final (scale, still) in [(2.0, false), (1.0, true), (2.0, true)]) {
    testWidgets('the Tower survives ${scale}x text, reduced motion: $still', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.progress.recordAttempt(playedAttempt(missions[0]));
      await rig.boot(
        Routes.tower(lit: 1),
        textScale: scale,
        reduceMotion: still,
      );
      await rig.until(find.byType(TowerScreen));
      await rig.run(const Duration(seconds: 2));
      final room = find.bySemanticsLabel(
        roomLabel(missions[1], RoomState.current),
      );
      await tester.ensureVisible(room);
      await tester.pump();
      await tester.tap(room);
      await rig.until(find.byType(MissionPlayer));
    });
  }

  testWidgets('the room windows hold a 44 dp target', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    final room = find.bySemanticsLabel(
      roomLabel(missions[0], RoomState.current),
    );
    expect(tester.getSize(room).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(room).width, greaterThan(200));
  });
}
