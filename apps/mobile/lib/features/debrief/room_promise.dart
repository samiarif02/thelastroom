import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/reminder_outlook.dart' show dayWords, fullDate;
import '../../core/progress/progress_repository.dart';
import '../mission/mission_lookup.dart';
import '../recall/recall_controller.dart';
import '../recall/recall_store.dart';
import '../tower/tower_rooms.dart';

/// The debrief's dated promise for one room, with what the card needs to say it.
class RoomPromiseReading {
  const RoomPromiseReading({
    required this.promise,
    required this.today,
    required this.opensNow,
  });

  final RoomPromise promise;
  final CalendarDay today;

  /// This attempt opened the next room (the room's first finish): "Room 4 opens now", rather
  /// than "Room 4 is next".
  final bool opensNow;
}

/// The promise after the latest attempt at [missionId] (brief 61): the engine's
/// [promiseAfterRoom] over the Recall Room's schedule, the very one the reminders plan from
/// (`syncRecallSchedule`), so the debrief, the Recall Room and tomorrow's notification name the
/// same day. Read once the attempt is stored (the debrief has settled).
final roomPromiseProvider = FutureProvider.autoDispose
    .family<RoomPromiseReading, String>((ref, missionId) async {
      final now = ref.read(recallClockProvider)();
      final today = CalendarDay(now.year, now.month, now.day);
      final progress = ref.read(progressRepositoryProvider);
      final deck = ref.read(recallDeckProvider);
      final schedule = await syncRecallSchedule(
        store: ref.read(recallStoreProvider),
        progress: progress,
        deck: deck,
        today: today,
      );
      final attempts = await progress.attempts();
      AttemptRecord? latest;
      for (final a in attempts) {
        if (a.missionId != missionId) continue;
        if (latest == null || a.attemptNumber >= latest.attemptNumber) {
          latest = a;
        }
      }
      final next = towerRooms(
        missions,
        attempts,
      ).where((r) => r.state == RoomState.current).firstOrNull?.mission;
      final room = missions.where((m) => m.id == missionId).firstOrNull;
      return RoomPromiseReading(
        promise: promiseAfterRoom(
          cards: schedule.cards,
          roomCardIds: latest == null ? const [] : deck.missedCardIds(latest),
          today: today,
          nextRoom: next?.number,
        ),
        today: today,
        opensNow:
            next != null &&
            room != null &&
            next.number == room.number + 1 &&
            latest?.attemptNumber == 1,
      );
    });

/// What the promise says, in the voice of whoever keeps it (brief 61). Plain words, a real day.
abstract final class PromiseCopy {
  /// "tomorrow", "on Friday", "on Tuesday 10 November".
  static String when(CalendarDay day, CalendarDay today) {
    final words = dayWords(_at(day), _at(today));
    return words == 'tomorrow' || words == 'today' ? words : 'on $words';
  }

  /// The kicker over a recall promise: the full date, so it reads as a date and not a mood.
  static String recallKicker(CalendarDay day) =>
      'Recall Room · ${fullDate(_at(day))}';

  static String nextKicker(int room) => 'Up next · room $room';
  static const String doneKicker = 'Every room played';

  /// "Priya will bring this line back tomorrow."
  static String recallHeadline(
    RecallPromise p, {
    required String keeper,
    required CalendarDay today,
  }) {
    final when = PromiseCopy.when(p.day, today);
    if (!p.fromThisRoom) {
      final notes = p.notes == 1 ? 'your note' : 'your ${p.notes} notes';
      return '$keeper will bring $notes back $when.';
    }
    final lines = p.notes == 1 ? 'this line' : 'these ${p.notes} lines';
    return '$keeper will bring $lines back $when.';
  }

  /// "Room 4 opens now." / "Room 4 is next." / with no room left, the last word.
  static String nextRoomLine(int? room, {required bool opensNow}) =>
      room == null
      ? 'That was the last room.'
      : opensNow
      ? 'Room $room opens now.'
      : 'Room $room is next.';

  /// A clean room: the next one, in its interviewer's voice.
  static String cleanDetail(String nextInterviewer) =>
      '$nextInterviewer has your next question. Nothing from this room needs '
      'another look.';

  static const String doneHeadline = 'Every room is done.';
  static const String doneDetail =
      'Nothing to bring back. Replay any room to beat your best.';

  static DateTime _at(CalendarDay d) => DateTime(d.year, d.month, d.day);
}

/// The next room's mission, for its interviewer's face and name.
Mission? promisedRoom(RoomPromise p) =>
    p.nextRoom == null ? null : missionByNumber(p.nextRoom!);
