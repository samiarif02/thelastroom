import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/intro/character_screen.dart';
import 'package:the_last_room/features/intro/title_gate.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/title/start_title.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../mission/mission_harness.dart';

void main() {
  Future<void> tapText(MissionRig rig, String text) async {
    final f = find.text(text);
    await rig.until(f);
    await rig.tester.ensureVisible(f);
    await rig.tester.pump();
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  testWidgets('the practice CV opens Mission 1', (tester) async {
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

  for (final textScale in [1.0, 2.0]) {
    testWidgets('first launch: the title, Begin, onboarding at ${textScale}x', (
      tester,
    ) async {
      final rig = MissionRig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.home, textScale: textScale);
      await rig.until(find.byType(TitleGate));
      await rig.run(const Duration(seconds: 2));
      expect(rig.sounds.count('titleOpened'), 1);
      await tapText(rig, TitleGate.prompt);
      await rig.until(find.byType(OnboardingScreen));
    });
  }

  testWidgets('the old intro link lands on onboarding', (tester) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.intro);
    await rig.until(find.byType(OnboardingScreen));
  });

  testWidgets(
    'a returning player sees the title for a moment, then the tower',
    (tester) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.home);
      await rig.until(find.byType(TowerScreen));
      expect(find.byType(TitleScreen), findsOneWidget);
      await rig.run(StartTitle.hold + const Duration(seconds: 1));
      expect(find.byType(TitleScreen), findsNothing);
    },
  );

  testWidgets('a tap skips the returning player\'s title', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.home);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TitleScreen));
    await rig.run(const Duration(seconds: 1));
    expect(find.byType(TitleScreen), findsNothing);
  });

  testWidgets('a mission that doesn\'t exist is a locked door, not a crash', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(99));
    await rig.run(const Duration(milliseconds: 500));
    expect(find.text('THIS ROOM IS LOCKED'), findsOneWidget);
    expect(find.textContaining('MissionNotFound'), findsNothing);
    // The locked door's button is a vivid one, in sentence case (brief 18b).
    await tapText(rig, 'Back to the tower');
    await rig.until(find.byType(TowerScreen));
  });
}
