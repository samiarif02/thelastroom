import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  const mission = missionTheOpportunity;
  final paths = allPaths(mission);
  final totals = [for (final p in paths) p.score.total];

  test('Mission 1 is the unhinted, untimed baseline (FR-13, FR-30)', () {
    expect(mission.isBaseline, isTrue);
    expect(mission.hinted, isFalse);
    expect(mission.timed, isFalse);
    expect(mission.chapter, 1);
    expect(mission.number, 1);
    expect(gameContent.missions.first, same(mission));
  });

  test('Priya says every line', () {
    final speakers = {
      for (final line in mission.scene) line.speakerId,
      mission.question.speakerId,
      for (final followUp in mission.followUps) followUp.line.speakerId,
    };
    expect(speakers, {priya.id});
  });

  test('the setup makes clear who the player plays (note 3)', () {
    final firstName = player.name.split(' ').first;
    expect(mission.scene.first.text, contains(firstName));
  });

  test('the best path scores at least 90, the worst at most 30', () {
    // So the baseline has room to show growth either way.
    expect(totals.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(90));
    expect(totals.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(30));
  });

  test('every beat asks why and reacts, in Priya\'s voice (wave 5)', () {
    for (final beat in mission.beats) {
      final why = beat.why!;
      final reaction = beat.reaction!;
      final lines = [
        why.line,
        reaction.strong,
        reaction.weak,
        reaction.guessed,
      ];
      expect(lines.map((l) => l.speakerId), everyElement(priyaId));
      expect(why.reasons, hasLength(beat.options.length));
    }
  });

  test(
    'the best line, given for the right reason after thinking, scores 100',
    () {
      BeatPick pick(Beat beat, {required Duration decidedIn}) {
        final best = beat.options.firstWhere((o) => beat.isStrongest(o.id));
        final reason = beat.why!.reasons.firstWhere(
          (r) => r.isSoundFor(best.id),
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
      MissionScore play(Duration decidedIn) => scoreAttempt(
        AttemptInput(
          picks: [for (final b in mission.beats) pick(b, decidedIn: decidedIn)],
          followUpReply: reply,
          hinted: false,
        ),
      );
      final thought = play(const Duration(seconds: 5));
      final rushed = play(const Duration(milliseconds: 400));
      expect(thought.beatCredits, everyElement(PickCredit.full));
      expect(rushed.guessed, isTrue);
      expect(rushed.total, lessThan(thought.total));
      expect(rushed.dimensions[Dimension.structure], 0);
    },
  );
}
