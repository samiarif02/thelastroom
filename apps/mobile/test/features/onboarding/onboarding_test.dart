import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/intro/intro_screen.dart';
import 'package:the_last_room/features/onboarding/name_field.dart';
import 'package:the_last_room/features/onboarding/onboarding_copy.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../mission/mission_harness.dart';

void main() {
  /// A player's reading pause on each screen.
  const read = Duration(seconds: 2);

  Future<void> tapText(MissionRig rig, String text) async {
    final f = find.text(text.toUpperCase());
    await rig.until(f);
    await rig.tester.ensureVisible(f);
    await rig.tester.pump();
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  Future<void> pickTile(MissionRig rig, String text) async {
    final f = find.widgetWithText(AnswerCard, text);
    await rig.until(f);
    await rig.run(read);
    await rig.tester.ensureVisible(f);
    await rig.tester.pump();
    await rig.tester.tap(f);
    await rig.run(const Duration(milliseconds: 500));
  }

  /// Title → welcome cards (skipped) → onboarding, answering every question.
  Future<MissionRig> onboard(
    WidgetTester tester, {
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(
      Routes.home,
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    await rig.until(find.byType(TitleScreen));
    await tester.tapAt(const Offset(187, 300));
    await rig.until(find.byType(IntroScreen));
    await rig.run(read);
    await tapText(rig, IntroScreen.skip);
    await rig.until(find.byType(OnboardingScreen));
    await rig.run(read);
    await tester.enterText(find.byType(EditableText), '  Sami ');
    await tester.pump();
    await tapText(rig, NameField.confirm);
    await pickTile(rig, OnboardingCopy.experience[Experience.freshGraduate]!);
    await pickTile(rig, OnboardingCopy.role[TargetRole.product]!);
    await pickTile(rig, OnboardingCopy.nerves[4]);
    await pickTile(rig, OnboardingCopy.goals[1].label);
    await rig.until(find.text(OnboardingCopy.ready));
    await rig.run(read);
    await tapText(rig, OnboardingCopy.toTower);
    await rig.until(find.byType(TowerScreen));
    return rig;
  }

  testWidgets('first launch: onboarding to the Tower in under 60 s', (
    tester,
  ) async {
    final start = tester.binding.clock.now();
    final rig = await onboard(tester);
    final took = tester.binding.clock.now().difference(start);
    expect(took, lessThan(const Duration(seconds: 60)), reason: '$took');

    final saved = await rig.profile.load();
    expect(saved.onboarded, isTrue);
    expect(saved.firstName, 'Sami');
    expect(saved.experience, Experience.freshGraduate);
    expect(saved.targetRole, TargetRole.product);
    expect(saved.nervesLevel, 5);
    expect(saved.calmMode, isTrue, reason: 'nerves 4–5 turn calm mode on');
    expect(saved.weeklyGoal, 3);
    expect(saved.autoAdvance, isTrue);

    expect(rig.analytics.only(AnalyticsEvent.onboardingCompleted).wire, {
      'skipped_steps': 0,
      'named': true,
      'experience': 'freshGraduate',
      'target_role': 'product',
      'nerves_level': 5,
      'calm_mode': true,
      'weekly_goal': 3,
    });
    await rig.until(find.text(TowerScreen.greeting('Sami')));
  });

  testWidgets('the name never reaches analytics', (tester) async {
    final rig = await onboard(tester);
    for (final e in rig.analytics.events) {
      for (final value in e.wire.values) {
        expect('$value', isNot(contains('Sami')), reason: '${e.event}');
      }
    }
  });

  testWidgets('the title, the cards and every button make their sounds', (
    tester,
  ) async {
    final rig = await onboard(tester);
    expect(rig.sounds.count('titleOpened'), 1);
    // Five questions answered, then "ready": one page turn per step.
    expect(rig.sounds.count('pageTurn'), OnboardingStep.values.length - 1);
    // Tap to begin, Skip, That's me, four tiles, Go to the tower.
    expect(rig.sounds.count('uiTap'), 8);
  });

  testWidgets('the name field is one labelled text field for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding);
    await rig.until(find.byType(NameField));
    final fields = find.semantics.byPredicate(
      // A node merged into its parent isn't a node a screen reader visits.
      (n) => n.flagsCollection.isTextField && !n.isMergedIntoParent,
    );
    expect(fields, findsOne);
    expect(fields.evaluate().single.label, NameField.label);
    handle.dispose();
  });

  testWidgets('second launch goes straight to the Tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.home);
    await rig.until(find.byType(TowerScreen));
    expect(find.byType(TitleScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets(
    'every step but the name skips; the name has "call me Candidate"',
    (tester) async {
      final rig = MissionRig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.onboarding);
      await rig.until(find.byType(NameField));
      expect(find.text(OnboardingCopy.skip.toUpperCase()), findsOneWidget);
      // On the name step "Skip" is held invisible and inert.
      expect(find.bySemanticsLabel(OnboardingCopy.skip), findsNothing);
      await tapText(rig, NameField.skip);
      for (var i = 0; i < 4; i++) {
        await rig.run(const Duration(milliseconds: 300));
        await tapText(rig, OnboardingCopy.skip);
      }
      await tapText(rig, OnboardingCopy.toTower);
      await rig.until(find.byType(TowerScreen));
      final saved = await rig.profile.load();
      expect(saved.onboarded, isTrue);
      expect(saved.displayName, PlayerProfile.fallbackName);
      expect(saved.calmMode, isFalse);
      expect(rig.analytics.only(AnalyticsEvent.onboardingCompleted).wire, {
        'skipped_steps': 4,
        'named': false,
        'calm_mode': false,
      });
    },
  );

  for (final (scale, still) in [(2.0, false), (1.0, true), (2.0, true)]) {
    testWidgets('onboarding survives ${scale}x text, reduced motion: $still', (
      tester,
    ) async {
      await onboard(tester, textScale: scale, reduceMotion: still);
    });
  }
}
