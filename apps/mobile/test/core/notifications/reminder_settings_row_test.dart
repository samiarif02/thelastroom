import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/notifications/reminder_outlook.dart';
import 'package:the_last_room/core/notifications/reminder_primer.dart';
import 'package:the_last_room/core/notifications/reminder_settings_row.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../../ui/harness.dart';
import 'reminder_fakes.dart';

/// Brief 42: "Send a test reminder" and the next-reminder line in Settings, on a phone (a fake
/// scheduler) and on the web, at 1x and at 2x text with reduced motion.
void main() {
  late FakeScheduler scheduler;
  late RecordingAnalytics analytics;

  Future<void> pump(
    WidgetTester tester, {
    bool supported = true,
    bool permitted = true,
    bool grant = true,
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    scheduler = FakeScheduler(grant: grant, permitted: permitted);
    analytics = RecordingAnalytics();
    final container = ProviderContainer(
      overrides: reminderOverrides(
        scheduler: scheduler,
        store: MemoryReminderStore(),
        analytics: analytics,
        supported: supported,
      ),
    );
    addTearDown(container.dispose);
    await pumpKit(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: VividPanel(child: ReminderSettingsRow()),
            ),
          ),
        ),
      ),
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    await settle(tester);
  }

  Future<void> tapTest(WidgetTester tester) async {
    await tester.ensureVisible(find.text(ReminderSettingsRow.test));
    await tester.tap(find.text(ReminderSettingsRow.test));
    await settle(tester);
  }

  for (final (scale, reduced) in [(1.0, false), (2.0, true)]) {
    final at = ' (text ${scale}x${reduced ? ', reduced motion' : ''})';

    testWidgets('phone, allowed: shows tomorrow\'s reminder now$at', (
      tester,
    ) async {
      await pump(tester, textScale: scale, reduceMotion: reduced);
      expect(find.text(ReminderSettingsRow.label), findsOneWidget);
      expect(find.text(ReminderLines.off), findsOneWidget);
      await tapTest(tester);
      final shown = scheduler.shown.single;
      expect(shown.title, startsWith('Priya'));
      expect(shown.missionNumber, 1);
      expect(scheduler.permissionAsks, 0);
      expect(find.text(ReminderSettingsRow.testSent), findsOneWidget);
      expect(
        analytics.events.map((e) => e.$1),
        contains(AnalyticsEvent.testReminderSent),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone, not allowed yet: the explainer comes first$at', (
      tester,
    ) async {
      await pump(
        tester,
        permitted: false,
        textScale: scale,
        reduceMotion: reduced,
      );
      await tapTest(tester);
      expect(find.text(ReminderPrimer.title), findsOneWidget);
      expect(scheduler.permissionAsks, 0, reason: 'never the system cold');
      expect(
        analytics.events.map((e) => e.$1),
        contains(AnalyticsEvent.notificationPermissionPrompted),
      );
      await tester.ensureVisible(find.text(ReminderPrimer.yes));
      await tester.tap(find.text(ReminderPrimer.yes));
      await settle(tester);
      expect(scheduler.permissionAsks, 1);
      expect(scheduler.shown, hasLength(1));
      expect(find.text(ReminderSettingsRow.testSent), findsOneWidget);
      // Saying yes switched reminders on: the line now says when the next one comes.
      expect(find.text('Next: tomorrow at 18:00, from Priya'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone, "Not now": nothing asked, nothing shown$at', (
      tester,
    ) async {
      await pump(
        tester,
        permitted: false,
        textScale: scale,
        reduceMotion: reduced,
      );
      await tapTest(tester);
      await tester.ensureVisible(find.text(ReminderPrimer.notNow));
      await tester.tap(find.text(ReminderPrimer.notNow));
      await settle(tester);
      expect(scheduler.permissionAsks, 0);
      expect(scheduler.shown, isEmpty);
      expect(find.text(ReminderSettingsRow.testSent), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone, the system says no: blocked, nothing shown$at', (
      tester,
    ) async {
      await pump(
        tester,
        permitted: false,
        grant: false,
        textScale: scale,
        reduceMotion: reduced,
      );
      await tapTest(tester);
      await tester.ensureVisible(find.text(ReminderPrimer.yes));
      await tester.tap(find.text(ReminderPrimer.yes));
      await settle(tester);
      expect(scheduler.shown, isEmpty);
      expect(find.text(ReminderSettingsRow.denied), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'web: no switch; the button explains reminders are phone-only$at',
      (tester) async {
        await pump(
          tester,
          supported: false,
          textScale: scale,
          reduceMotion: reduced,
        );
        expect(find.text(ReminderSettingsRow.label), findsNothing);
        expect(find.text(ReminderLines.web), findsOneWidget);
        await tapTest(tester);
        expect(find.text(ReminderSettingsRow.testWeb), findsOneWidget);
        expect(scheduler.shown, isEmpty);
        expect(scheduler.permissionAsks, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('switched on and allowed: the line says when and from whom', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(ReminderSettingsRow.label));
    await settle(tester);
    expect(find.text('Next: tomorrow at 18:00, from Priya'), findsOneWidget);
  });
}

/// Lets the futures resolve and the dialog's transition finish, frame by frame, failing on any
/// frame that throws (an overflow at 2x text).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }
}
