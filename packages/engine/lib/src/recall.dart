import 'beat.dart';
import 'calendar_day.dart';

/// The Leitner boxes of the Recall Room (FR-40): a card in a box is due that many days after
/// it was last answered.
enum LeitnerBox {
  one(intervalDays: 1),
  three(intervalDays: 3),
  seven(intervalDays: 7);

  const LeitnerBox({required this.intervalDays});

  final int intervalDays;
}

/// A mistake the player made, waiting in the Recall Room.
class RecallCard {
  const RecallCard({
    required this.cardId,
    required this.box,
    required this.due,
  });

  /// What the card asks about: the content id of the misconception the player fell for (a
  /// `Reason`) or of a lesson they missed. The engine never sees the words.
  final String cardId;
  final LeitnerBox box;
  final CalendarDay due;

  @override
  bool operator ==(Object other) =>
      other is RecallCard &&
      other.cardId == cardId &&
      other.box == box &&
      other.due == due;

  @override
  int get hashCode => Object.hash(cardId, box, due);

  @override
  String toString() => 'RecallCard($cardId, ${box.name}, due $due)';
}

/// How one recall answer counts.
enum RecallVerdict {
  /// Right, after reading: the card moves up a box.
  known,

  /// Right, but faster than anyone can read the choices ([isGuess]): luck, so the card stays in
  /// its box and comes back tomorrow.
  guessed,

  /// Wrong: the card starts over in box one.
  missed,
}

/// What reviewing a card did to it.
sealed class RecallOutcome {
  const RecallOutcome(this.verdict);

  /// How the answer was judged, for the round's streak and the card's animation.
  final RecallVerdict verdict;
}

/// The card stays in the Recall Room, in a box with a new due day.
final class Rescheduled extends RecallOutcome {
  const Rescheduled(this.card, super.verdict);

  final RecallCard card;
}

/// Known from the last box: the lesson has stuck, and the card leaves.
final class Retired extends RecallOutcome {
  const Retired(this.cardId) : super(RecallVerdict.known);

  final String cardId;
}

/// Judges one answer: wrong is [RecallVerdict.missed] however long it took; right is
/// [RecallVerdict.known] unless it was a guess. The same 1.5 s rule as a mission beat
/// ([guessThreshold]); the player measures [decidedIn], the engine never reads a clock.
RecallVerdict judgeRecall({required bool correct, Duration? decidedIn}) {
  if (!correct) return RecallVerdict.missed;
  return isGuess(decidedIn) ? RecallVerdict.guessed : RecallVerdict.known;
}

/// A new card for a mistake made [today]: box one, due **today**, so the room has something to
/// practise straight after the mission while it's fresh. From the first answer on, the boxes'
/// intervals apply.
RecallCard newRecallCard(String cardId, {required CalendarDay today}) =>
    RecallCard(cardId: cardId, box: LeitnerBox.one, due: today);

RecallCard _inBox(
  String cardId,
  LeitnerBox box, {
  required CalendarDay today,
}) =>
    RecallCard(cardId: cardId, box: box, due: today.addDays(box.intervalDays));

/// Reviews [card] on [today].
///
/// - **Known** (right, after reading): up a box (one → three → seven), due that box's interval
///   from today; known from box seven retires the card.
/// - **Guessed** (right, under 1.5 s): stays in its box, due tomorrow. A lucky tap teaches
///   nothing, so it neither promotes nor punishes.
/// - **Missed** (wrong): back to box one, due tomorrow. Leitner's rule: a missed lesson starts
///   over, a known one is seen less and less.
RecallOutcome reviewRecallCard(
  RecallCard card, {
  required bool correct,
  required CalendarDay today,
  Duration? decidedIn,
}) {
  final verdict = judgeRecall(correct: correct, decidedIn: decidedIn);
  switch (verdict) {
    case RecallVerdict.missed:
      return Rescheduled(
        _inBox(card.cardId, LeitnerBox.one, today: today),
        verdict,
      );
    case RecallVerdict.guessed:
      return Rescheduled(
        RecallCard(cardId: card.cardId, box: card.box, due: today.addDays(1)),
        verdict,
      );
    case RecallVerdict.known:
      final next = card.box.index + 1;
      if (next == LeitnerBox.values.length) return Retired(card.cardId);
      return Rescheduled(
        _inBox(card.cardId, LeitnerBox.values[next], today: today),
        verdict,
      );
  }
}

/// [cards] after a mission in which the player made the mistakes [missedCardIds] on [today].
///
/// A mistake with no card gets a new one ([newRecallCard]); one already in the room goes back
/// to box one, due today at the latest (making it again means it hadn't stuck). Every other card
/// is untouched. The order is stable: existing cards first, as they were, then new ones in the
/// order they were missed.
List<RecallCard> withMissedCards(
  List<RecallCard> cards,
  Iterable<String> missedCardIds, {
  required CalendarDay today,
}) {
  final missed = missedCardIds.toSet();
  final existing = {for (final c in cards) c.cardId};
  return [
    for (final c in cards)
      if (missed.contains(c.cardId))
        RecallCard(
          cardId: c.cardId,
          box: LeitnerBox.one,
          due: c.due.isBefore(today) ? c.due : today,
        )
      else
        c,
    for (final id in missed)
      if (!existing.contains(id)) newRecallCard(id, today: today),
  ];
}

/// The cards due on or before [today], most overdue first, then lowest box first (the
/// shakiest lessons), then by card id so the order is stable. At most [limit] of them: a round
/// is a one-minute warm-up, not a backlog.
List<RecallCard> dueRecallCards(
  List<RecallCard> cards, {
  required CalendarDay today,
  int limit = recallSessionCardLimit,
}) {
  RangeError.checkNotNegative(limit, 'limit');
  final due = cards.where((c) => !today.isBefore(c.due)).toList()
    ..sort((a, b) {
      final byDue = a.due.compareTo(b.due);
      if (byDue != 0) return byDue;
      final byBox = a.box.index.compareTo(b.box.index);
      return byBox != 0 ? byBox : a.cardId.compareTo(b.cardId);
    });
  return due.take(limit).toList();
}

/// The current run of [RecallVerdict.known] answers at the end of [verdicts]: the round's
/// streak. A guess or a miss breaks it.
int recallStreak(List<RecallVerdict> verdicts) {
  var streak = 0;
  for (final v in verdicts.reversed) {
    if (v != RecallVerdict.known) break;
    streak++;
  }
  return streak;
}

/// Cards per Recall Room round. About 12 seconds a card keeps a round near one minute
/// (brief 21).
const int recallSessionCardLimit = 5;
