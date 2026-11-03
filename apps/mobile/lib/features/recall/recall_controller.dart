import 'dart:async';
import 'dart:math' as math;

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/progress/progress_repository.dart';
import '../progression/progression.dart';
import 'recall_deck.dart';
import 'recall_store.dart';

/// The device's clock, read only here (the engine never reads one). Tests pin it.
final recallClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final recallDeckProvider = Provider<RecallDeck>(
  (ref) => RecallDeck(gameContent),
);

CalendarDay _dayOf(DateTime t) => CalendarDay(t.year, t.month, t.day);

/// Turns every stored attempt not yet seen into cards ([RecallDeck.missedCardIds]), saves, and
/// returns the schedule. Safe to call on every visit: an attempt is only ever counted once.
Future<RecallSchedule> syncRecallSchedule({
  required RecallStore store,
  required ProgressRepository progress,
  required RecallDeck deck,
  required CalendarDay today,
}) async {
  final schedule = await store.load();
  var cards = schedule.cards;
  final ingested = {...schedule.ingested};
  for (final attempt in await progress.attempts()) {
    final key = attemptKey(
      attempt.missionId,
      attempt.attemptNumber,
      attempt.attemptId,
    );
    if (!ingested.add(key)) continue;
    cards = withMissedCards(cards, deck.missedCardIds(attempt), today: today);
  }
  final synced = RecallSchedule(cards: cards, ingested: ingested);
  if (ingested.length != schedule.ingested.length) await store.save(synced);
  return synced;
}

/// About how long [due] notes take in the Recall Room: a minute for every two, never zero. The
/// tower's Recall card and the Recall tip both say it, so they never disagree (QA 51).
int recallMinutes(int due) => math.max(1, (due / _notesPerMinute).ceil());

const int _notesPerMinute = 2;

/// How many cards are due today, for the tower's Recall Room card. A store that can't be read
/// counts as none (the room says so when opened).
final recallDueCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final today = _dayOf(ref.watch(recallClockProvider)());
  try {
    final schedule = await syncRecallSchedule(
      store: ref.watch(recallStoreProvider),
      progress: ref.watch(progressRepositoryProvider),
      deck: ref.watch(recallDeckProvider),
      today: today,
    );
    return dueRecallCards(
      schedule.cards,
      today: today,
      limit: schedule.cards.length,
    ).length;
  } on FormatException catch (e) {
    ref.read(logProvider).warn('recall schedule unreadable', {
      'error': e.runtimeType.toString(),
    });
    return 0;
  }
});

/// One Recall Room round.
sealed class RecallRoomState {
  const RecallRoomState();
}

final class RecallLoading extends RecallRoomState {
  const RecallLoading();
}

/// Nothing due: every card is scheduled for later, or there are none yet.
final class RecallEmpty extends RecallRoomState {
  const RecallEmpty({required this.hasCards, this.nextDue});

  /// False before the first mission with a mistake: the room explains where cards come from.
  final bool hasCards;

  /// When the next note comes back; null with none scheduled.
  final CalendarDay? nextDue;
}

final class RecallPlaying extends RecallRoomState {
  const RecallPlaying({
    required this.round,
    required this.index,
    required this.verdicts,
    this.chosenId,
    this.boxes = const [],
  });

  final List<RecallQuestion> round;

  /// Each card's Leitner box, card for card with [round] (empty in older callers).
  final List<LeitnerBox> boxes;
  final int index;

  /// One per answered card, in order.
  final List<RecallVerdict> verdicts;

  /// The choice picked on the current card; null while the player is still deciding.
  final String? chosenId;

  RecallQuestion get question => round[index];

  /// The current card's box; null when unknown.
  LeitnerBox? get box => index < boxes.length ? boxes[index] : null;
  bool get answered => chosenId != null;
  RecallVerdict? get verdict => answered ? verdicts.last : null;
  int get streak => recallStreak(verdicts);

  /// 0–1: cards answered out of the round.
  double get progress => verdicts.length / round.length;
}

final class RecallFinished extends RecallRoomState {
  const RecallFinished({required this.verdicts});

  final List<RecallVerdict> verdicts;

  int get known => verdicts.where((v) => v == RecallVerdict.known).length;
  int get bestStreak {
    var best = 0;
    for (var i = 1; i <= verdicts.length; i++) {
      final s = recallStreak(verdicts.sublist(0, i));
      if (s > best) best = s;
    }
    return best;
  }
}

/// The room could not load its schedule; the game goes on, and the room can try again.
final class RecallUnavailable extends RecallRoomState {
  const RecallUnavailable();
}

final recallRoomProvider =
    NotifierProvider.autoDispose<RecallRoomController, RecallRoomState>(
      RecallRoomController.new,
    );

/// Runs a round: up to five due cards, each answered by one tap, timed like a mission beat.
class RecallRoomController extends Notifier<RecallRoomState> {
  RecallSchedule _schedule = RecallSchedule.empty;
  DateTime? _shownAt;
  int _boxMoves = 0;

  DateTime _now() => ref.read(recallClockProvider)();
  CalendarDay get _today => _dayOf(_now());

  @override
  RecallRoomState build() {
    unawaited(_start());
    return const RecallLoading();
  }

  Future<void> _start() async {
    final today = _today;
    try {
      _schedule = await syncRecallSchedule(
        store: ref.read(recallStoreProvider),
        progress: ref.read(progressRepositoryProvider),
        deck: ref.read(recallDeckProvider),
        today: today,
      );
    } on Object catch (e) {
      ref.read(logProvider).warn('recall room unavailable', {
        'error': e.runtimeType.toString(),
      });
      if (ref.mounted) state = const RecallUnavailable();
      return;
    }
    if (!ref.mounted) return;
    final deck = ref.read(recallDeckProvider);
    final seed = _seedFor(today);
    final due = [
      for (final card in dueRecallCards(_schedule.cards, today: today))
        if (deck.question(card.cardId, seed: seed) case final q?) (q, card.box),
    ];
    final round = [for (final (q, _) in due) q];
    ref.read(analyticsProvider).track(AnalyticsEvent.recallRoomOpened, {
      'due_cards': EventValue.count(round.length),
    });
    if (round.isEmpty) {
      CalendarDay? next;
      for (final c in _schedule.cards) {
        if (next == null || c.due.compareTo(next) < 0) next = c.due;
      }
      state = RecallEmpty(hasCards: _schedule.cards.isNotEmpty, nextDue: next);
      return;
    }
    _shownAt = _now();
    state = RecallPlaying(
      round: round,
      index: 0,
      verdicts: const [],
      boxes: [for (final (_, b) in due) b],
    );
    _noteOpened(state);
  }

  /// `recall_note_opened`: a note is on screen (once per card per round).
  void _noteOpened(RecallRoomState s) {
    if (s is! RecallPlaying) return;
    final box = s.box;
    ref.read(analyticsProvider).track(AnalyticsEvent.recallNoteOpened, {
      'card_kind': EventValue.name(s.question.kind),
      if (box != null) 'box': EventValue.name(box),
    });
  }

  /// The player taps [choiceId] on the current card. A second tap is ignored.
  Future<void> answer(String choiceId) async {
    final s = state;
    if (s is! RecallPlaying || s.answered) return;
    final question = s.question;
    final card = _schedule.cards
        .where((c) => c.cardId == question.cardId)
        .firstOrNull;
    if (card == null) return;
    final shownAt = _shownAt;
    final outcome = reviewRecallCard(
      card,
      correct: choiceId == question.correctChoiceId,
      today: _today,
      decidedIn: shownAt == null ? null : _now().difference(shownAt),
    );
    final cards = [
      for (final c in _schedule.cards)
        if (c.cardId != card.cardId)
          c
        else if (outcome case Rescheduled(card: final next))
          next,
    ];
    final moved = switch (outcome) {
      Rescheduled(card: final next) => next.box != card.box,
      Retired() => true,
    };
    if (moved) _boxMoves++;
    _schedule = RecallSchedule(cards: cards, ingested: _schedule.ingested);
    state = RecallPlaying(
      round: s.round,
      index: s.index,
      verdicts: [...s.verdicts, outcome.verdict],
      chosenId: choiceId,
      boxes: s.boxes,
    );
    ref.read(analyticsProvider).track(AnalyticsEvent.recallCardAnswered, {
      'card_kind': EventValue.name(question.kind),
      'verdict': EventValue.name(outcome.verdict),
      'box': EventValue.name(card.box),
    });
    try {
      await ref.read(recallStoreProvider).save(_schedule);
    } on Object catch (e) {
      ref.read(logProvider).warn('recall schedule not saved', {
        'error': e.runtimeType.toString(),
      });
    }
  }

  /// On to the next card, or the end of the round.
  void next() {
    final s = state;
    if (s is! RecallPlaying || !s.answered) return;
    if (s.index + 1 < s.round.length) {
      _shownAt = _now();
      state = RecallPlaying(
        round: s.round,
        index: s.index + 1,
        verdicts: s.verdicts,
        boxes: s.boxes,
      );
      _noteOpened(state);
      return;
    }
    final finished = RecallFinished(verdicts: s.verdicts);
    ref.read(analyticsProvider).track(AnalyticsEvent.recallSessionCompleted, {
      'cards': EventValue.count(s.verdicts.length),
      'correct': EventValue.count(finished.known),
      'box_moves': EventValue.count(_boxMoves),
    });
    state = finished;
    // The round's XP and the day it counts towards the weekly goal (brief 32).
    unawaited(
      ref.read(progressionActionsProvider).recordRecallRound(s.verdicts),
    );
  }

  /// The same day gives the same order of choices, so a card read twice in a day doesn't
  /// reshuffle under the player.
  static int _seedFor(CalendarDay day) =>
      day.year * _yearScale + day.month * _monthScale + day.day;

  static const int _yearScale = 10000;
  static const int _monthScale = 100;
}
