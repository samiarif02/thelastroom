import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/debrief/debrief_facts.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';

void main() {
  const mission = missionTheOpportunity;
  final beat = mission.beats.first;
  final strongest = beat.options.firstWhere((o) => beat.isStrongest(o.id));
  final weak = beat.options.firstWhere((o) => !beat.isStrongest(o.id));
  final principle = beat.why!.reasons.firstWhere(
    (r) => r.isSoundFor(strongest.id),
  );
  final temptation = beat.why!.reasons.firstWhere(
    (r) => r.tempts.contains(weak.id),
  );

  test(
    'a weak line: you fell for its misconception; the principle is shown',
    () {
      final row = reasoningOf(mission, [
        BeatPlay(
          option: weak,
          decidedIn: const Duration(seconds: 4),
          reason: temptation,
        ),
      ]).single;
      expect(row.strongest, isFalse);
      expect(row.fellFor, temptation);
      expect(row.principle, principle);
      expect(row.sound, isFalse);
      expect(row.guessed, isFalse);
    },
  );

  test('the strongest line with the principle: sound, nothing fallen for', () {
    final row = reasoningOf(mission, [
      BeatPlay(
        option: strongest,
        decidedIn: const Duration(seconds: 4),
        reason: principle,
      ),
    ]).single;
    expect(row.strongest, isTrue);
    expect(row.sound, isTrue);
    expect(row.fellFor, isNull);
  });

  test('a guess is marked, with its time', () {
    final row = reasoningOf(mission, [
      BeatPlay(
        option: strongest,
        decidedIn: const Duration(milliseconds: 400),
        reason: principle,
      ),
    ]).single;
    expect(row.guessed, isTrue);
    expect(row.decidedIn, const Duration(milliseconds: 400));
  });

  test('the wrong principle on the strongest line costs; on a weak line it does not', () {
    final wrong = beat.why!.reasons.firstWhere(
      (r) => !r.isSoundFor(strongest.id),
    );
    final onStrong = BeatPlay(option: strongest, reason: wrong).pick(beat);
    final onWeak = BeatPlay(option: weak, reason: wrong).pick(beat);
    expect(onStrong.reason!.counts, isTrue);
    expect(onWeak.reason!.counts, isFalse);
  });
}
