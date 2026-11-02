import 'dart:async';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../features/progression/progression.dart';
import '../../features/recall/recall_controller.dart';
import '../../features/recall/recall_store.dart';
import '../../features/tower/tower_rooms.dart';
import '../analytics/analytics_event.dart';
import '../analytics/event_value.dart';
import '../progress/progress_repository.dart';
import 'reminder_outlook.dart';
import 'reminder_plan.dart';
import 'reminder_scheduler.dart';
import 'reminder_settings.dart';

/// Local reminders are a mobile thing (FR-53): the web build has none.
const bool remindersSupported = !kIsWeb;

/// [remindersSupported], as a provider so Settings' web state can be tested on any platform.
final remindersSupportedProvider = Provider<bool>((ref) => remindersSupported);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationsScheduler(),
);

/// The device's clock for planning. Tests pin it.
final reminderClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final remindersProvider = Provider<Reminders>(Reminders.new);

/// The next reminder, or why there is none, for the line under the switch in Settings. Read
/// again whenever the choices change.
final reminderOutlookProvider = FutureProvider.autoDispose<ReminderOutlook>((
  ref,
) {
  ref.watch(reminderSettingsProvider);
  return ref.read(remindersProvider).outlook();
});

/// How "Send a test reminder" went.
enum TestReminderResult {
  /// Tomorrow's reminder is in the notification shade.
  sent,

  /// Nothing to remind the player of: every room is done and no cards are due.
  nothingPlanned,

  /// The web: reminders are phone-only.
  unsupported,

  /// The system refused it (no permission after all, an old OS).
  failed,
}

/// Plans and schedules the reminders from the game's own state: the Recall Room's due cards and
/// the next mission on the tower. It reads features' pure rules (`towerRooms`, the recall
/// schedule) rather than duplicating them. Nothing here throws: a failure is logged and the
/// game goes on.
class Reminders {
  Reminders(this._ref);

  final Ref _ref;

  ReminderScheduler get _scheduler => _ref.read(reminderSchedulerProvider);

  bool get _supported => _ref.read(remindersSupportedProvider);

  /// The reminders the game would schedule now, from its own state; [enabled] false plans
  /// none. Throws if the stores can't be read: callers catch.
  Future<List<PlannedReminder>> plan({required bool enabled}) async {
    final now = _ref.read(reminderClockProvider)();
    final today = CalendarDay(now.year, now.month, now.day);
    final progress = _ref.read(progressRepositoryProvider);
    final schedule = await syncRecallSchedule(
      store: _ref.read(recallStoreProvider),
      progress: progress,
      deck: _ref.read(recallDeckProvider),
      today: today,
    );
    final rooms = towerRooms(missions, await progress.attempts());
    final next = rooms
        .where((r) => r.state == RoomState.current)
        .firstOrNull
        ?.mission;
    final interview = (await loadProgressionRecord(_ref)).interviewDate;
    return planReminders(
      now: now,
      enabled: enabled,
      recallDue: (day) =>
          schedule.cards.where((c) => !_dayOf(day).isBefore(c.due)).length,
      interviewDate: interview == null
          ? null
          : DateTime(interview.year, interview.month, interview.day),
      nextMission: next == null
          ? null
          : NextMission(
              number: next.number,
              interviewerId: next.question.speakerId,
            ),
    );
  }

  /// Cancels what was scheduled and schedules the next week (on every open and every close).
  Future<void> reschedule() async {
    if (!_supported) return;
    try {
      final settings = _ref.read(reminderSettingsProvider.notifier);
      await settings.loaded;
      final enabled = _ref.read(reminderSettingsProvider).enabled;
      await _scheduler.replace(await plan(enabled: enabled));
    } on Object catch (e) {
      _warn('reminders not scheduled', e);
    }
  }

  /// Whether the phone lets the game post notifications now (false on the web, or on error).
  Future<bool> hasPermission() async {
    if (!_supported) return false;
    try {
      return await _scheduler.hasPermission();
    } on Object catch (e) {
      _warn('reminder permission unknown', e);
      return false;
    }
  }

  /// "Send a test reminder" (brief 42): tomorrow's real reminder, shown now, so the player sees
  /// what will arrive and that a tap opens it. Permission is the caller's to ask for first,
  /// behind the explainer. Planned as if reminders were on, so it works with the switch off.
  Future<TestReminderResult> sendTest() async {
    if (!_supported) return TestReminderResult.unsupported;
    try {
      final next = (await plan(enabled: true)).firstOrNull;
      if (next == null) return TestReminderResult.nothingPlanned;
      await _scheduler.show(next);
      _ref.read(analyticsProvider).track(AnalyticsEvent.testReminderSent, {
        'type': EventValue.name(next.kind),
      });
      return TestReminderResult.sent;
    } on Object catch (e) {
      _warn('test reminder not shown', e);
      return TestReminderResult.failed;
    }
  }

  /// The next reminder, or why there is none: the web, the switch off, the phone blocking them,
  /// or nothing to remind the player of.
  Future<ReminderOutlook> outlook() async {
    if (!_supported) return const ReminderOutlook.quiet(ReminderQuiet.web);
    await _ref.read(reminderSettingsProvider.notifier).loaded;
    if (!_ref.read(reminderSettingsProvider).enabled) {
      return const ReminderOutlook.quiet(ReminderQuiet.off);
    }
    if (!await hasPermission()) {
      return const ReminderOutlook.quiet(ReminderQuiet.blocked);
    }
    try {
      final next = (await plan(enabled: true)).firstOrNull;
      return next == null
          ? const ReminderOutlook.quiet(ReminderQuiet.nothingPlanned)
          : ReminderOutlook.next(next);
    } on Object catch (e) {
      _warn('next reminder unknown', e);
      return const ReminderOutlook.quiet(ReminderQuiet.nothingPlanned);
    }
  }

  /// The player said yes: ask the system, and switch reminders on if it allows them. Returns
  /// whether they're on.
  Future<bool> enable() async {
    if (!_supported) return false;
    final settings = _ref.read(reminderSettingsProvider.notifier);
    var granted = false;
    try {
      granted = await _scheduler.requestPermission();
    } on Object catch (e) {
      _warn('reminder permission failed', e);
    }
    if (granted) {
      _ref
          .read(analyticsProvider)
          .track(AnalyticsEvent.notificationPermissionGranted);
    }
    await settings.set(
      _ref
          .read(reminderSettingsProvider)
          .copyWith(enabled: granted, offered: true),
    );
    await reschedule();
    return granted;
  }

  /// Off: nothing more is sent.
  Future<void> disable() async {
    final settings = _ref.read(reminderSettingsProvider.notifier);
    await settings.set(
      _ref.read(reminderSettingsProvider).copyWith(enabled: false),
    );
    try {
      await _scheduler.replace(const []);
    } on Object catch (e) {
      _warn('reminders not cancelled', e);
    }
  }

  /// The explainer was shown (and answered "Not now"): never shown again.
  Future<void> markOffered() async {
    final settings = _ref.read(reminderSettingsProvider.notifier);
    await settings.set(
      _ref.read(reminderSettingsProvider).copyWith(offered: true),
    );
  }

  /// A reminder was tapped: report it, then open where it points.
  void open(String payload) {
    final reminder = decodeReminderPayload(payload);
    if (reminder == null) return;
    _ref.read(analyticsProvider).track(AnalyticsEvent.notificationOpened, {
      'type': EventValue.name(reminder.kind),
      'variant': EventValue.count(reminder.variant),
    });
    _ref.read(routerProvider).go(reminderRoute(reminder.missionNumber));
  }

  void _warn(String message, Object e) =>
      _ref.read(logProvider).warn(message, {'error': e.runtimeType.toString()});

  static CalendarDay _dayOf(DateTime t) => CalendarDay(t.year, t.month, t.day);
}

/// Where a tapped reminder opens: the mission it nudges about, or the Recall Room. Both are the
/// tower's children, so back returns to the tower.
String reminderRoute(int? missionNumber) =>
    missionNumber == null ? Routes.recall : Routes.mission(missionNumber);

/// Sets reminders up at launch (`main.dart`), without holding up the first frame: the plugin,
/// a tap that launched the app, and a fresh plan now and whenever the app is hidden.
void startReminders(ProviderContainer container) {
  if (!remindersSupported) return;
  final reminders = container.read(remindersProvider);
  final scheduler = container.read(reminderSchedulerProvider);
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await scheduler.init(onTap: reminders.open);
      final launched = await scheduler.launchPayload();
      if (launched != null) reminders.open(launched);
    } on Object catch (e) {
      container.read(logProvider).warn('reminders unavailable', {
        'error': e.runtimeType.toString(),
      });
      return;
    }
    await reminders.reschedule();
  });
  // Lives as long as the app (ADR 0004: re-plan on every close too).
  AppLifecycleListener(onHide: () => unawaited(reminders.reschedule()));
}
