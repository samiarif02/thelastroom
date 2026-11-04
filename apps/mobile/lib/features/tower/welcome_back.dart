import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/notifications/reminder_copy.dart';
import '../progression/progression.dart';
import '../progression/progression_card.dart';
import 'tower_rooms.dart';

/// Calendar days between the player's last visit and [now]: 0 the same day, 1 the next, null
/// for a first visit. Calendar days, not 24-hour spans: last night and this morning is a return.
int? daysAway(DateTime? lastVisit, DateTime now) {
  if (lastVisit == null) return null;
  return DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(lastVisit.year, lastVisit.month, lastVisit.day))
      .inDays;
}

/// Whether the tower greets the player back (brief 42): only after a day or more away. Never on
/// a first visit, never twice the same day, and never if the clock went backwards.
bool welcomesBack(int? away) => away != null && away >= 1;

/// Where the card's one button goes.
enum WelcomeBackTarget { recall, mission, progress }

/// What a "waiting" line is about, so the card can give it its icon.
enum WaitingKind { recall, room, week, interview }

/// What the card says and where its button goes, in the voice of the next room's interviewer.
class WelcomeBack {
  const WelcomeBack({
    required this.interviewerId,
    required this.waiting,
    required this.target,
    this.kinds = const [],
    this.missionNumber,
  });

  final String interviewerId;

  /// What's waiting, one line each: cards due, the next room, the week so far.
  final List<String> waiting;

  /// What each of [waiting] is about, line for line.
  final List<WaitingKind> kinds;
  final WelcomeBackTarget target;

  /// The room the button starts, when [target] is a mission.
  final int? missionNumber;

  String get speaker =>
      ReminderCopy.name(interviewerId) ?? ReminderCopy.company;

  String get kicker => 'Welcome back · $speaker';

  /// Glad to see them; never a count of the days they were gone, never a guilt trip.
  String get greeting => switch (interviewerId) {
    'marcus' => "Good, you're back. Here's where things stand.",
    'lena' => 'Welcome back. I kept your file open.',
    'sam' => 'You came back. That is what counts. Here is what is next.',
    _ => "Good to see you again. Here's what's waiting.",
  };

  /// A day with nothing due: when the next note comes back ("on Friday", "tomorrow").
  static String nextNoteLine(String when) =>
      'Your next Recall note comes back $when.';

  /// The interview countdown (FR-4), as the day-5 hook in direction.md puts it.
  static String interviewLine(int days) => switch (days) {
    0 => 'Interview day. One room makes a good warm-up.',
    1 => 'Your interview is tomorrow. One room makes a good warm-up.',
    _ => 'Interview in $days days. One room makes a good warm-up.',
  };

  String get action => switch (target) {
    WelcomeBackTarget.recall => 'Open the Recall Room',
    WelcomeBackTarget.mission => 'Start room $missionNumber',
    WelcomeBackTarget.progress => 'See your file',
  };
}

/// The card's content from what the tower already knows. Cards due come first (a minute, and
/// the memory is fading); then the next room; with neither, the player's file.
///
/// Brief 61 (what brings them back on day 3 and day 7): with nothing due today, [nextNote] says
/// when the next note comes back ("on Friday"); with an interview date ahead, [interviewIn]
/// (days from today) counts down to it.
WelcomeBack welcomeBackFor({
  required int recallDue,
  required TowerRoom? next,
  required Progression progress,
  String? nextNote,
  int? interviewIn,
}) {
  final mission = next?.mission;
  final noteLater = recallDue == 0 && nextNote != null;
  final countdown = interviewIn != null && interviewIn >= 0;
  return WelcomeBack(
    interviewerId: mission?.question.speakerId ?? _host,
    waiting: [
      if (recallDue > 0) ReminderCopy.recallBody(recallDue, 0),
      if (noteLater) WelcomeBack.nextNoteLine(nextNote),
      if (countdown) WelcomeBack.interviewLine(interviewIn),
      if (next != null && mission != null)
        next.state == RoomState.current
            ? 'Room ${mission.number}, “${mission.title}”, is ready for you.'
            : 'Every room is open. Room ${mission.number}, “${mission.title}”, '
                  'is your best one to beat.',
      ProgressionCard.weekLine(progress.sessionsThisWeek, progress.weeklyGoal),
    ],
    kinds: [
      if (recallDue > 0) WaitingKind.recall,
      if (noteLater) WaitingKind.recall,
      if (countdown) WaitingKind.interview,
      if (next != null && mission != null) WaitingKind.room,
      WaitingKind.week,
    ],
    target: recallDue > 0
        ? WelcomeBackTarget.recall
        : mission != null
        ? WelcomeBackTarget.mission
        : WelcomeBackTarget.progress,
    missionNumber: mission?.number,
  );
}

/// Who greets the player when no room names an interviewer: the lobby's.
const String _host = 'priya';

/// When the player was last here, on the device.
abstract interface class LastVisitStore {
  Future<DateTime?> load();
  Future<void> save(DateTime at);
}

class SharedPreferencesLastVisitStore implements LastVisitStore {
  const SharedPreferencesLastVisitStore();

  static const String key = 'tower.lastVisit';

  @override
  Future<DateTime?> load() async {
    final ms = (await SharedPreferences.getInstance()).getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> save(DateTime at) async =>
      (await SharedPreferences.getInstance()).setInt(
        key,
        at.millisecondsSinceEpoch,
      );
}

final lastVisitStoreProvider = Provider<LastVisitStore>(
  (ref) => const SharedPreferencesLastVisitStore(),
);

/// The device's clock for the welcome. Tests pin it.
final welcomeBackClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The days the player was away while the welcome-back card is up; null when it isn't. Lives
/// as long as the app, so the card survives the tower rebuilding and shows once per return.
final welcomeBackProvider = NotifierProvider<WelcomeBackController, int?>(
  WelcomeBackController.new,
);

class WelcomeBackController extends Notifier<int?> {
  Future<void>? _arriving;
  bool _announced = false;

  @override
  int? build() => null;

  /// The player is on the tower (it opened, or the app came back to the front): greet them if
  /// they were away a day or more, unless [quiet] (back from a mission, so they never left),
  /// and remember this visit either way.
  Future<void> arrive({bool quiet = false}) =>
      _arriving ??= _arrive(quiet).whenComplete(() => _arriving = null);

  Future<void> _arrive(bool quiet) async {
    final now = ref.read(welcomeBackClockProvider)();
    final store = ref.read(lastVisitStoreProvider);
    try {
      final away = daysAway(await store.load(), now);
      if (!ref.mounted) return;
      if (!quiet && welcomesBack(away)) {
        _announced = false;
        state = away;
      }
      await store.save(now);
    } on Object catch (e) {
      _warn('last visit not read', e);
    }
  }

  /// The app went to the background: the visit ends now, not when it began.
  Future<void> leave() async {
    try {
      await ref
          .read(lastVisitStoreProvider)
          .save(ref.read(welcomeBackClockProvider)());
    } on Object catch (e) {
      _warn('last visit not saved', e);
    }
  }

  /// The card is on screen with [target] on its button: reported once per return.
  void shown(WelcomeBackTarget target) {
    final away = state;
    if (_announced || away == null) return;
    _announced = true;
    ref.read(analyticsProvider).track(AnalyticsEvent.welcomeBackShown, {
      'days_away': EventValue.count(away),
      'target': EventValue.name(target),
    });
  }

  /// The card goes: its button was [followed], or it was dismissed.
  void close(WelcomeBackTarget target, {required bool followed}) {
    if (state == null) return;
    state = null;
    ref.read(analyticsProvider).track(AnalyticsEvent.welcomeBackClosed, {
      'action': EventValue.name(
        followed ? WelcomeBackClose.followed : WelcomeBackClose.dismissed,
      ),
      'target': EventValue.name(target),
    });
  }

  void _warn(String message, Object e) {
    if (!ref.mounted) return;
    ref.read(logProvider).warn(message, {'error': e.runtimeType.toString()});
  }
}

/// `welcome_back_closed`'s `action`.
enum WelcomeBackClose { followed, dismissed }
