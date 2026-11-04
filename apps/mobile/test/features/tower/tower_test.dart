import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/debrief/debrief_view.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/tower/elevator.dart';
import 'package:the_last_room/features/tower/floor_sheet.dart';
import 'package:the_last_room/features/tower/northstar_tower.dart';
import 'package:the_last_room/features/tower/tower_door.dart';
import 'package:the_last_room/features/tower/tower_extras.dart';
import 'package:the_last_room/features/tower/tower_hero.dart';
import 'package:the_last_room/features/tower/tower_rooms.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart'
    show FloatingTabBar;

import '../mission/mission_harness.dart';
import 'played_attempt.dart';

/// Scrolls the home to its end, where the whole tower is on screen (rooms off screen have no
/// semantics to find).
Future<void> toTheTower(WidgetTester tester) async {
  await tester.drag(
    find.byType(SingleChildScrollView).first,
    const Offset(0, -3000),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
        ...List.filled(missions.length - 3, RoomState.locked),
      ]);
      final best = weak.score.total > strong.score.total ? weak : strong;
      expect(rooms[0].best, best.score.total);
      expect(rooms[1].best, playedAttempt(m2).score.total);
    });

    test('any score unlocks the next room', () {
      final rooms = towerRooms(missions, [playedAttempt(missions[0], pick: 2)]);
      expect(rooms[1].state, RoomState.current);
    });

    test('stars: one for finishing, two from 60, three from 80', () {
      expect([0, 59, 60, 79, 80, 100].map(starsFor), [1, 1, 2, 2, 3, 3]);
    });

    test('the hero offers the current room, then the weakest to beat', () {
      expect(heroRoom(towerRooms(missions, const []))!.mission, missions[0]);
      // Every Chapter 1 mission played (the helper plays choices missions), one weaker.
      final chapterOne = [
        for (final m in missions)
          if (m.chapter == 1) m,
      ];
      final all = [
        for (var i = 0; i < chapterOne.length; i++)
          playedAttempt(chapterOne[i], pick: i == 3 ? 2 : 0),
      ];
      final rooms = towerRooms(chapterOne, all);
      final weakest = rooms.reduce((a, b) => a.best! <= b.best! ? a : b);
      expect(heroRoom(rooms), weakest);
    });
  });

  String roomLabel(Mission m, RoomState state, [int? best]) => switch (state) {
    RoomState.done =>
      'Room ${m.number}, ${m.title}, lit, best $best. Play again.',
    RoomState.current => 'Room ${m.number}, ${m.title}. Play.',
    RoomState.locked =>
      'Room ${m.number}, ${m.title}, locked: opens after room ${m.number - 1}.',
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
    await toTheTower(tester);
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
    // Floors 2 and 3 are on the facade from day one; the top room is lit: Sam waits.
    expect(find.text(NorthstarTower.floorLine(chapters[1])), findsOneWidget);
    expect(find.text(NorthstarTower.floorLine(chapters[2])), findsOneWidget);
    expect(find.text(NorthstarTower.samWaits), findsOneWidget);
    expect(find.textContaining(RecallRoomCardView.title), findsWidgets);
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
    final back = find.text(DebriefView.continueLabel);
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
    await toTheTower(tester);
    final room = find.bySemanticsLabel(
      roomLabel(missions[1], RoomState.current),
    );
    await tester.ensureVisible(room);
    await tester.pump();
    await tester.tap(room);
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

  testWidgets('one tap from a new player\'s tower into Mission 1', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    final play = find.bySemanticsLabel(
      TowerHero.playLabel(towerRooms(missions, const []).first),
    );
    // On the first screen, above the tab bar, no scrolling.
    expect(
      tester.getRect(play).bottom,
      lessThan(tester.getRect(find.byType(FloatingTabBar)).top),
    );
    await tester.tap(play);
    await rig.until(find.byType(MissionPlayer));
    expect(rig.state(1).mission, missions[0]);
  });

  testWidgets('the tower stands floor 1 at the bottom, rooms 1 → 7 left to '
      'right', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    final floorTops = <double>[
      for (final c in chapters)
        tester.getTopLeft(find.text(NorthstarTower.floorLine(c))).dy,
    ];
    final byHeight = <double>[...floorTops]..sort((a, b) => b.compareTo(a));
    expect(floorTops, orderedEquals(byHeight));
    final rooms = towerRooms(missions, const []);
    final firstFloor = [
      for (final r in rooms.where((r) => r.mission.chapter == 1))
        tester
            .getTopLeft(find.bySemanticsLabel(roomLabel(r.mission, r.state)))
            .dx,
    ];
    expect(firstFloor, orderedEquals([...firstFloor]..sort()));
  });

  testWidgets('the tab bar stays over the tower as it scrolls', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    final tabs = find.byType(FloatingTabBar);
    final before = tester.getRect(tabs);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await rig.run(const Duration(milliseconds: 300));
    expect(tester.getRect(tabs), before);
  });

  testWidgets('a locked door opens its floor, which says what opens it', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    final locked = find.bySemanticsLabel(
      roomLabel(missions[2], RoomState.locked),
    );
    await tester.ensureVisible(locked);
    await tester.tap(locked);
    await rig.run(const Duration(milliseconds: 600));
    expect(find.byType(FloorSheet), findsOneWidget);
    expect(find.byType(Elevator), findsNothing);
    expect(
      find.descendant(
        of: find.byType(FloorSheet),
        matching: find.bySemanticsLabel(
          'Room ${missions[2].number}, ${missions[2].title}, locked',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the doors: lit with a check, the next one ajar with a play cue, '
      'the rest closed; floors ahead locked', (tester) async {
    final rig = MissionRig(tester);
    await rig.progress.recordAttempt(playedAttempt(missions[0]));
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    final doors = tester.widgetList<TowerDoor>(find.byType(TowerDoor)).toList();
    expect(doors, hasLength(missions.length));
    // The facade reads top floor first: floor 3, floor 2, then floor 1's rooms 1 → 7.
    final floor1 = doors.skip(14).toList();
    expect(floor1.first.state, DoorState.done);
    expect(floor1[1].state, DoorState.next);
    expect(floor1[2].state, DoorState.closed);
    expect(doors.where((d) => d.state == DoorState.locked), hasLength(13));
    expect(doors[6].state, DoorState.waiting);
    expect(find.byType(PlayCue), findsOneWidget);
    // Every door is at least a thumb tall, and says what a tap does.
    expect(
      find.bySemanticsLabel(roomLabel(missions[1], RoomState.current)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Room 8, ${missions[7].title}, locked: opens after floor 1.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a locked floor opens to show what is ahead', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    final floor2 = chapters[1];
    await tester.ensureVisible(find.text(NorthstarTower.floorLine(floor2)));
    await tester.pump();
    await tester.tap(find.text(NorthstarTower.floorLine(floor2)));
    await rig.run(const Duration(milliseconds: 600));
    expect(find.byType(FloorSheet), findsOneWidget);
    expect(find.text(floor2.title), findsOneWidget);
    final lastOfFloor1 = missions.lastWhere((m) => m.chapter == 1);
    expect(find.text(FloorSheet.opensWhen(lastOfFloor1)), findsOneWidget);
    for (final m in missions.where((m) => m.chapter == 2)) {
      expect(
        find.descendant(
          of: find.byType(FloorSheet),
          matching: find.bySemanticsLabel(
            'Room ${m.number}, ${m.title}, locked',
          ),
        ),
        findsOneWidget,
      );
    }
    expect(rig.analytics.only(AnalyticsEvent.floorPreviewed).wire, {
      'chapter': 2,
      'open': false,
    });
  });

  testWidgets('an open floor\'s sheet takes you into its next room', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    await tester.tap(find.text(NorthstarTower.floorLine(chapters.first)));
    await rig.run(const Duration(milliseconds: 600));
    final first = missions.first;
    final row = find.descendant(
      of: find.byType(FloorSheet),
      matching: find.bySemanticsLabel(
        'Room ${first.number}, ${first.title}, up next',
      ),
    );
    await tester.ensureVisible(row);
    await rig.run(const Duration(milliseconds: 300));
    await tester.tap(row);
    await rig.until(find.byType(MissionPlayer));
    expect(rig.state(1).mission, first);
  });

  testWidgets('the file opens from the Tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingTabBar),
        matching: find.text(TowerScreen.progress),
      ),
    );
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
      await toTheTower(tester);
      final room = find.bySemanticsLabel(
        roomLabel(missions[1], RoomState.current),
      );
      await tester.ensureVisible(room);
      await tester.pump();
      await tester.tap(room);
      await rig.until(find.byType(MissionPlayer));
    });
  }

  testWidgets('the rooms hold a 44 dp target', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower());
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    final room = find.bySemanticsLabel(
      roomLabel(missions[0], RoomState.current),
    );
    // A window is a column of the facade: as tall as a thumb, as wide as a seventh of it.
    expect(tester.getSize(room).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(room).width, greaterThanOrEqualTo(40));
  });
}
