import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/notifications/reminder_primer.dart';
import '../../core/progress/progress_repository.dart';
import '../../ui/haptics.dart';
import '../mission/mission_lookup.dart';
import '../recall/recall_controller.dart';
import '../recall/recall_store.dart';
import '../tower/tower_rooms.dart';
import 'first_day_moment.dart';
import 'progression.dart';

/// Whether the first-day moment has been shown, on the device. Shown once, ever.
abstract interface class FirstDayStore {
  Future<bool> shown();
  Future<void> markShown();
}

class SharedPreferencesFirstDayStore implements FirstDayStore {
  const SharedPreferencesFirstDayStore();

  static const String key = 'firstDay.shown';

  @override
  Future<bool> shown() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;

  @override
  Future<void> markShown() async =>
      (await SharedPreferences.getInstance()).setBool(key, true);
}

final firstDayStoreProvider = Provider<FirstDayStore>(
  (ref) => const SharedPreferencesFirstDayStore(),
);

/// What the first-day moment shows: the week so far, what the room earned, and tomorrow.
class FirstDay {
  const FirstDay({
    required this.room,
    required this.sessions,
    required this.weeklyGoal,
    required this.xp,
    required this.notesTomorrow,
    this.skill,
    this.nextRoom,
  });

  /// The room just finished, whose interviewer speaks.
  final Mission room;

  /// The weekly ring: its first segment, out of the goal.
  final int sessions;
  final int weeklyGoal;
  final int xp;

  /// A skill the room unlocked, if it did.
  final Skill? skill;

  /// Recall notes due by tomorrow (the engine's [notesDueBy]: the same count the first
  /// reminder will give).
  final int notesTomorrow;
  final Mission? nextRoom;

  /// "Your first Recall note, about a minute, plus room 2." The concrete hook for tomorrow.
  String get tomorrow {
    final next = nextRoom;
    if (notesTomorrow > 0) {
      final notes = notesTomorrow == 1
          ? 'Your first Recall note'
          : 'Your first $notesTomorrow Recall notes';
      final minutes = recallMinutes(notesTomorrow);
      final time = minutes <= 1 ? 'about a minute' : 'about $minutes minutes';
      return next == null
          ? '$notes, $time.'
          : '$notes, $time, plus room ${next.number}.';
    }
    if (next != null) return 'Room ${next.number}, with ${next.lead.name}.';
    return 'Any room, any time: your file keeps every one.';
  }

  static const String kicker = 'Room 1 is lit';
  static const String title = 'Day 1 of your prep';
  static const String tomorrowKicker = 'Tomorrow';
  static const String done = 'See you tomorrow';

  /// The host's line: glad, and no pressure. The ring is weekly, so a missed day costs nothing.
  static String line(int goal) =>
      'The hardest part is done: you started. Any $goal days this week '
      'close your ring, so there is nothing to lose by taking a day off.';

  static String week(int sessions, int goal) => '$sessions of $goal this week';
}

/// The first-day moment's facts, or null when it isn't due: already shown, or this isn't the
/// player's first finished room ever (a player from before the moment existed never sees it).
/// Nothing here throws: a store that can't be read means no moment.
Future<FirstDay?> firstDayDue(WidgetRef ref, Mission room) async {
  try {
    if (await ref.read(firstDayStoreProvider).shown()) return null;
    final progress = ref.read(progressRepositoryProvider);
    final attempts = await progress.attempts();
    if (attempts.length != 1 || attempts.single.missionId != room.id) {
      return null;
    }
    final now = ref.read(recallClockProvider)();
    final today = CalendarDay(now.year, now.month, now.day);
    final schedule = await syncRecallSchedule(
      store: ref.read(recallStoreProvider),
      progress: progress,
      deck: ref.read(recallDeckProvider),
      today: today,
    );
    final p = await ref.read(progressionProvider.future);
    return FirstDay(
      room: room,
      sessions: p.sessionsThisWeek,
      weeklyGoal: p.weeklyGoal,
      xp: p.lastXp,
      skill: p.unlocked.firstOrNull,
      notesTomorrow: notesDueBy(schedule.cards, today.addDays(1)),
      nextRoom: towerRooms(
        missions,
        attempts,
      ).where((r) => r.state == RoomState.current).firstOrNull?.mission,
    );
  } on Object catch (e) {
    ref.read(logProvider).warn('first day not shown', {
      'error': e.runtimeType.toString(),
    });
    return null;
  }
}

/// Back on the tower after the player's first finished room ever (brief 61): the first-day
/// moment, once, then the reminder explainer ([offerReminders], which asks only if reminders
/// were never offered, and never on the web). The moment is the reason to come back tomorrow;
/// the explainer is how tomorrow reaches them.
Future<void> offerFirstDay(
  BuildContext context,
  WidgetRef ref,
  Mission room,
) async {
  final day = await firstDayDue(ref, room);
  if (day == null) {
    if (context.mounted) await offerReminders(context, ref);
    return;
  }
  // Let the room light up and its notice land first, as the explainer always has.
  await Future<void>.delayed(ReminderPrimer.settle);
  if (!context.mounted) return;
  // Marked before it's up: a phone killed mid-moment never shows it twice.
  try {
    await ref.read(firstDayStoreProvider).markShown();
  } on Object catch (e) {
    ref.read(logProvider).warn('first day flag not saved', {
      'error': e.runtimeType.toString(),
    });
  }
  if (!context.mounted) return;
  ref.read(analyticsProvider).track(AnalyticsEvent.firstDayShown, {
    'recall_tomorrow': EventValue.flag(day.notesTomorrow > 0),
  });
  successTap();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: FirstDay.done,
    barrierColor: DaylightColors.ink.withValues(alpha: ReminderPrimer.scrim),
    transitionDuration: DaylightMotion.colour,
    pageBuilder: (dialogContext, _, _) => FirstDayMoment(
      day: day,
      onDone: () => Navigator.of(dialogContext).pop(),
    ),
  );
  if (context.mounted) await offerReminders(context, ref, settled: true);
}
