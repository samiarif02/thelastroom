import 'calendar_day.dart';

/// The Leitner boxes of the Recall Room (FR-40): a card in a box is due that many days after
/// it was last seen.
enum LeitnerBox {
  one(intervalDays: 1),
  three(intervalDays: 3),
  seven(intervalDays: 7);

  const LeitnerBox({required this.intervalDays});

  final int intervalDays;
}

/// A lesson the player missed, waiting in the Recall Room.
class RecallCard {
  const RecallCard({
    required this.lessonId,
    required this.box,
    required this.due,
  });

  final String lessonId;
  final LeitnerBox box;
  final CalendarDay due;
}

/// What reviewing a card did to it.
sealed class RecallOutcome {
  const RecallOutcome();
}

/// The card stays in the Recall Room, in a new box with a new due day.
final class Rescheduled extends RecallOutcome {
  const Rescheduled(this.card);

  final RecallCard card;
}

/// Answered correctly from the last box: the lesson has stuck, and the card leaves.
final class Retired extends RecallOutcome {
  const Retired(this.lessonId);

  final String lessonId;
}

/// A new card for a lesson missed [today]: box one, due tomorrow.
RecallCard newRecallCard(String lessonId, {required CalendarDay today}) =>
    throw UnimplementedError();

/// Reviews [card] on [today].
///
/// Correct moves it up a box (one → three → seven) and due that box's interval from today;
/// correct from box seven retires it. Wrong sends it back to box one, due tomorrow. Leitner's
/// rule: a missed lesson starts over, a known one is seen less and less.
RecallOutcome reviewRecallCard(
  RecallCard card, {
  required bool correct,
  required CalendarDay today,
}) => throw UnimplementedError();

/// The cards due on or before [today], most overdue first, then lowest box first (the
/// shakiest lessons), then by lesson id so the order is stable. At most [limit] of them: the
/// Recall Room is a two-minute warm-up, not a backlog.
List<RecallCard> dueRecallCards(
  List<RecallCard> cards, {
  required CalendarDay today,
  int limit = recallSessionCardLimit,
}) => throw UnimplementedError();

/// Cards per Recall Room session. About 20 seconds a card keeps it near two minutes (FR-40).
const int recallSessionCardLimit = 6;
