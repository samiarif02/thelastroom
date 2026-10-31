import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/back_to_exit.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/mission_screen.dart';
import 'package:the_last_room/features/mission/widgets/scene_notes.dart';
import 'package:the_last_room/features/onboarding/onboarding_copy.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';
import 'package:the_last_room/features/tower/settings_gear.dart';
import 'package:the_last_room/features/tower/tower_hero.dart';
import 'package:the_last_room/features/tower/tower_rooms.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../features/mission/mission_harness.dart';

/// Brief 20 (owner: "when I press back, the app completely closes"): back from every screen the
/// tower opens lands on the tower; at a root, one back shows the hint and only a second within
/// two seconds exits.
void main() {
  var exits = 0;
  setUp(() {
    exits = 0;
    BackToExit.exit = () async => exits++;
  });

  /// The Android back button.
  Future<void> back(MissionRig rig) async {
    await rig.tester.binding.handlePopRoute();
    await rig.run(const Duration(milliseconds: 400));
  }

  Future<MissionRig> atTower(WidgetTester tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 300));
    return rig;
  }

  testWidgets('at the tower one back hints, a second within 2 s exits', (
    tester,
  ) async {
    final rig = await atTower(tester);
    await back(rig);
    expect(find.text(BackToExit.hint), findsOneWidget);
    expect(exits, 0);
    expect(find.byType(TowerScreen), findsOneWidget);
    await back(rig);
    expect(exits, 1);
  });

  testWidgets('the hint lapses: a back after 2 s only hints again', (
    tester,
  ) async {
    final rig = await atTower(tester);
    await back(rig);
    await rig.run(BackToExit.window + const Duration(milliseconds: 200));
    expect(find.text(BackToExit.hint), findsNothing);
    await back(rig);
    expect(exits, 0);
    expect(find.text(BackToExit.hint), findsOneWidget);
  });

  testWidgets('back from your file lands on the tower', (tester) async {
    final rig = await atTower(tester);
    await tester.tap(find.text(TowerScreen.progress));
    await rig.until(find.byType(ProgressScreen));
    await back(rig);
    expect(find.byType(ProgressScreen), findsNothing);
    expect(find.byType(TowerScreen), findsOneWidget);
    expect(exits, 0);
  });

  testWidgets('the gear opens settings, and back lands on the tower', (
    tester,
  ) async {
    final rig = await atTower(tester);
    await tester.tap(find.bySemanticsLabel(SettingsGear.label));
    await rig.until(find.byType(SettingsScreen));
    await back(rig);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(TowerScreen), findsOneWidget);
    expect(exits, 0);
  });

  testWidgets('back in a mission asks to leave; it never exits the app', (
    tester,
  ) async {
    final rig = await atTower(tester);
    await tester.tap(
      find.bySemanticsLabel(
        TowerHero.playLabel(towerRooms(missions, const []).first),
      ),
    );
    await rig.until(find.byType(MissionPlayer));
    await rig.run(const Duration(seconds: 1));
    await back(rig);
    expect(find.byType(LeaveSheet), findsOneWidget);
    expect(find.byType(TowerScreen), findsNothing);
    expect(exits, 0);
  });

  testWidgets('a deep link opens the mission with the tower underneath', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot('/mission/1', reduceMotion: true);
    await rig.until(find.byType(MissionScreen));
    expect(
      rig.container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      Routes.mission(1),
    );
    // The tower beneath is built but not seen: it hasn't opened.
    expect(
      rig.analytics.events.where((e) => e.event == AnalyticsEvent.towerOpened),
      isEmpty,
    );
  });

  testWidgets('an old /progress link lands under the tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot('/progress', reduceMotion: true);
    await rig.until(find.byType(ProgressScreen));
    await back(rig);
    await rig.until(find.byType(TowerScreen));
    expect(exits, 0);
  });

  testWidgets('onboarding: back steps back, and on the first step hints', (
    tester,
  ) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding, reduceMotion: true);
    await rig.until(find.byType(OnboardingScreen));
    await tester.tap(find.text(OnboardingCopy.next));
    await rig.until(find.text(OnboardingCopy.castTitle));
    await back(rig);
    await rig.until(find.text(OnboardingCopy.gameTitle));
    expect(find.text(BackToExit.hint), findsNothing);
    await back(rig);
    expect(find.text(BackToExit.hint), findsOneWidget);
    expect(exits, 0);
  });
}
