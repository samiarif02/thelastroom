import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/intro/character_screen.dart';
import 'package:the_last_room/features/intro/intro_screen.dart';
import 'package:the_last_room/features/intro/title_gate.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../mission/mission_harness.dart';

void main() {
  Future<void> tapText(MissionRig rig, String text) async {
    final f = find.text(text.toUpperCase());
    await rig.until(f);
    await rig.tester.ensureVisible(f);
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  testWidgets('the CV before Mission 1 is the player\'s practice CV', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.character);
    await rig.until(find.byType(CharacterScreen));
    expect(find.text(testName), findsOneWidget);
    expect(find.text(CharacterScreen.premise), findsOneWidget);
    expect(find.text(player.premise), findsNothing);
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
    await rig.until(find.byType(OnboardingScreen));
    expect(rig.analytics.count(AnalyticsEvent.introCompleted), 1);
    expect(
      rig.analytics.only(AnalyticsEvent.introCompleted).wire['skipped'],
      isTrue,
    );
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('title, intro and CV survive ${textScale}x text', (
      tester,
    ) async {
      final rig = MissionRig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.home, textScale: textScale);
      await rig.run(const Duration(seconds: 5));
      expect(find.text(TitleGate.prompt.toUpperCase()), findsOneWidget);
      await rig.tester.tapAt(const Offset(187, 300));
      await rig.until(find.byType(IntroScreen));
      await rig.run(const Duration(seconds: 5));
      await tapText(rig, IntroScreen.skip);
      await rig.until(find.byType(OnboardingScreen));
      await rig.tester.pumpWidget(const SizedBox.shrink());
      final cv = MissionRig(tester);
      await cv.boot(Routes.character, textScale: textScale);
      await cv.until(find.byType(CharacterScreen));
      await cv.run(const Duration(seconds: 1));
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
    // The locked door's button is a vivid one, in sentence case (brief 18b).
    final back = find.text('Back to the tower');
    await rig.until(back);
    await tester.tap(back);
    await tester.pump();
    await rig.until(find.byType(TowerScreen));
  });
}
