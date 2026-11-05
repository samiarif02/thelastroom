import 'dart:io';
import 'dart:ui' as ui;

import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/room_intro.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/features/voice/voice_player.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';
import 'package:the_last_room/ui/subtitle/typewriter_subtitle.dart';

import '../mission_harness.dart';

/// Issue 76: the room's intro replaced the lift ride (a floor indicator counting up on
/// full-screen floor-coloured doors) and the floor-coloured title card that moved on by
/// itself. It names the room, says what it trains and how it's answered, and waits for
/// "Start the interview". With `WRITE_STILLS=1` each state is saved at 2x in
/// `.pr-screenshots/76/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const phone = Size(390, 844);
  final room5 = missions.firstWhere((m) => m.number == 5);
  final voiceRoom = missions.firstWhere(
    (m) => m.answerMode == AnswerMode.voice,
  );

  Future<void> still(
    WidgetTester tester,
    String name, {
    bool settle = true,
  }) async {
    for (var i = 0; i < (settle ? 12 : 0); i++) {
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
      File('../../.pr-screenshots/76/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<MissionRig> open(
    WidgetTester tester,
    Mission m, {
    double textScale = 1,
    bool reduceMotion = false,
    bool calm = false,
  }) async {
    final rig = MissionRig(
      tester,
      profile: onboardedPlayer.copyWith(calmMode: calm),
    );
    await rig.unlockThrough(m.number);
    await rig.boot(
      Routes.mission(m.number),
      size: phone,
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    await rig.until(find.text(RoomIntro.start));
    return rig;
  }

  testWidgets('a door on the tower opens straight onto the intro', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(room5.number);
    await rig.boot(Routes.tower(), size: phone);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(seconds: 2));
    final start = find.textContaining('Start room ${room5.number}');
    await rig.until(start);
    await tester.ensureVisible(start.first);
    await tester.pump();
    await tester.tap(start.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await still(tester, '00d-after-door-opening', settle: false);
    expect(rig.sounds.count('elevator'), 0);
    await rig.until(find.text(RoomIntro.start));
    expect(rig.analytics.count(AnalyticsEvent.roomEntered), 1);
    expect(rig.analytics.count(AnalyticsEvent.missionStarted), 0);
  });

  testWidgets('the intro names the room and what it trains', (tester) async {
    await open(tester, room5);
    expect(find.text(RoomIntro.heading(room5)), findsOneWidget);
    expect(find.text('Room 5 · ${room5.title}'), findsOneWidget);
    expect(find.text(RoomIntro.withWho(room5.lead)), findsOneWidget);
    expect(find.text(room5.practises!), findsOneWidget);
    expect(find.text(RoomIntro.choices), findsOneWidget);
    expect(find.text(RoomIntro.beats(room5.beats.length)), findsOneWidget);
    expect(
      find.text(
        room5.timed
            ? RoomIntro.timed(const Duration(seconds: 60))
            : RoomIntro.untimed,
      ),
      findsOneWidget,
    );
    expect(find.text(RoomIntro.ready(room5.lead)), findsOneWidget);
    expect(find.bySemanticsLabel(RoomIntro.back), findsOneWidget);
    await still(tester, '01-after-intro-room-5');
  });

  testWidgets('nothing starts by itself, and no numbers count down', (
    tester,
  ) async {
    final rig = await open(tester, room5);
    for (final n in ['1', '2', '3']) {
      expect(find.text(n), findsNothing);
    }
    await rig.run(const Duration(seconds: 10));
    expect(find.text(RoomIntro.start), findsOneWidget);
    expect(find.byType(TypewriterSubtitle), findsNothing);
    expect(rig.analytics.count(AnalyticsEvent.missionStarted), 0);
  });

  testWidgets('"Start the interview" begins the first line', (tester) async {
    final rig = await open(tester, room5);
    await rig.startInterview();
    await rig.until(find.byType(TypewriterSubtitle));
    expect(find.text(RoomIntro.start), findsNothing);
    expect(rig.analytics.count(AnalyticsEvent.missionStarted), 1);
  });

  testWidgets('Back returns to the tower, starting nothing', (tester) async {
    final rig = await open(tester, room5);
    await tester.tap(find.bySemanticsLabel(RoomIntro.back));
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(seconds: 1));
    expect(find.byType(MissionPlayer), findsNothing);
    expect(rig.analytics.count(AnalyticsEvent.missionStarted), 0);
    expect(await rig.resume.load(room5.id), isNull);
  });

  testWidgets('Calm mode says there is no timer', (tester) async {
    await open(tester, room5, calm: true);
    expect(find.text(RoomIntro.calmTag), findsOneWidget);
    await still(tester, '02-after-intro-calm-mode');
  });

  testWidgets('a voice room says it is answered out loud', (tester) async {
    await open(tester, voiceRoom);
    expect(find.byType(VoicePlayer), findsOneWidget);
    expect(find.text(RoomIntro.outLoud), findsOneWidget);
    expect(find.text(RoomIntro.outLoudHow), findsOneWidget);
    await still(tester, '03-after-intro-out-loud');
  });

  testWidgets('a left room offers Resume and Start over on the same card', (
    tester,
  ) async {
    final m = missions.first;
    final rig = MissionRig(tester);
    await rig.resume.save(
      SavedAttempt(
        missionId: m.id,
        seed: testSeed,
        attemptNumber: 1,
        draftDone: true,
        plays: [SavedPlay(optionId: m.beats.first.options.first.id)],
      ),
    );
    await rig.boot(Routes.mission(m.number), size: phone);
    await rig.until(find.text(RoomIntro.resume));
    expect(find.text(RoomIntro.heading(m)), findsOneWidget);
    expect(find.text(RoomIntro.startOver), findsOneWidget);
    expect(find.text(RoomIntro.leftAt(1, m.beats.length)), findsOneWidget);
    expect(find.text(RoomIntro.start), findsNothing);
    expect(find.text(RoomIntro.untimed), findsOneWidget);
    await still(tester, '04-after-resume');
  });

  testWidgets('2x text: everything still fits and scrolls', (tester) async {
    await open(tester, room5, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text(RoomIntro.start), findsOneWidget);
    await still(tester, '05-after-2x-text');
  });

  testWidgets('reduced motion: the card arrives still', (tester) async {
    await open(tester, room5, reduceMotion: true);
    expect(
      find.descendant(
        of: find.byType(RoomIntro),
        matching: find.byType(Entrance),
      ),
      findsNothing,
    );
  });
}
