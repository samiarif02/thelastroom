import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/notifications/reminder_plan.dart';
import 'package:the_last_room/core/notifications/reminder_scheduler.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/notifications/reminders.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/recall/recall_store.dart';

class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.grant = true});

  final bool grant;
  List<PlannedReminder>? scheduled;
  int permissionAsks = 0;

  @override
  Future<void> init({required void Function(String payload) onTap}) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return grant;
  }

  @override
  Future<void> replace(List<PlannedReminder> plan) async => scheduled = plan;
}

class MemoryReminderStore implements ReminderSettingsStore {
  ReminderSettings saved = const ReminderSettings();

  @override
  Future<ReminderSettings> load() async => saved;

  @override
  Future<void> save(ReminderSettings settings) async => saved = settings;
}

class RecordingAnalytics implements Analytics {
  final List<(AnalyticsEvent, Map<String, Object>)> events = [];

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) =>
      events.add((
        event,
        {for (final e in properties.entries) e.key: e.value.wire},
      ));
}

void main() {
  late FakeScheduler scheduler;
  late MemoryReminderStore store;
  late RecordingAnalytics analytics;
  late GoRouter router;

  ProviderContainer container({bool grant = true}) {
    scheduler = FakeScheduler(grant: grant);
    store = MemoryReminderStore();
    analytics = RecordingAnalytics();
    router = GoRouter(initialLocation: Routes.home, routes: appRoutes());
    addTearDown(router.dispose);
    final c = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(Log(sink: (_) {})),
        analyticsProvider.overrideWithValue(analytics),
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
        recallStoreProvider.overrideWithValue(InMemoryRecallStore()),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        reminderSettingsStoreProvider.overrideWithValue(store),
        reminderClockProvider.overrideWithValue(
          () => DateTime(2026, 11, 2, 18),
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
      // A new player: Mission 1 is next, so Priya nudges on days 1, 2, 3 and 6.
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
}
