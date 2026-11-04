import 'calendar_day.dart';
import 'recall.dart';

/// What the debrief promises at the end of a room (brief 61, direction.md "Reward and
/// retention": the **dated promise**). A real date from the Recall Room's Leitner schedule, or,
/// with nothing to bring back, the next room. Every promise also carries [nextRoom], so the card
/// can say what opens now.
sealed class RoomPromise {
  const RoomPromise({this.nextRoom});

  /// The campaign number of the room to play next; null when every room is done.
  final int? nextRoom;
}

/// Notes come back on [day]: the first day from tomorrow on with a note due, which is the day
/// the reminder plan first counts them ([nextRecallDay]).
final class RecallPromise extends RoomPromise {
  const RecallPromise({
    required this.day,
    required this.daysAhead,
    required this.notes,
    required this.fromThisRoom,
    super.nextRoom,
  });

  final CalendarDay day;

  /// Whole days from today to [day]: 1 is tomorrow, never 0 (a reminder is never today).
  final int daysAhead;

  /// How many notes are due by [day]: this room's when [fromThisRoom], else every note.
  final int notes;

  /// The notes are this room's lines ("this line"); false for notes from earlier rooms, promised
  /// when this room left none and every room is done.
  final bool fromThisRoom;

  @override
  bool operator ==(Object other) =>
      other is RecallPromise &&
      other.day == day &&
      other.daysAhead == daysAhead &&
      other.notes == notes &&
      other.fromThisRoom == fromThisRoom &&
      other.nextRoom == nextRoom;

  @override
  int get hashCode =>
      Object.hash(day, daysAhead, notes, fromThisRoom, nextRoom);

  @override
  String toString() =>
      'RecallPromise($day, +$daysAhead, $notes notes, '
      'this room: $fromThisRoom, next room: $nextRoom)';
}

/// Nothing from this room to bring back: the promise is the next room ([nextRoom]), or, with
/// every room done and no notes waiting, a quiet "every room is done".
final class NextRoomPromise extends RoomPromise {
  const NextRoomPromise({super.nextRoom});

  @override
  bool operator ==(Object other) =>
      other is NextRoomPromise && other.nextRoom == nextRoom;

  @override
  int get hashCode => nextRoom.hashCode;

  @override
  String toString() => 'NextRoomPromise(next room: $nextRoom)';
}

/// The first day from tomorrow on when a note of [cards] is due, or null with no cards.
///
/// From tomorrow, because the reminders never come today (the player is here now): a note due
/// today, or already overdue, is still due tomorrow if it isn't practised, so tomorrow is when
/// it comes back. The reminder plan counts a day's notes the same way (every card due on or
/// before that day), so on this day it counts at least one.
CalendarDay? nextRecallDay(
  Iterable<RecallCard> cards, {
  required CalendarDay today,
}) {
  CalendarDay? earliest;
  for (final c in cards) {
    if (earliest == null || c.due.isBefore(earliest)) earliest = c.due;
  }
  if (earliest == null) return null;
  final tomorrow = today.addDays(1);
  return earliest.isBefore(tomorrow) ? tomorrow : earliest;
}

/// How many of [cards] are due on or before [day]: what the Recall Room holds that day if
/// nothing is practised before it, and what that day's reminder counts.
int notesDueBy(Iterable<RecallCard> cards, CalendarDay day) =>
    cards.where((c) => !day.isBefore(c.due)).length;

/// The promise after a room finished on [today].
///
/// [cards] is the Recall Room's schedule once the room's attempt is in it, and [roomCardIds]
/// the cards that attempt earned (its mistakes). [nextRoom] is the room to play next, if any.
///
/// - The room left notes: they come back on [nextRecallDay] of those notes ("Priya will bring
///   this line back tomorrow").
/// - It left none: the next room.
/// - It left none and every room is done, but earlier notes are waiting: when they come back.
/// - Nothing at all: [NextRoomPromise] with no room.
RoomPromise promiseAfterRoom({
  required List<RecallCard> cards,
  required Iterable<String> roomCardIds,
  required CalendarDay today,
  int? nextRoom,
}) {
  final ids = roomCardIds.toSet();
  final fromRoom = [
    for (final c in cards)
      if (ids.contains(c.cardId)) c,
  ];
  final fromThisRoom = fromRoom.isNotEmpty;
  final promised = fromThisRoom ? fromRoom : (nextRoom == null ? cards : null);
  final day = promised == null ? null : nextRecallDay(promised, today: today);
  if (promised == null || day == null) {
    return NextRoomPromise(nextRoom: nextRoom);
  }
  return RecallPromise(
    day: day,
    daysAhead: today.daysUntil(day),
    notes: notesDueBy(promised, day),
    fromThisRoom: fromThisRoom,
    nextRoom: nextRoom,
  );
}
