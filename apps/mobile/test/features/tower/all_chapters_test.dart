import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/tower/all_chapters_screen.dart';
import 'package:the_last_room/features/tower/chapter_section.dart';
import 'package:the_last_room/features/tower/elevator.dart';
import 'package:the_last_room/features/tower/tower_door.dart';
import 'package:the_last_room/features/tower/tower_rooms.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../mission/mission_harness.dart';

/// Scrolls the tower to its end, where the link under it is.
Future<void> toTheTower(WidgetTester tester) async {
  await tester.drag(
    find.byType(SingleChildScrollView).first,
    const Offset(0, -3000),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A row's label, from the tower's own rooms: the list must say what the tower says.
String rowLabel(TowerRoom r, List<TowerRoom> rooms) {
  final m = r.mission;
  final floorOpen = floorIsOpen(
    rooms.where((x) => x.mission.chapter == m.chapter),
  );
  final mode = m.answerMode == AnswerMode.voice ? 'voice' : 'choices';
  final tail = switch (r.state) {
    RoomState.done => 'played, best ${r.best}. Play again',
    RoomState.current => 'up next. Play',
    RoomState.locked =>
      'locked: opens after ${opensAfter(m, floorOpen: floorOpen)}',
  };
  return 'Room ${m.number}, ${m.title}, with ${m.lead.name}, $mode, $tail.';
}

Finder header(Chapter c) => find.bySemanticsLabel(
  RegExp('^${RegExp.escape(ChapterSection.title(c))},'),
);

Future<void> openAll(WidgetTester tester, MissionRig rig) async {
  for (final c in chapters) {
    final rows = find.bySemanticsLabel(
      RegExp(
        '^Room ${missions.firstWhere((m) => m.chapter == c.number).number},',
      ),
    );
    if (rows.evaluate().isNotEmpty) continue;
    await tester.ensureVisible(header(c));
    await tester.tap(header(c));
    await rig.run(const Duration(milliseconds: 700));
  }
}

Future<void> settle(MissionRig rig) async {
  await rig.until(find.byType(AllChaptersScreen));
  await rig.until(find.byType(ChapterSection));
  await rig.run(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('"View all chapters" under the tower opens every floor', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await toTheTower(tester);
    final link = find.bySemanticsLabel(
      RegExp('^${AllChaptersLink.label}, 21 rooms'),
    );
    expect(link, findsOneWidget);
    await tester.ensureVisible(link);
    await tester.tap(link);
    await settle(rig);
    expect(find.byType(ChapterSection), findsNWidgets(chapters.length));
    for (final c in chapters) {
      expect(find.text(ChapterSection.title(c)), findsOneWidget);
    }
    expect(rig.analytics.only(AnalyticsEvent.allChaptersOpened).wire, {
      'missions_done': 0,
      'chapter': 1,
    });
  });

  testWidgets('a new player: floor 1 open with room 1 up next, the rest '
      'locked by the tower\'s rules; all 21 rooms listed', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.chapters, reduceMotion: true);
    await settle(rig);
    final rooms = towerRooms(missions, const []);
    // Only the current floor is open at first.
    expect(find.bySemanticsLabel(rowLabel(rooms[0], rooms)), findsOneWidget);
    expect(find.bySemanticsLabel(rowLabel(rooms[7], rooms)), findsNothing);
    await openAll(tester, rig);
    for (final r in rooms) {
      final row = find.bySemanticsLabel(rowLabel(r, rooms));
      await tester.ensureVisible(row);
      expect(row, findsOneWidget, reason: rowLabel(r, rooms));
    }
    expect(
      find.bySemanticsLabel(
        'Room 9, ${missions[8].title}, with ${missions[8].lead.name}, '
        '${missions[8].answerMode == AnswerMode.voice ? 'voice' : 'choices'}, '
        'locked: opens after floor 1.',
      ),
      findsOneWidget,
    );
    // The doors: one ajar, the top room lit with Sam, every other one shut.
    final doors = tester
        .widgetList<TowerDoor>(find.byType(TowerDoor))
        .where((d) => d.width == 28);
    expect(doors, hasLength(missions.length));
    expect(doors.where((d) => d.state == DoorState.next), hasLength(1));
    expect(doors.where((d) => d.state == DoorState.waiting), hasLength(1));
    expect(doors.where((d) => d.state == DoorState.done), isEmpty);
  });

  testWidgets('mid-game: the rows match the tower, scores on played rooms', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(10);
    await rig.boot(Routes.chapters, reduceMotion: true);
    await settle(rig);
    final rooms = towerRooms(missions, await rig.progress.attempts());
    expect(rooms[9].state, RoomState.current);
    // Floor 2 holds the room to play, so it's the one open.
    expect(find.bySemanticsLabel(rowLabel(rooms[9], rooms)), findsOneWidget);
    await openAll(tester, rig);
    for (final r in rooms) {
      final row = find.bySemanticsLabel(rowLabel(r, rooms));
      await tester.ensureVisible(row);
      expect(row, findsOneWidget, reason: rowLabel(r, rooms));
    }
    expect(find.text('${rooms[0].best}'), findsWidgets);
    expect(rig.analytics.only(AnalyticsEvent.allChaptersOpened).wire, {
      'missions_done': 9,
      'chapter': 2,
    });
  });

  testWidgets('all done: every room played, the top floor open', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(missions.length + 1);
    await rig.boot(Routes.chapters, reduceMotion: true, textScale: 2);
    await settle(rig);
    final rooms = towerRooms(missions, await rig.progress.attempts());
    expect(rooms.every((r) => r.state == RoomState.done), isTrue);
    expect(find.bySemanticsLabel(rowLabel(rooms.last, rooms)), findsOneWidget);
    expect(find.text(ChapterSection.allLit), findsNWidgets(chapters.length));
  });

  testWidgets('the room up next starts through the lift, like its door', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.chapters);
    await settle(rig);
    final rooms = towerRooms(missions, const []);
    await tester.tap(find.bySemanticsLabel(rowLabel(rooms[0], rooms)));
    await tester.pump();
    expect(find.byType(Elevator), findsOneWidget);
    expect(rig.sounds.count('roomEntered'), 1);
    expect(rig.analytics.only(AnalyticsEvent.roomEntered).wire, {
      'mission_id': missions[0].id,
      'replay': false,
    });
    await rig.until(find.byType(MissionPlayer));
    expect(rig.state(1).mission, missions[0]);
  });

  testWidgets('a played room replays from its row', (tester) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(3);
    await rig.boot(Routes.chapters, reduceMotion: true);
    await settle(rig);
    final rooms = towerRooms(missions, await rig.progress.attempts());
    await tester.tap(find.bySemanticsLabel(rowLabel(rooms[0], rooms)));
    await rig.until(find.byType(MissionPlayer));
    expect(rig.state(1).mission, missions[0]);
    expect(
      rig.analytics.only(AnalyticsEvent.roomEntered).wire['replay'],
      isTrue,
    );
  });

  testWidgets('a locked room says what opens it and goes nowhere', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.chapters, reduceMotion: true);
    await settle(rig);
    final rooms = towerRooms(missions, const []);
    final locked = find.bySemanticsLabel(rowLabel(rooms[3], rooms));
    await tester.ensureVisible(locked);
    await tester.tap(locked);
    await rig.run(const Duration(milliseconds: 400));
    expect(find.text(lockedNote(missions[3], floorOpen: true)), findsOneWidget);
    expect(
      lockedNote(missions[3], floorOpen: true),
      startsWith('Opens after room 3'),
    );
    expect(find.byType(Elevator), findsNothing);
    expect(rig.sounds.count('lockedRoomTapped'), 1);
    expect(find.byType(AllChaptersScreen), findsOneWidget);
    expect(find.byType(MissionPlayer), findsNothing);
    // A room on a floor not open yet names the floor.
    expect(
      lockedNote(missions[8], floorOpen: false),
      startsWith('Opens after floor 1'),
    );
  });

  testWidgets('a floor folds and unfolds on its header', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.chapters);
    await settle(rig);
    final rooms = towerRooms(missions, const []);
    final room8 = find.bySemanticsLabel(rowLabel(rooms[7], rooms));
    expect(room8, findsNothing);
    await tester.ensureVisible(header(chapters[1]));
    await tester.tap(header(chapters[1]));
    await rig.run(const Duration(milliseconds: 800));
    expect(room8, findsOneWidget);
    await tester.ensureVisible(header(chapters[1]));
    await tester.tap(header(chapters[1]));
    await rig.run(const Duration(milliseconds: 800));
    expect(room8, findsNothing);
    // Floor 1 folds too.
    final room1 = find.bySemanticsLabel(rowLabel(rooms[0], rooms));
    expect(room1, findsOneWidget);
    await tester.ensureVisible(header(chapters[0]));
    await tester.tap(header(chapters[0]));
    await rig.run(const Duration(milliseconds: 800));
    expect(room1, findsNothing);
  });

  for (final (scale, still) in [(2.0, false), (2.0, true)]) {
    testWidgets('survives ${scale}x text, reduced motion: $still', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.unlockThrough(4);
      await rig.boot(Routes.chapters, textScale: scale, reduceMotion: still);
      await settle(rig);
      await openAll(tester, rig);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -6000),
      );
      await rig.run(const Duration(milliseconds: 400));
    });
  }

  testWidgets('back returns to the tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.chapters, reduceMotion: true);
    await settle(rig);
    await tester.tap(find.bySemanticsLabel(AllChaptersScreen.back));
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 400));
    expect(find.byType(AllChaptersScreen), findsNothing);
  });
}
