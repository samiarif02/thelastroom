import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

/// Wave 5 across all seven missions: the score rewards thinking (brief 19).
void main() {
  const thinking = Duration(seconds: 6);
  const rushed = Duration(milliseconds: 500);

  // The strongest line of every beat, picked after [decidedIn], with its sound reason or (when
  // [soundReason] is false) the first reason that is wrong for it.
  MissionScore play(
    Mission mission, {
    required Duration decidedIn,
    bool soundReason = true,
  }) {
    BeatPick pick(Beat beat) {
      final best = beat.options.firstWhere((o) => beat.isStrongest(o.id));
      final reason = beat.why!.reasons.firstWhere(
        (r) => r.isSoundFor(best.id) == soundReason,
      );
      return BeatPick(
        beat: beat.kind,
        choice: best.scored,
        decidedIn: decidedIn,
        reason: reason.pickFor(best.id),
      );
    }

    final reply = mission.followUps
        .firstWhere((f) => f.trigger == null)
        .replies
        .first
        .scored;
    return scoreAttempt(
      AttemptInput(
        picks: [for (final b in mission.beats) pick(b)],
        followUpReply: reply,
        hinted: mission.hinted,
      ),
    );
  }

  for (final mission in missions) {
    group(mission.id, () {
      test('thinking scores more than rushing the same lines', () {
        final thought = play(mission, decidedIn: thinking);
        final guessed = play(mission, decidedIn: rushed);
        expect(guessed.total, lessThan(thought.total));
        expect(guessed.guessedBeats, BeatKind.values);
        expect(thought.guessed, isFalse);
      });

      test('the right reasoning scores more than the wrong reasoning', () {
        final sound = play(mission, decidedIn: thinking);
        final unsound = play(mission, decidedIn: thinking, soundReason: false);
        expect(unsound.total, lessThan(sound.total));
        expect(unsound.beatCredits, everyElement(PickCredit.unsoundReason));
      });

      test('the interviewer who asks the question asks why and reacts', () {
        for (final beat in mission.beats) {
          final reaction = beat.reaction!;
          for (final line in [
            beat.why!.line,
            reaction.strong,
            reaction.weak,
            reaction.guessed,
          ]) {
            expect(line.speakerId, mission.question.speakerId);
          }
          // Three different lines, so the player hears how the pick landed.
          expect({
            reaction.strong.text,
            reaction.weak.text,
            reaction.guessed.text,
          }, hasLength(3));
        }
      });
    });
  }
}
