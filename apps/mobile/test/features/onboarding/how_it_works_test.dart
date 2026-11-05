import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/onboarding/explainer_copy.dart';
import 'package:the_last_room/features/onboarding/explainer_deck.dart';
import 'package:the_last_room/features/onboarding/how_it_works_screen.dart';
import 'package:the_last_room/features/onboarding/name_field.dart';
import 'package:the_last_room/features/progression/interview_date_choices.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';

import '../mission/mission_harness.dart';

/// Issue 75: "How it works" again from Settings, the explainer alone: no questions, the
/// profile untouched, and back to Settings at the end.
void main() {
  const read = Duration(seconds: 2);

  Future<MissionRig> fromSettings(
    WidgetTester tester, {
    bool reduceMotion = false,
    double textScale = 1,
  }) async {
    final rig = MissionRig(tester);
    await rig.boot(
      Routes.settings,
      reduceMotion: reduceMotion,
      textScale: textScale,
    );
    await rig.until(find.byType(SettingsScreen));
    await rig.run(read);
    final how = find.text(SettingsScreen.how);
    await tester.ensureVisible(how);
    await tester.pump();
    await tester.tap(how);
    await rig.until(find.byType(HowItWorksScreen));
    await rig.run(read);
    return rig;
  }

  for (final (scale, still) in [(1.0, false), (2.0, true)]) {
    testWidgets(
      'Settings replays all five pages, then Done returns to Settings '
      '(${scale}x text, reduced motion: $still)',
      (tester) async {
        final rig = await fromSettings(
          tester,
          reduceMotion: still,
          textScale: scale,
        );
        // A replay has Close, not Skip.
        expect(find.text(ExplainerCopy.skip).hitTestable(), findsNothing);
        expect(find.bySemanticsLabel(ExplainerCopy.close), findsOneWidget);
        for (var i = 0; i < ExplainerCopy.pages.length; i++) {
          await rig.until(find.text(ExplainerCopy.pages[i].title));
          await rig.run(read);
          final button = find.text(
            i == ExplainerCopy.pages.length - 1
                ? ExplainerCopy.done
                : ExplainerCopy.next,
          );
          await tester.ensureVisible(button);
          await tester.pump();
          await tester.tap(button);
          await tester.pump();
        }
        await rig.until(find.byType(SettingsScreen));
        await rig.run(read);
        expect(find.byType(HowItWorksScreen), findsNothing);
        expect(find.text(InterviewDateChoices.title), findsNothing);
        expect(find.byType(NameField), findsNothing);
        expect(
          rig.analytics.only(AnalyticsEvent.onboardingExplainerViewed).wire,
          {'page': 5, 'skipped': false, 'replay': true},
        );
        expect(rig.analytics.count(AnalyticsEvent.onboardingCompleted), 0);
        final after = await rig.profile.load();
        expect(after.onboarded, isTrue);
        expect(after.firstName, onboardedPlayer.firstName);
      },
    );
  }

  testWidgets('Close on a replay returns to Settings, counted as skipped', (
    tester,
  ) async {
    final rig = await fromSettings(tester);
    await tester.tap(find.bySemanticsLabel(ExplainerCopy.close));
    await rig.until(find.byType(SettingsScreen));
    expect(rig.analytics.only(AnalyticsEvent.onboardingExplainerViewed).wire, {
      'page': 1,
      'skipped': true,
      'replay': true,
    });
  });

  testWidgets('back on a replay turns back a page, then returns to Settings', (
    tester,
  ) async {
    final rig = await fromSettings(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await rig.until(find.text(ExplainerCopy.pages[1].title));
    await rig.run(read);
    await tester.binding.handlePopRoute();
    await rig.until(find.text(ExplainerCopy.pages[0].title));
    await rig.run(read);
    expect(find.byType(ExplainerDeck), findsOneWidget);
    await tester.binding.handlePopRoute();
    await rig.until(find.byType(SettingsScreen));
    await rig.run(read);
    expect(find.byType(HowItWorksScreen), findsNothing);
  });
}
