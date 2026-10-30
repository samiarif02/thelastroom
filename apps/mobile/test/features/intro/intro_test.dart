import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/intro/character_screen.dart';
import 'package:the_last_room/features/intro/intro_screen.dart';
import 'package:the_last_room/features/intro/title_gate.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/title/title_screen.dart';

import '../mission/mission_harness.dart';

void main() {
  Future<void> tapText(MissionRig rig, String text) async {
    final f = find.text(text.toUpperCase());
    await rig.until(f);
    await rig.tester.ensureVisible(f);
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  testWidgets('title → intro → character card → Mission 1', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.home);
    expect(find.byType(TitleScreen), findsOneWidget);
    await tester.tapAt(const Offset(187, 300));
    await rig.until(find.byType(IntroScreen));

    for (final frame in IntroScreen.frames) {
      await rig.until(find.text(frame.title));
      await rig.run(const Duration(seconds: 1));
      await tapText(
        rig,
        frame == IntroScreen.frames.last ? IntroScreen.last : IntroScreen.next,
      );
    }
    expect(rig.analytics.only(AnalyticsEvent.introCompleted).wire, {
      'skipped': false,
    });

    await rig.until(find.byType(CharacterScreen));
    expect(find.text(player.name), findsOneWidget);
    expect(find.text(player.premise), findsOneWidget);
    await tapText(rig, CharacterScreen.enter);
    await rig.until(find.byType(MissionPlayer));
    expect(rig.state(1).mission, missionTheOpportunity);
  });

  testWidgets('the intro can be skipped from its first frame, once', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.intro);
    await tapText(rig, IntroScreen.skip);
    await rig.until(find.byType(CharacterScreen));
    expect(rig.analytics.count(AnalyticsEvent.introCompleted), 1);
    expect(
      rig.analytics.only(AnalyticsEvent.introCompleted).wire['skipped'],
      isTrue,
    );
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('title, intro and character card survive ${textScale}x text', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.home, textScale: textScale);
      await rig.run(const Duration(seconds: 5));
      expect(find.text(TitleGate.prompt.toUpperCase()), findsOneWidget);
      await rig.tester.tapAt(const Offset(187, 300));
      await rig.until(find.byType(IntroScreen));
      await rig.run(const Duration(seconds: 5));
      await tapText(rig, IntroScreen.skip);
      await rig.until(find.byType(CharacterScreen));
      await rig.run(const Duration(seconds: 1));
    });
  }

  testWidgets('a mission that doesn\'t exist is a locked door, not a crash', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(99));
    await rig.run(const Duration(milliseconds: 500));
    expect(find.text('THIS ROOM IS LOCKED'), findsOneWidget);
    expect(find.textContaining('MissionNotFound'), findsNothing);
    await tapText(rig, 'Back to the lobby');
    await rig.until(find.byType(TitleScreen));
  });
}
