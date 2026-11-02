import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/notifications/reminder_plan.dart';
import 'package:the_last_room/core/notifications/reminder_scheduler.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/notifications/reminders.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/recall/recall_store.dart';

/// The platform side of reminders, in memory: what was scheduled, shown and asked.
class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.grant = true, this.permitted = false});

  /// What the system answers when asked.
  final bool grant;

  /// Whether the system already allows notifications (before any ask).
  bool permitted;
  List<PlannedReminder>? scheduled;
  final List<PlannedReminder> shown = [];
  int permissionAsks = 0;

  @override
  Future<void> init({required void Function(String payload) onTap}) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    permitted = grant;
    return grant;
  }

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<void> replace(List<PlannedReminder> plan) async => scheduled = plan;

  @override
  Future<void> show(PlannedReminder reminder) async => shown.add(reminder);
}

class MemoryReminderStore implements ReminderSettingsStore {
  MemoryReminderStore([this.saved = const ReminderSettings()]);

  ReminderSettings saved;

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

/// 18:00 on a Monday: the clock reminders tests plan from.
final DateTime reminderTestNow = DateTime(2026, 11, 2, 18);

/// Everything reminders read, in memory, for a container or a widget's scope.
List<Override> reminderOverrides({
  required FakeScheduler scheduler,
  required MemoryReminderStore store,
  required RecordingAnalytics analytics,
  bool supported = true,
}) => [
  logProvider.overrideWithValue(Log(sink: (_) {})),
  analyticsProvider.overrideWithValue(analytics),
  progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
  recallStoreProvider.overrideWithValue(InMemoryRecallStore()),
  progressionStoreProvider.overrideWithValue(InMemoryProgressionStore()),
  reminderSchedulerProvider.overrideWithValue(scheduler),
  reminderSettingsStoreProvider.overrideWithValue(store),
  reminderClockProvider.overrideWithValue(() => reminderTestNow),
  remindersSupportedProvider.overrideWithValue(supported),
];
