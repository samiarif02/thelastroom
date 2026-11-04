import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/notifications/reminder_primer.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/progression/first_day.dart';
import 'package:the_last_room/features/progression/first_day_moment.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../../core/notifications/reminder_fakes.dart' show MemoryReminderStore;
import '../mission/mission_harness.dart';
import '../tower/played_attempt.dart';

void main() {
  // The progression record's store is the device's: an empty one.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('FirstDay.tomorrow: the concrete hook', () {
    FirstDay day({int notes = 0, Mission? next}) => FirstDay(
      room: missions[0],
      sessions: 1,
      weeklyGoal: 3,
      xp: 40,
      notesTomorrow: notes,
      nextRoom: next,
    );

    test('a note and the next room', () {
      expect(
        day(notes: 1, next: missions[1]).tomorrow,
        'Your first Recall note, about a minute, plus room 2.',
      );
      expect(
        day(notes: 5, next: missions[1]).tomorrow,
        'Your first 5 Recall notes, about 3 minutes, plus room 2.',
      );
    });

    test('a clean room: the next room and who asks it', () {
      expect(
        day(next: missions[1]).tomorrow,
        'Room 2, with ${missions[1].lead.name}.',
      );
    });

    test('gentle: no streak, nothing to lose', () {
      final line = FirstDay.line(3).toLowerCase();
      expect(line, contains('nothing to lose'));
      for (final guilt in [
        'streak',
        'lose your streak',
        "don't break",
        'miss',
      ]) {
        expect(line, isNot(contains(guilt)), reason: guilt);
      }
    });
  });

  group('on the tower after the first room (brief 61)', () {
    Future<MissionRig> backFromRoomOne(
      WidgetTester tester, {
      bool shown = false,
      bool offered = false,
      int attempts = 1,
      double textScale = 1,
      bool reduceMotion = true,
    }) async {
      final rig = MissionRig(tester);
      rig.firstDay.isShown = shown;
      final reminders = MemoryReminderStore(ReminderSettings(offered: offered));
      rig.overrides.add(
        reminderSettingsStoreProvider.overrideWithValue(reminders),
      );
      for (var i = 0; i < attempts; i++) {
        await rig.progress.recordAttempt(playedAttempt(missions[i], pick: 1));
      }
      await rig.boot(
        Routes.tower(lit: attempts),
        textScale: textScale,
        reduceMotion: reduceMotion,
      );
      await rig.until(find.byType(TowerScreen));
      return rig;
    }

    Future<void> answerPrimer(MissionRig rig) async {
      await rig.until(find.text(ReminderPrimer.notNow));
      await rig.tester.ensureVisible(find.text(ReminderPrimer.notNow));
      await rig.tester.tap(find.text(ReminderPrimer.notNow));
      await rig.run(const Duration(milliseconds: 400));
    }

    testWidgets('Day 1: the ring, the XP, tomorrow; then the reminder '
        'explainer, and it never shows again', (tester) async {
      final rig = await backFromRoomOne(tester);
      await rig.until(find.text(FirstDay.title));
      expect(find.text(FirstDay.week(1, 3)), findsOneWidget);
      expect(find.textContaining('XP'), findsWidgets);
      expect(find.text(FirstDay.tomorrowKicker), findsOneWidget);
      expect(find.textContaining('plus room 2'), findsOneWidget);
      expect(rig.analytics.only(AnalyticsEvent.firstDayShown).wire, {
        'recall_tomorrow': true,
      });
      expect(find.text(ReminderPrimer.title), findsNothing);
      expect(rig.firstDay.isShown, isTrue, reason: 'marked once it is up');

      await tester.ensureVisible(find.text(FirstDay.done));
      await tester.tap(find.text(FirstDay.done));
      await rig.run(const Duration(milliseconds: 400));
      expect(find.byType(FirstDayMoment), findsNothing);
      // The existing explainer follows, once: no permission logic of its own.
      await answerPrimer(rig);
      expect(
        rig.analytics.events
            .where(
              (e) => e.event == AnalyticsEvent.notificationPermissionPrompted,
            )
            .length,
        1,
      );

      // Another visit back from room 1 (a replay): neither again.
      rig.container.read(routerProvider).go(Routes.settings);
      await rig.run(const Duration(milliseconds: 600));
      rig.container.read(routerProvider).go(Routes.tower(lit: 1));
      await rig.run(const Duration(seconds: 3));
      expect(find.byType(FirstDayMoment), findsNothing);
      expect(find.text(ReminderPrimer.title), findsNothing);
      expect(
        rig.analytics.events.where(
          (e) => e.event == AnalyticsEvent.firstDayShown,
        ),
        hasLength(1),
      );
    });

    testWidgets('reminders already offered: the moment alone', (tester) async {
      final rig = await backFromRoomOne(tester, offered: true);
      await rig.until(find.text(FirstDay.title));
      await tester.ensureVisible(find.text(FirstDay.done));
      await tester.tap(find.text(FirstDay.done));
      await rig.run(const Duration(seconds: 3));
      expect(find.text(ReminderPrimer.title), findsNothing);
    });

    testWidgets('already shown: straight to the explainer, as before', (
      tester,
    ) async {
      final rig = await backFromRoomOne(tester, shown: true);
      await answerPrimer(rig);
      expect(find.byType(FirstDayMoment), findsNothing);
      expect(
        rig.analytics.events.where(
          (e) => e.event == AnalyticsEvent.firstDayShown,
        ),
        isEmpty,
      );
    });

    testWidgets('not the first room ever (a player from before): no moment', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      rig.overrides.add(
        reminderSettingsStoreProvider.overrideWithValue(
          MemoryReminderStore(const ReminderSettings(offered: true)),
        ),
      );
      await rig.progress.recordAttempt(playedAttempt(missions[0]));
      await rig.progress.recordAttempt(playedAttempt(missions[0], attempt: 2));
      await rig.boot(Routes.tower(lit: 1), reduceMotion: true);
      await rig.until(find.byType(TowerScreen));
      await rig.run(const Duration(seconds: 3));
      expect(find.byType(FirstDayMoment), findsNothing);
    });

    for (final (scale, still) in [(2.0, true), (2.0, false), (1.0, false)]) {
      testWidgets('survives ${scale}x text, reduced motion: $still; the '
          'button is reachable', (tester) async {
        final rig = await backFromRoomOne(
          tester,
          offered: true,
          textScale: scale,
          reduceMotion: still,
        );
        await rig.until(find.text(FirstDay.title));
        await rig.run(const Duration(seconds: 1));
        await tester.ensureVisible(find.text(FirstDay.done));
        await tester.pump();
        await tester.tap(find.text(FirstDay.done));
        await rig.run(const Duration(milliseconds: 600));
        expect(find.byType(FirstDayMoment), findsNothing);
      });
    }
  });
}
