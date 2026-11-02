import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_plan.dart';

/// What the reminders need from the platform: `flutter_local_notifications` in the app, a fake
/// in tests. Every call may fail (no permission, an old OS); callers log and carry on.
abstract interface class ReminderScheduler {
  /// Sets up the plugin; [onTap] gets the tapped reminder's payload while the app runs.
  Future<void> init({required void Function(String payload) onTap});

  /// The payload of the reminder that launched the app, if one did.
  Future<String?> launchPayload();

  /// Asks the system (Android 13+ `POST_NOTIFICATIONS`, iOS alerts). True when allowed.
  Future<bool> requestPermission();

  /// Whether the system lets the game post notifications right now, without asking (the player
  /// can revoke it in the phone's settings at any time).
  Future<bool> hasPermission();

  /// Cancels every scheduled reminder and schedules [plan] instead. A reminder already in the
  /// notification shade (a delivered one, or a test) stays there.
  Future<void> replace(List<PlannedReminder> plan);

  /// Shows [reminder] now, as the test reminder (brief 42): its own id, so a re-plan never
  /// replaces it, and the same payload, so a tap goes where the real one would.
  Future<void> show(PlannedReminder reminder);
}

/// The test reminder's notification id: plan ids are their days (1 and up), so 0 is free.
const int testReminderId = 0;

/// The payload a reminder carries, so a tap knows where to go and what to report:
/// `recallDue:<variant>` or `nudge:<variant>:<mission number>`.
String encodeReminderPayload(PlannedReminder r) =>
    [r.kind.name, r.variant, ?r.missionNumber].join(_separator);

/// The parts of a payload, or null if it isn't one of ours.
({ReminderKind kind, int variant, int? missionNumber})? decodeReminderPayload(
  String payload,
) {
  final parts = payload.split(_separator);
  final kind = ReminderKind.values
      .where((k) => k.name == parts.first)
      .firstOrNull;
  final variant = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (kind == null || variant == null) return null;
  final mission = parts.length > 2 ? int.tryParse(parts[2]) : null;
  if (kind == ReminderKind.nudge && mission == null) return null;
  return (kind: kind, variant: variant, missionNumber: mission);
}

const String _separator = ':';

/// [ReminderScheduler] on `flutter_local_notifications`. Inexact delivery on Android, so no
/// exact-alarm permission is needed (ADR 0004); the times are absolute instants, so no time
/// zone database is loaded.
class LocalNotificationsScheduler implements ReminderScheduler {
  LocalNotificationsScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDescription =
      'The Recall Room and your next interview, at most once a day.';
  static const String _icon = '@mipmap/ic_launcher';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init({required void Function(String payload) onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        // The permission is asked at the designed moment, never at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) onTap(payload);
      },
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(alert: true, sound: true) ?? false;
      default:
        return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.areNotificationsEnabled() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final options = await ios?.checkPermissions();
        return options?.isEnabled ?? false;
      default:
        return false;
    }
  }

  @override
  Future<void> show(PlannedReminder reminder) => _plugin.show(
    id: testReminderId,
    title: reminder.title,
    body: reminder.body,
    notificationDetails: _details,
    payload: encodeReminderPayload(reminder),
  );

  @override
  Future<void> replace(List<PlannedReminder> plan) async {
    // Pending only: `cancelAll` would also clear the shade, so a test reminder (or yesterday's,
    // unread) vanished the moment the app was hidden and re-planned.
    await _plugin.cancelAllPendingNotifications();
    for (final r in plan) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: encodeReminderPayload(r),
      );
    }
  }
}
