import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/notifications/reminder_primer.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/features/debrief/scoring_basis_sheet.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/widgets/beat_timer.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/recall/recall_controller.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';
import 'package:the_last_room/features/tips/tip_overlay.dart';
import 'package:the_last_room/features/tips/tips.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/features/voice/audio/silence_detector.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart'
    show FloatingTabBar;
import 'package:the_last_room/ui/paper/dossier.dart';

import '../../core/notifications/reminder_fakes.dart' show MemoryReminderStore;
import '../mission/mission_harness.dart';
import '../tower/played_attempt.dart';
import '../voice/voice_rig.dart';

/// Every tip seen but [tip]: the test meets that one and no other.
Set<Tip> allBut(Tip tip) => {...Tip.values}..remove(tip);

Finder get _overlay => find.byType(TipOverlay);

Finder _tab(String label) => find.descendant(
  of: find.byType(FloatingTabBar),
  matching: find.text(label),
);

void main() {
  group('the store and the controller', () {
    test('the old tower tour flag counts as the door tip seen; reset clears '
        'every tip', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesTipStore.legacyTour: true,
      });
      const store = SharedPreferencesTipStore();
      expect(await store.seen(), {Tip.towerDoor});
      await store.markSeen(Tip.whyStep);
      expect(await store.seen(), {Tip.towerDoor, Tip.whyStep});
      await store.reset();
      expect(await store.seen(), isEmpty);
    });

    test('one tip on screen at a time; a seen tip never comes back', () async {
      final analytics = RecordingAnalytics();
      final store = InMemoryTipStore();
      final container = ProviderContainer(
        overrides: [
          tipStoreProvider.overrideWithValue(store),
          analyticsProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(container.dispose);
      container.read(tipsProvider);
      await Future<void>.delayed(Duration.zero);
      final tips = container.read(tipsProvider.notifier);
      expect(tips.shown(Tip.yourFile), isTrue);
      expect(tips.shown(Tip.recallDue), isFalse, reason: 'one at a time');
      await tips.done(Tip.yourFile, TipAction.dismissed);
      expect(tips.shown(Tip.yourFile), isFalse, reason: 'seen');
      expect(store.flags, {Tip.yourFile});
      expect(tips.shown(Tip.recallDue), isTrue);
      expect(analytics.count(AnalyticsEvent.tipShown), 2);
      expect(analytics.only(AnalyticsEvent.tipDone).wire, {
        'tip': 'yourFile',
        'action': 'dismissed',
      });
    });

    test('a store that cannot be read counts as every tip seen', () async {
      final container = ProviderContainer(
        overrides: [tipStoreProvider.overrideWithValue(_BrokenStore())],
      );
      addTearDown(container.dispose);
      container.read(tipsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(tipsProvider).loaded, isTrue);
      for (final tip in Tip.values) {
        expect(container.read(tipsProvider.notifier).canShow(tip), isFalse);
      }
    });

    test('the voice tip says the silence window the recorder uses', () {
      expect(
        Tip.voiceMic.line,
        contains('${SilenceDetector.defaultWindow.inSeconds} seconds'),
      );
    });
  });

  group('tower_door', () {
    Future<MissionRig> firstVisit(
      WidgetTester tester, {
      double textScale = 1,
    }) async {
      final rig = MissionRig(tester);
      rig.tips.flags.remove(Tip.towerDoor);
      await rig.boot(Routes.tower(), textScale: textScale, reduceMotion: true);
      await rig.until(_overlay);
      await rig.run(const Duration(milliseconds: 600));
      return rig;
    }

    testWidgets('shows once round the door to play; the door still starts '
        'the room', (tester) async {
      final rig = await firstVisit(tester);
      expect(find.text(Tip.towerDoor.line), findsOneWidget);
      expect(rig.analytics.only(AnalyticsEvent.tipShown).wire, {
        'tip': 'towerDoor',
        'replay': false,
      });
      await tester.tap(
        find.bySemanticsLabel('Room 1, ${missions[0].title}. Play.'),
      );
      await rig.run(const Duration(milliseconds: 300));
      expect(_overlay, findsNothing);
      expect(rig.tips.flags, contains(Tip.towerDoor));
      expect(rig.analytics.only(AnalyticsEvent.tipDone).wire, {
        'tip': 'towerDoor',
        'action': 'followed',
      });
      await rig.until(find.byType(MissionPlayer));
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('"Got it" puts it away for good (${scale}x text)', (
        tester,
      ) async {
        final rig = await firstVisit(tester, textScale: scale);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(TipBubble.gotIt));
        await tester.pump();
        await tester.tap(find.text(TipBubble.gotIt));
        await rig.run(const Duration(milliseconds: 300));
        expect(_overlay, findsNothing);
        expect(rig.tips.flags, contains(Tip.towerDoor));
        expect(rig.analytics.only(AnalyticsEvent.tipDone).wire, {
          'tip': 'towerDoor',
          'action': 'dismissed',
        });
        expect(find.byType(MissionPlayer), findsNothing);
        // A new visit: it doesn't come back.
        rig.container.read(routerProvider).go(Routes.settings);
        await rig.run(const Duration(milliseconds: 600));
        rig.container.read(routerProvider).go(Routes.tower());
        await rig.run(const Duration(seconds: 2));
        expect(_overlay, findsNothing);
      });
    }

    testWidgets('a tap anywhere else dismisses it', (tester) async {
      final rig = await firstVisit(tester);
      await tester.tapAt(const Offset(8, 8));
      await rig.run(const Duration(milliseconds: 300));
      expect(_overlay, findsNothing);
      expect(
        rig.analytics.only(AnalyticsEvent.tipDone).wire['action'],
        'dismissed',
      );
    });
  });

  group('your_file and recall_due on the tower', () {
    Future<MissionRig> backFromRoomOne(
      WidgetTester tester, {
      Set<Tip> unseen = const {Tip.yourFile},
      int recallDue = 0,
    }) async {
      final rig = MissionRig(tester);
      rig.tips.flags.removeAll(unseen);
      rig.overrides.addAll([
        recallDueCountProvider.overrideWith((ref) async => recallDue),
        reminderSettingsStoreProvider.overrideWithValue(MemoryReminderStore()),
      ]);
      await rig.progress.recordAttempt(playedAttempt(missions[0]));
      await rig.boot(Routes.tower(lit: 1), reduceMotion: true);
      await rig.until(find.byType(TowerScreen));
      return rig;
    }

    Future<void> answerPrimer(MissionRig rig) async {
      await rig.until(find.text(ReminderPrimer.notNow));
      expect(_overlay, findsNothing, reason: 'never with the explainer');
      await rig.tester.tap(find.text(ReminderPrimer.notNow));
      await rig.run(const Duration(milliseconds: 300));
    }

    testWidgets('after the first room, once the explainer is answered, it '
        'points at Skills; the tab still opens the file', (tester) async {
      final rig = await backFromRoomOne(tester);
      await answerPrimer(rig);
      await rig.until(_overlay);
      expect(find.text(Tip.yourFile.line), findsOneWidget);
      final hole = tester.widget<TipOverlay>(_overlay).target;
      expect(
        hole.contains(tester.getCenter(_tab(TowerScreen.progress))),
        isTrue,
      );
      await tester.tap(_tab(TowerScreen.progress));
      await rig.run(const Duration(milliseconds: 600));
      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(rig.analytics.only(AnalyticsEvent.tipDone).wire, {
        'tip': 'yourFile',
        'action': 'followed',
      });
    });

    testWidgets('only one tip at a time: the Recall tip waits for the next '
        'visit', (tester) async {
      final rig = await backFromRoomOne(
        tester,
        unseen: {Tip.yourFile, Tip.recallDue},
        recallDue: 2,
      );
      await answerPrimer(rig);
      await rig.until(_overlay);
      expect(_overlay, findsOneWidget);
      expect(find.text(Tip.yourFile.line), findsOneWidget);
      await tester.tap(find.text(TipBubble.gotIt));
      await rig.run(const Duration(seconds: 2));
      expect(_overlay, findsNothing, reason: 'one tip per visit');

      // The next visit: the Recall tip, on the Recall tab.
      rig.container.read(routerProvider).go(Routes.settings);
      await rig.run(const Duration(milliseconds: 600));
      rig.container.read(routerProvider).go(Routes.tower());
      await rig.until(_overlay);
      expect(find.text(Tip.recallDue.line), findsOneWidget);
      final hole = tester.widget<TipOverlay>(_overlay).target;
      expect(
        hole.contains(tester.getCenter(_tab(TowerScreen.recallTab))),
        isTrue,
      );
      expect(
        rig.analytics.events
            .where((e) => e.event == AnalyticsEvent.tipShown)
            .map((e) => e.wire['tip']),
        ['yourFile', 'recallDue'],
      );
    });
  });

  testWidgets('"Show tips again" resets every tip and returns to the tower', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.settings, reduceMotion: true);
    await rig.until(find.text(SettingsScreen.tips));
    await tester.ensureVisible(find.text(SettingsScreen.tips));
    await tester.pump();
    await tester.tap(find.text(SettingsScreen.tips));
    await rig.until(_overlay);
    expect(find.byType(TowerScreen), findsOneWidget);
    expect(rig.tips.flags, isEmpty);
    expect(rig.analytics.only(AnalyticsEvent.tipShown).wire, {
      'tip': 'towerDoor',
      'replay': true,
    });
  });

  group('in a choice room', () {
    Future<MissionRig> toCards(
      WidgetTester tester,
      Tip unseen, {
      int number = 1,
      double textScale = 1,
    }) async {
      final rig = MissionRig(tester);
      rig.tips.flags.remove(unseen);
      await rig.unlockThrough(number);
      await rig.boot(Routes.mission(number), textScale: textScale);
      await rig.playLines(number);
      if (rig.state(number).mission.offersDraft) await rig.skipDraft();
      await rig.until(find.byType(ChoiceCard));
      return rig;
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('answer_cards: over the first cards and "Lock in"; a tap on '
          'a card picks it (${scale}x text)', (tester) async {
        final rig = await toCards(tester, Tip.answerCards, textScale: scale);
        await rig.until(_overlay);
        expect(find.text(Tip.answerCards.line), findsOneWidget);
        expect(rig.analytics.only(AnalyticsEvent.tipShown).wire, {
          'tip': 'answerCards',
          'replay': false,
        });
        final first = missionTheOpportunity.beats.first;
        final option = rig.state(1).optionsForBeat(0).first;
        await rig.run(readFor);
        // A tap on card A where it shows through the cut-out (the bubble may cover its top
        // edge when the room above is short).
        final hole = tester.widget<TipOverlay>(_overlay).hole;
        final card = tester
            .getRect(find.widgetWithText(ChoiceCard, option.text))
            .intersect(hole);
        final bubble = tester.getRect(
          find.ancestor(
            of: find.byType(TipBubble),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        final top = bubble.bottom > card.top && bubble.top < card.top
            ? bubble.bottom
            : card.top;
        final at = Offset(card.center.dx, (top + card.bottom) / 2);
        await tester.tapAt(at);
        await tester.pump();
        await rig.run(const Duration(milliseconds: 300));
        expect(_overlay, findsNothing);
        expect(rig.analytics.only(AnalyticsEvent.tipDone).wire, {
          'tip': 'answerCards',
          'action': 'followed',
        });
        expect(
          find.text(MissionPlayer.lockLabel(ChoiceCard.letterFor(0))),
          findsOneWidget,
          reason: 'the tap went through: line A is picked',
        );
        // Said, explained, and on to the next beat: no tip again.
        await rig.tapOnce(option);
        await rig.pick(first.why!.reasons.first);
        await rig.until(find.text(beatLabel(BeatKind.evidence, 1, 3)));
        await rig.run(const Duration(seconds: 1));
        expect(_overlay, findsNothing);
        expect(rig.analytics.count(AnalyticsEvent.tipShown), 1);
      });
    }

    testWidgets('why_step: over the reasons once she has asked; "Got it" puts '
        'it away', (tester) async {
      final rig = await toCards(tester, Tip.whyStep);
      final option = rig.state(1).optionsForBeat(0).first;
      await rig.pick(option);
      await rig.until(_overlay);
      expect(find.text(Tip.whyStep.line), findsOneWidget);
      final hole = tester.widget<TipOverlay>(_overlay).target;
      final reason = rig.state(1).reasonsForBeat(0).first;
      expect(
        hole.overlaps(
          tester.getRect(find.widgetWithText(ChoiceCard, reason.text)),
        ),
        isTrue,
      );
      await tester.tap(find.text(TipBubble.gotIt));
      await rig.run(const Duration(milliseconds: 300));
      expect(_overlay, findsNothing);
      expect(rig.tips.flags, contains(Tip.whyStep));
      await rig.pick(reason);
      expect(rig.state(1).plays.first.reason, isNotNull);
    });

    testWidgets('a timed room: the countdown waits while the tip is up', (
      tester,
    ) async {
      final rig = await toCards(tester, Tip.answerCards, number: 2);
      expect(missionTellMeAboutYourself.timed, isTrue);
      await rig.until(_overlay);
      expect(find.byType(BeatTimer), findsOneWidget);
      await rig.run(
        BeatTimer.defaultDuration + const Duration(seconds: 5),
        step: const Duration(milliseconds: 500),
      );
      expect(rig.analytics.count(AnalyticsEvent.answerTimerExpired), 0);
      expect(rig.sounds.count('timerPulse'), 0);
      await tester.tap(find.text(TipBubble.gotIt));
      await rig.run(
        BeatTimer.defaultDuration,
        step: const Duration(milliseconds: 500),
      );
      expect(rig.analytics.count(AnalyticsEvent.answerTimerExpired), 1);
    });

    testWidgets('first_result: under the sheet, only once its whole timeline '
        'has played', (tester) async {
      final rig = await toCards(tester, Tip.firstResult);
      const m = missionTheOpportunity;
      for (final id in [
        'm01_open_role_fit',
        'm01_evidence_team_did',
        'm01_land_bring_habit',
      ]) {
        await rig.say(m.optionById(id)!);
      }
      await rig.until(find.text(rig.state(1).followUpLine!.text));
      await rig.run(const Duration(milliseconds: 300));
      if (rig.typing) await rig.tapScene();
      await rig.say(m.optionById('m01_reply_part_led_it')!);
      await rig.until(find.byType(Dossier));
      // Slide, stamps, seal, pen: never a tip while any of it plays.
      await rig.run(
        BrandMotion.dossier,
        eachFrame: () => expect(find.byType(TipBubble), findsNothing),
      );
      await rig.until(find.byType(TipBubble));
      expect(find.text(Tip.firstResult.line), findsOneWidget);
      expect(_overlay, findsNothing, reason: 'no dim over the sheet');
      final sheet = tester.getRect(find.byType(Dossier));
      final bubble = tester.getRect(find.byType(TipBubble));
      expect(bubble.top, greaterThanOrEqualTo(sheet.bottom));
      await tester.ensureVisible(find.text(ScoringBasisSheet.open));
      await tester.pump();
      await tester.tap(find.text(ScoringBasisSheet.open));
      await rig.run(const Duration(milliseconds: 600));
      expect(find.byType(TipBubble), findsNothing);
      expect(rig.analytics.only(AnalyticsEvent.tipDone).wire, {
        'tip': 'firstResult',
        'action': 'followed',
      });
    });
  });

  testWidgets('voice_mic: on the record tile once the recorder is ready; a '
      'tap on it records', (tester) async {
    final rig = VoiceRig(tester);
    rig.tips.flags.remove(Tip.voiceMic);
    await rig.boot();
    await rig.playToAnswer();
    await rig.until(_overlay);
    expect(find.text(Tip.voiceMic.line), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RecorderPanel.recordLabel));
    await tester.pump();
    await tester.pump();
    expect(_overlay, findsNothing);
    expect(find.text(RecorderPanel.recordingLine), findsOneWidget);
    expect(rig.analytics.only(AnalyticsEvent.tipDone).wire, {
      'tip': 'voiceMic',
      'action': 'followed',
    });
  });
}

class _BrokenStore implements TipStore {
  @override
  Future<Set<Tip>> seen() => Future.error(StateError('no disk'));

  @override
  Future<void> markSeen(Tip tip) async {}

  @override
  Future<void> reset() async {}
}
