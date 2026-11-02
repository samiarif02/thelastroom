import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/notifications/reminder_outlook.dart';
import 'package:the_last_room/core/notifications/reminder_plan.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/notifications/reminders.dart';

import 'reminder_fakes.dart';

void main() {
  late FakeScheduler scheduler;
  late MemoryReminderStore store;
  late RecordingAnalytics analytics;
  late GoRouter router;

  ProviderContainer container({
    bool grant = true,
    bool permitted = false,
    bool supported = true,
    ReminderSettings saved = const ReminderSettings(),
  }) {
    scheduler = FakeScheduler(grant: grant, permitted: permitted);
    store = MemoryReminderStore(saved);
    analytics = RecordingAnalytics();
    router = GoRouter(initialLocation: Routes.home, routes: appRoutes());
    addTearDown(router.dispose);
    final c = ProviderContainer(
      overrides: [
        ...reminderOverrides(
          scheduler: scheduler,
          store: store,
          analytics: analytics,
          supported: supported,
        ),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('off by default: a re-plan schedules nothing', () async {
    final c = container();
    await c.read(remindersProvider).reschedule();
    expect(scheduler.scheduled, isEmpty);
    expect(scheduler.permissionAsks, 0);
  });

  test(
    'yes, and the phone allows it: on, reported, and the week planned',
    () async {
      final c = container();
      final on = await c.read(remindersProvider).enable();
      expect(on, isTrue);
      expect(store.saved, const ReminderSettings(enabled: true, offered: true));
      expect(
        analytics.events.map((e) => e.$1),
        contains(AnalyticsEvent.notificationPermissionGranted),
      );
      // A new player: Mission 1 is next, so Priya nudges on days 1, 3, 5 and 8.
      expect(
        scheduler.scheduled!.map((r) => r.kind),
        everyElement(ReminderKind.nudge),
      );
      expect(scheduler.scheduled, hasLength(planDays.length));
    },
  );

  test('yes, but the phone says no: off, and never offered again', () async {
    final c = container(grant: false);
    final on = await c.read(remindersProvider).enable();
    expect(on, isFalse);
    expect(store.saved, const ReminderSettings(offered: true));
    expect(scheduler.scheduled, isEmpty);
  });

  test('switched off in Settings: everything cancelled', () async {
    final c = container();
    await c.read(remindersProvider).enable();
    await c.read(remindersProvider).disable();
    expect(store.saved.enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
  });

  test('a tapped reminder is reported and opens where it points', () async {
    final c = container();
    c.read(remindersProvider).open('nudge:2:3');
    expect(analytics.events.last.$1, AnalyticsEvent.notificationOpened);
    expect(analytics.events.last.$2, {'type': 'nudge', 'variant': 2});
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, Routes.mission(3));
  });

  test('a payload that is not ours is ignored', () {
    final c = container();
    c.read(remindersProvider).open('something else');
    expect(analytics.events, isEmpty);
  });

  group('send a test reminder (brief 42)', () {
    test("shows tomorrow's real reminder now, in Priya's voice, and reports its kind", () async {
      final c = container(permitted: true);
      final result = await c.read(remindersProvider).sendTest();
      expect(result, TestReminderResult.sent);
      final shown = scheduler.shown.single;
      final planned = (await c.read(remindersProvider).plan(enabled: true))
          .first;
      expect(shown.at, DateTime(2026, 11, 3, 18));
      expect(shown.title, planned.title);
      expect(shown.body, planned.body);
      expect(shown.title, startsWith('Priya'));
      expect(reminderRoute(shown.missionNumber), Routes.mission(1));
      expect(analytics.events.last.$1, AnalyticsEvent.testReminderSent);
      expect(analytics.events.last.$2, {'type': 'nudge'});
    });

    test('works with the switch off, and leaves it off', () async {
      final c = container(permitted: true);
      await c.read(remindersProvider).sendTest();
      expect(scheduler.shown, hasLength(1));
      expect(store.saved.enabled, isFalse);
      expect(scheduler.scheduled, isNull);
    });

    test('the web: nothing is shown or asked', () async {
      final c = container(supported: false);
      expect(
        await c.read(remindersProvider).sendTest(),
        TestReminderResult.unsupported,
      );
      expect(scheduler.shown, isEmpty);
      expect(scheduler.permissionAsks, 0);
      expect(await c.read(remindersProvider).hasPermission(), isFalse);
    });
  });

  group('the next reminder, for Settings (brief 42)', () {
    Future<ReminderOutlook> outlook(ProviderContainer c) =>
        c.read(remindersProvider).outlook();

    test('on and allowed: tomorrow, from the next interviewer', () async {
      final c = container(
        permitted: true,
        saved: const ReminderSettings(enabled: true, offered: true),
      );
      final o = await outlook(c);
      expect(
        nextReminderLine(o, reminderTestNow),
        'Next: tomorrow at 18:00, from Priya',
      );
    });

    test('off, blocked by the phone, or the web: why there is none', () async {
      expect(
        (await outlook(container(permitted: true))).quiet,
        ReminderQuiet.off,
      );
      final blocked = container(
        saved: const ReminderSettings(enabled: true, offered: true),
      );
      expect((await outlook(blocked)).quiet, ReminderQuiet.blocked);
      expect(
        (await outlook(container(supported: false))).quiet,
        ReminderQuiet.web,
      );
    });

    test('the provider follows the switch', () async {
      final c = container(permitted: true);
      final sub = c.listen(reminderOutlookProvider, (_, _) {});
      addTearDown(sub.close);
      expect(
        (await c.read(reminderOutlookProvider.future)).quiet,
        ReminderQuiet.off,
      );
      await c.read(remindersProvider).enable();
      expect((await c.read(reminderOutlookProvider.future)).next, isNotNull);
    });
  });
}
