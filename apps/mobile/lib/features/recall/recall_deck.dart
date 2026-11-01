import 'package:content/content.dart';
import 'package:engine/engine.dart';

import '../../core/progress/progress_repository.dart';

/// What a recall card is about.
enum RecallCardKind {
  /// A misconception the player fell for in a beat ("You fell for: …"). The card id is the
  /// misconception's `Reason` id.
  trap,

  /// A lesson behind a costly follow-up reply, which has no why step. The card id is the
  /// `Lesson` id, and the question is the lesson's own `RecallCheck`.
  lesson,
}

/// One answer on a recall card.
class RecallChoice {
  const RecallChoice({required this.id, required this.text});

  final String id;
  final String text;
}

/// A recall card as the player sees it: active, not reading. They read a line or a
/// misconception and pick what beats it.
class RecallQuestion {
  const RecallQuestion({
    required this.cardId,
    required this.kind,
    required this.kicker,
    required this.prompt,
    required this.ask,
    required this.choices,
    required this.correctChoiceId,
    this.quote,
    this.takeaway,
  });

  final String cardId;
  final RecallCardKind kind;

  /// The small caps over the card ("YOU FELL FOR", or the lesson's title).
  final String kicker;

  /// The misconception, or the lesson's question.
  final String prompt;

  /// The line the misconception led to, quoted under it. Null on a lesson card.
  final String? quote;

  /// What the player has to do ("Which principle beats it?").
  final String ask;
  final List<RecallChoice> choices;
  final String correctChoiceId;

  /// What to remember, shown once the card is answered.
  final String? takeaway;
}

/// Builds recall cards from the game's content and the player's stored attempts.
class RecallDeck {
  RecallDeck(this.content) {
    for (final mission in content.missions) {
      for (final beat in mission.beats) {
        for (final reason in beat.why?.reasons ?? const <Reason>[]) {
          if (reason.tempts.isNotEmpty) _traps[reason.id] = (beat, reason);
        }
      }
    }
  }

  final ContentBundle content;
  final Map<String, (Beat, Reason)> _traps = {};

  static const String trapKicker = 'YOU FELL FOR';
  static const String trapAsk = 'Which principle beats it?';
  static const String lessonAsk = 'Pick the one that holds.';

  /// A trap card offers this many principles: the sound one and misconceptions.
  static const int trapChoices = 3;

  /// The cards one finished attempt earned, in the order they happened: the misconception
  /// behind every weak beat line (the lesson of a weak built answer), then the lesson of a weak
  /// follow-up reply.
  List<String> missedCardIds(AttemptRecord attempt) {
    final mission = _missionById(attempt.missionId);
    if (mission == null) return const [];
    final ids = <String>[];
    final beats = mission.beats;
    for (var i = 0; i < beats.length && i < attempt.beatOptionIds.length; i++) {
      final beat = beats[i];
      final optionId = attempt.beatOptionIds[i];
      if (beat.isStrongest(optionId)) continue;
      // A built answer (brief 27) isn't any reason's temptation: its lesson is the card.
      final builtLesson = beat.build?.answerById(optionId)?.lessonId;
      if (builtLesson != null && _lessonById(builtLesson) != null) {
        ids.add(builtLesson);
        continue;
      }
      for (final reason in beat.why?.reasons ?? const <Reason>[]) {
        if (reason.tempts.contains(optionId)) ids.add(reason.id);
      }
    }
    final reply = _replyOf(mission, attempt);
    final lessonId = reply?.lessonId;
    if (lessonId != null && _lessonById(lessonId) != null) ids.add(lessonId);
    return ids;
  }

  /// The question for [cardId], or null if the content no longer has it (an old card after a
  /// content change: the room skips it). [seed] shuffles the choices, so the right answer isn't
  /// always in the same place.
  RecallQuestion? question(String cardId, {required int seed}) {
    final trap = _traps[cardId];
    if (trap != null) return _trapQuestion(trap.$1, trap.$2, seed: seed);
    final lesson = _lessonById(cardId);
    if (lesson != null) return _lessonQuestion(lesson, seed: seed);
    return null;
  }

  RecallQuestion? _trapQuestion(Beat beat, Reason trap, {required int seed}) {
    final reasons = beat.why!.reasons;
    final sound = reasons.where((r) => r.soundFor.isNotEmpty).firstOrNull;
    if (sound == null) return null;
    // The beat's other misconceptions first; a beat with only one other is topped up from the
    // rest of the game, so every trap card offers the same number of choices.
    final distractors = [
      for (final r in reasons)
        if (r.tempts.isNotEmpty && r.id != trap.id) r,
      for (final (_, r) in _traps.values)
        if (r.id != trap.id && !reasons.contains(r)) r,
    ].take(trapChoices - 1);
    final choices = shuffled(
      [
        for (final r in [sound, ...distractors])
          RecallChoice(id: r.id, text: r.text),
      ],
      seed: seed,
      salt: _stableHash(trap.id),
    );
    final tempted = beat.options
        .where((o) => trap.tempts.contains(o.id))
        .firstOrNull;
    return RecallQuestion(
      cardId: trap.id,
      kind: RecallCardKind.trap,
      kicker: trapKicker,
      prompt: trap.text,
      quote: tempted?.text,
      ask: trapAsk,
      choices: choices,
      correctChoiceId: sound.id,
      takeaway: _lessonById(tempted?.lessonId)?.takeaway ?? sound.text,
    );
  }

  RecallQuestion _lessonQuestion(Lesson lesson, {required int seed}) {
    final check = lesson.recall;
    return RecallQuestion(
      cardId: lesson.id,
      kind: RecallCardKind.lesson,
      kicker: lesson.title.toUpperCase(),
      prompt: check.prompt,
      ask: lessonAsk,
      choices: shuffled(
        [for (final o in check.options) RecallChoice(id: o.id, text: o.text)],
        seed: seed,
        salt: _stableHash(lesson.id),
      ),
      correctChoiceId: check.correctOptionId,
      takeaway: lesson.takeaway,
    );
  }

  Mission? _missionById(String id) =>
      content.missions.where((m) => m.id == id).firstOrNull;

  Lesson? _lessonById(String? id) =>
      id == null ? null : content.lessons.where((l) => l.id == id).firstOrNull;

  AnswerOption? _replyOf(Mission mission, AttemptRecord attempt) {
    final followUp = mission.followUps
        .where((f) => f.id == attempt.followUpId)
        .firstOrNull;
    return followUp?.replies
        .where((r) => r.id == attempt.replyOptionId)
        .firstOrNull;
  }
}

/// A hash of [text] that is the same on every platform and every run (`String.hashCode` isn't
/// promised to be), for shuffle salts.
int _stableHash(String text) =>
    text.codeUnits.fold(_hashStart, (h, c) => (h * _hashPrime + c) & _mask31);

const int _hashStart = 17;
const int _hashPrime = 31;
const int _mask31 = 0x7FFFFFFF;
