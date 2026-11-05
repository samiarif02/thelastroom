import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/intro/title_gate.dart';
import 'package:the_last_room/features/onboarding/explainer_copy.dart';
import 'package:the_last_room/features/onboarding/explainer_deck.dart';
import 'package:the_last_room/features/onboarding/name_field.dart';
import 'package:the_last_room/features/onboarding/onboarding_copy.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/progression/interview_date_choices.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../mission/mission_harness.dart';

void main() {
  /// A player's reading pause on each screen.
  const read = Duration(seconds: 2);

  Future<void> tapText(MissionRig rig, String text) async {
    final f = find.text(text);
    await rig.until(f);
    await rig.tester.ensureVisible(f);
    await rig.tester.pump();
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  /// The explainer, reading each page, to the questions.
  Future<void> explain(MissionRig rig) async {
    for (var i = 0; i < ExplainerCopy.pages.length - 1; i++) {
      await rig.until(find.text(ExplainerCopy.pages[i].title));
      await rig.run(read);
      await tapText(rig, ExplainerCopy.next);
    }
    await rig.until(find.text(ExplainerCopy.pages.last.title));
    await rig.run(read);
    await tapText(rig, ExplainerCopy.ready);
  }

  /// The explainer, then the questions (the interview date left unanswered: it's optional),
  /// then the name.
  Future<MissionRig> onboard(
    WidgetTester tester, {
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(
      Routes.onboarding,
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    await rig.until(find.byType(OnboardingScreen));
    await explain(rig);
    await rig.until(find.text(InterviewDateChoices.title));
    await rig.run(read);
    await tapText(rig, OnboardingCopy.next);
    await rig.until(find.byType(NameField));
    await rig.run(read);
    await tester.enterText(find.byType(EditableText), '  Sami ');
    await tester.pump();
    await tapText(rig, NameField.confirm);
    await rig.until(find.byType(TowerScreen));
    return rig;
  }

  testWidgets(
    'first launch: how it works, then the questions, to the Tower in under 60 s',
    (tester) async {
      final start = tester.binding.clock.now();
      final rig = await onboard(tester);
      final took = tester.binding.clock.now().difference(start);
      expect(took, lessThan(const Duration(seconds: 60)), reason: '$took');

      final saved = await rig.profile.load();
      expect(saved.onboarded, isTrue);
      expect(saved.firstName, 'Sami');
      expect(saved.calmMode, const PlayerProfile().calmMode);
      expect(rig.analytics.only(AnalyticsEvent.onboardingCompleted).wire, {
        'skipped_steps': 0,
        'named': true,
        'calm_mode': const PlayerProfile().calmMode,
      });
      expect(
        rig.analytics.only(AnalyticsEvent.onboardingExplainerViewed).wire,
        {'page': 5, 'skipped': false, 'replay': false},
      );
      await rig.until(find.textContaining('Sami.'));
    },
  );

  testWidgets(
    'how it works: five pages, each with its idea, then the questions',
    (tester) async {
      final rig = MissionRig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.onboarding);
      for (var i = 0; i < ExplainerCopy.pages.length; i++) {
        final page = ExplainerCopy.pages[i];
        await rig.until(find.text(page.title));
        expect(find.text(page.kicker), findsOneWidget);
        expect(find.text(page.line), findsOneWidget);
        expect(find.bySemanticsLabel('Page ${i + 1} of 5'), findsOneWidget);
        await rig.run(read);
        await tapText(
          rig,
          i == ExplainerCopy.pages.length - 1
              ? ExplainerCopy.ready
              : ExplainerCopy.next,
        );
      }
      await rig.until(find.text(InterviewDateChoices.title));
      expect(find.bySemanticsLabel('Step 1 of 2'), findsOneWidget);
      await tapText(rig, OnboardingCopy.next);
      await rig.until(find.text(OnboardingCopy.nameTitle));
      expect(find.bySemanticsLabel('Step 2 of 2'), findsOneWidget);
    },
  );

  testWidgets('the pages swipe both ways, and Back turns back a page', (
    tester,
  ) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding);
    await rig.until(find.text(ExplainerCopy.pages[0].title));
    await rig.run(read);
    // No Back on the first page of onboarding.
    expect(find.bySemanticsLabel(ExplainerCopy.back), findsNothing);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await rig.until(find.text(ExplainerCopy.pages[1].title));
    await rig.run(read);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await rig.until(find.text(ExplainerCopy.pages[2].title));
    await rig.run(read);
    await tester.tap(find.bySemanticsLabel(ExplainerCopy.back));
    await rig.until(find.text(ExplainerCopy.pages[1].title));
    await rig.run(read);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await rig.until(find.text(ExplainerCopy.pages[0].title));
    await rig.run(read);
    expect(find.bySemanticsLabel('Page 1 of 5'), findsOneWidget);
  });

  testWidgets('Skip on the explainer goes to the questions, not past them', (
    tester,
  ) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding);
    await rig.until(find.text(ExplainerCopy.pages[0].title));
    await tapText(rig, ExplainerCopy.next);
    await rig.until(find.text(ExplainerCopy.pages[1].title));
    await rig.run(read);
    await tapText(rig, ExplainerCopy.skip);
    await rig.until(find.text(InterviewDateChoices.title));
    expect(find.byType(ExplainerDeck), findsNothing);
    expect(rig.analytics.only(AnalyticsEvent.onboardingExplainerViewed).wire, {
      'page': 2,
      'skipped': true,
      'replay': false,
    });
    await tapText(rig, OnboardingCopy.next);
    await rig.until(find.byType(NameField));
    await rig.run(read);
    await tapText(rig, NameField.skip);
    await rig.until(find.byType(TowerScreen));
    // Pages 2 to 5 skipped past.
    expect(
      rig.analytics
          .only(AnalyticsEvent.onboardingCompleted)
          .wire['skipped_steps'],
      4,
    );
  });

  testWidgets('the name never reaches analytics', (tester) async {
    final rig = await onboard(tester);
    for (final e in rig.analytics.events) {
      for (final value in e.wire.values) {
        expect('$value', isNot(contains('Sami')), reason: '${e.event}');
      }
    }
  });

  testWidgets('every step turns a page, every button taps', (tester) async {
    final rig = await onboard(tester);
    // Four explainer pages, into the questions, then the name.
    expect(rig.sounds.count('pageTurn'), 4 + 1 + 1);
    // Next ×4, "Let's get you ready", Next, Let's go.
    expect(rig.sounds.count('uiTap'), 7);
  });

  testWidgets('the name field is one labelled text field for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding);
    await tapText(rig, ExplainerCopy.skip);
    await rig.until(find.text(InterviewDateChoices.title));
    await rig.run(read);
    await tapText(rig, OnboardingCopy.skip);
    await rig.until(find.byType(NameField));
    await rig.run(read);
    final fields = find.semantics.byPredicate(
      // A node merged into its parent isn't a node a screen reader visits.
      (n) => n.flagsCollection.isTextField && !n.isMergedIntoParent,
    );
    expect(fields, findsOne);
    expect(fields.evaluate().single.label, NameField.label);
    // Enabled: the web marks a text field with no enabled state `disabled` (brief 44).
    expect(fields.evaluate().single.flagsCollection.isEnabled, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('second launch goes straight to the Tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.home);
    await rig.until(find.byType(TowerScreen));
    expect(find.byType(TitleGate), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets(
    'Skip, Skip goes to the name, and the name has "call me Candidate"',
    (tester) async {
      final handle = tester.ensureSemantics();
      final rig = MissionRig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.onboarding);
      await tapText(rig, ExplainerCopy.skip);
      await rig.until(find.text(InterviewDateChoices.title));
      await rig.run(read);
      await tapText(rig, OnboardingCopy.skip);
      await rig.until(find.byType(NameField));
      await rig.run(read);
      // On the name step "Skip" is held invisible and inert.
      expect(find.semantics.byLabel(OnboardingCopy.skip), findsNothing);
      handle.dispose();
      await tapText(rig, NameField.skip);
      await rig.until(find.byType(TowerScreen));
      final saved = await rig.profile.load();
      expect(saved.onboarded, isTrue);
      expect(saved.displayName, PlayerProfile.fallbackName);
      expect(
        rig.analytics
            .only(AnalyticsEvent.onboardingCompleted)
            .wire['skipped_steps'],
        // The five explainer pages and the interview date.
        6,
      );
      expect(
        rig.analytics.only(AnalyticsEvent.onboardingCompleted).wire['named'],
        isFalse,
      );
    },
  );

  testWidgets('"Let\'s go" waits for a name', (tester) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding);
    await tapText(rig, ExplainerCopy.skip);
    await rig.until(find.text(InterviewDateChoices.title));
    await rig.run(read);
    await tapText(rig, OnboardingCopy.skip);
    await rig.until(find.byType(NameField));
    await rig.run(read);
    await tester.tap(find.text(NameField.confirm));
    await rig.run(read);
    expect(find.byType(TowerScreen), findsNothing);
  });

  for (final (scale, still) in [(2.0, false), (1.0, true), (2.0, true)]) {
    testWidgets('onboarding survives ${scale}x text, reduced motion: $still', (
      tester,
    ) async {
      await onboard(tester, textScale: scale, reduceMotion: still);
    });
  }
}
