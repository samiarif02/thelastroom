import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

/// A pick made [ms] milliseconds after the options appeared, with an optional reason.
BeatPick timed(BeatKind beat, ScoredChoice choice, {int? ms, bool? sound}) =>
    BeatPick(
      beat: beat,
      choice: choice,
      decidedIn: ms == null ? null : Duration(milliseconds: ms),
      reason: sound == null ? null : ReasonPick(reasonId: 'r', sound: sound),
    );

const thinking = 4000;
const instant = 300;

void main() {
  final perfect = even('p', 3);
  final reply = even('reply', 3);

  group('PickCredit', () {
    test('a guess keeps nothing, whatever the reason', () {
      for (final sound in [null, true, false]) {
        final pick = timed(BeatKind.open, perfect, ms: instant, sound: sound);
        expect(PickCredit.of(pick), PickCredit.guessed);
      }
    });

    test('an unsound reason keeps 60 %', () {
      final pick = timed(BeatKind.open, perfect, ms: thinking, sound: false);
      expect(PickCredit.of(pick), PickCredit.unsoundReason);
      expect(PickCredit.unsoundReason.keepPercent, unsoundReasonKeepPercent);
      expect(unsoundReasonKeepPercent, 60);
    });

    test('a sound reason, no why step, or an old pick keeps everything', () {
      for (final pick in [
        timed(BeatKind.open, perfect, ms: thinking, sound: true),
        timed(BeatKind.open, perfect, ms: thinking),
        timed(BeatKind.open, perfect),
      ]) {
        expect(PickCredit.of(pick), PickCredit.full);
      }
    });

    test('the guess threshold is exclusive: exactly 1.5 s is thinking', () {
      expect(
        PickCredit.of(timed(BeatKind.open, perfect, ms: 1499)),
        PickCredit.guessed,
      );
      expect(
        PickCredit.of(timed(BeatKind.open, perfect, ms: 1500)),
        PickCredit.full,
      );
    });
  });

  group('scoreAttempt: reasons and guesses', () {
    AttemptInput withEvidence({int? ms, bool? sound}) => AttemptInput(
      picks: [
        timed(BeatKind.open, perfect, ms: thinking, sound: true),
        timed(BeatKind.evidence, even('e', 3), ms: ms, sound: sound),
        timed(BeatKind.land, perfect, ms: thinking, sound: true),
      ],
      followUpReply: reply,
      hinted: false,
    );

    test('thought through with sound reasons: 100, every beat full', () {
      final s = scoreAttempt(withEvidence(ms: thinking, sound: true));
      expect(s.total, 100);
      expect(s.beatCredits, everyElement(PickCredit.full));
      expect(s.guessed, isFalse);
    });

    test('worked example: an unsound reason on a perfect evidence line', () {
      final s = scoreAttempt(withEvidence(ms: thinking, sound: false));
      // (3 + 1.8 + 3 + 3) / 12 = 90 %; structure is the weakest beat, 1.8 / 3 = 60 %.
      expect(s.dimensions[Dimension.relevance], 90);
      expect(s.dimensions[Dimension.specificity], 90);
      expect(s.dimensions[Dimension.structure], 60);
      expect(s.dimensions[Dimension.adaptability], 100);
      expect(s.beatCredits, [
        PickCredit.full,
        PickCredit.unsoundReason,
        PickCredit.full,
      ]);
      expect(s.costliestOptionId, 'e');
      expect(s.guessed, isFalse);
    });

    test('worked example: a guessed evidence beat scores 0 and is flagged', () {
      final s = scoreAttempt(withEvidence(ms: instant, sound: true));
      // (3 + 0 + 3 + 3) / 12 = 75 %; the weakest beat is now 0.
      expect(s.dimensions[Dimension.relevance], 75);
      expect(s.dimensions[Dimension.specificity], 75);
      expect(s.dimensions[Dimension.structure], 0);
      expect(s.guessed, isTrue);
      expect(s.guessedBeats, [BeatKind.evidence]);
      expect(s.costliestOptionId, 'e');
    });

    test('guessing every beat: only the reply can score', () {
      final s = scoreAttempt(
        AttemptInput(
          picks: [
            for (final b in BeatKind.values)
              timed(b, perfect, ms: instant, sound: true),
          ],
          followUpReply: reply,
          hinted: false,
        ),
      );
      expect(s.dimensions[Dimension.relevance], 25);
      expect(s.dimensions[Dimension.structure], 0);
      expect(s.dimensions[Dimension.adaptability], 100);
      expect(s.guessedBeats, BeatKind.values);
    });

    test(
      'random clicking at speed scores less than thinking, line for line',
      () {
        final lines = [even('a', 2), line('b', 3, 1, 2), even('c', 1)];
        AttemptInput run(int ms) => AttemptInput(
          picks: [
            for (var i = 0; i < 3; i++)
              timed(BeatKind.values[i], lines[i], ms: ms, sound: true),
          ],
          followUpReply: even('r', 1),
          hinted: false,
        );
        expect(
          scoreAttempt(run(instant)).total,
          lessThan(scoreAttempt(run(thinking)).total),
        );
      },
    );

    test(
      'a sound reason never scores below an unsound one, all else equal',
      () {
        for (var score = 0; score <= DimensionScores.max; score++) {
          AttemptInput run(bool sound) => AttemptInput(
            picks: [
              for (final b in BeatKind.values)
                timed(b, even('x$score', score), ms: thinking, sound: sound),
            ],
            followUpReply: reply,
            hinted: false,
          );
          expect(
            scoreAttempt(run(true)).total,
            greaterThanOrEqualTo(scoreAttempt(run(false)).total),
          );
        }
      },
    );
  });

  group('old attempts score exactly as before', () {
    // Every 0–3 combination on the beats, with picks as saved before wave 5 (no timing, no
    // reason), against the same picks with a sound reason after thinking: identical scores.
    test('no timing and no reason is full credit, for every line', () {
      for (var a = 0; a <= 3; a++) {
        for (var b = 0; b <= 3; b++) {
          for (var c = 0; c <= 3; c++) {
            final choices = [
              line('o', a, b, c),
              line('e', b, c, a),
              even('l', c),
            ];
            final old = scoreAttempt(attempt(choices, line('r', a, c, b, a)));
            final now = scoreAttempt(
              AttemptInput(
                picks: [
                  for (var i = 0; i < 3; i++)
                    timed(
                      BeatKind.values[i],
                      choices[i],
                      ms: thinking,
                      sound: true,
                    ),
                ],
                followUpReply: line('r', a, c, b, a),
                hinted: false,
              ),
            );
            expect(now, old);
            expect(old.beatCredits, everyElement(PickCredit.full));
          }
        }
      }
    });

    test('a score built without beatCredits defaults to all full', () {
      const s = MissionScore(
        dimensions: {},
        total: 0,
        optionIdsByCost: [],
        flags: {},
      );
      expect(s.beatCredits, everyElement(PickCredit.full));
      expect(s.guessed, isFalse);
    });
  });

  group('selectFollowUp probes a guessed beat', () {
    const candidates = [
      FollowUpCandidate(id: 'vague', trigger: Flag.vague),
      FollowUpCandidate(id: 'rambling', trigger: Flag.rambling),
      FollowUpCandidate(id: 'default'),
    ];

    test(
      'the guessed line is the weakest, so its flag picks the follow-up',
      () {
        final picks = [
          timed(BeatKind.open, even('o', 1, flags: {Flag.vague}), ms: thinking),
          timed(
            BeatKind.evidence,
            even('e', 3, flags: {Flag.rambling}),
            ms: instant,
          ),
          timed(BeatKind.land, even('l', 3), ms: thinking),
        ];
        expect(
          selectFollowUp(picks: picks, candidates: candidates),
          'rambling',
        );
      },
    );

    test('without timing the weakest written line is probed, as before', () {
      final picks = beatsOf([
        even('o', 1, flags: {Flag.vague}),
        even('e', 3, flags: {Flag.rambling}),
        even('l', 3),
      ]);
      expect(selectFollowUp(picks: picks, candidates: candidates), 'vague');
    });
  });

  group('trustAfterPicks', () {
    test('matches trustAfter when nothing is guessed or misreasoned', () {
      final choices = [even('a', 3), even('b', 1), line('c', 2, 3, 0)];
      for (var n = 0; n <= choices.length; n++) {
        expect(
          trustAfterPicks(beatsOf(choices.take(n).toList())),
          trustAfter(choices.take(n).toList()),
        );
      }
    });

    test('a guess counts as a 0 line: −24, even on a perfect line', () {
      expect(
        trustAfterPicks([timed(BeatKind.open, perfect, ms: instant)]),
        initialTrust - 24,
      );
    });

    test('an unsound reason on a perfect line still lifts it, but less', () {
      // 9 points at 60 % = 5.4; 4 × (5.4 − 6) = −2.4 → −2.
      final misreasoned = trustAfterPicks([
        timed(BeatKind.open, perfect, ms: thinking, sound: false),
      ]);
      expect(misreasoned, initialTrust - 2);
      expect(
        trustAfterPicks([
          timed(BeatKind.open, perfect, ms: thinking, sound: true),
        ]),
        initialTrust + 12,
      );
    });

    test('stays within 0–100', () {
      final guesses = [
        for (final b in BeatKind.values) timed(b, perfect, ms: instant),
      ];
      expect(trustAfterPicks([...guesses, ...guesses]), 0);
    });
  });

  group('judgePick', () {
    test('a guess is a guess, whatever was picked', () {
      final pick = timed(BeatKind.open, perfect, ms: instant, sound: true);
      expect(judgePick(pick, strongestOption: true), PickQuality.guessed);
    });

    test('strong needs the strongest line and a sound reason', () {
      expect(
        judgePick(
          timed(BeatKind.open, perfect, ms: thinking, sound: true),
          strongestOption: true,
        ),
        PickQuality.strong,
      );
      expect(
        judgePick(
          timed(BeatKind.open, perfect, ms: thinking, sound: false),
          strongestOption: true,
        ),
        PickQuality.weak,
      );
      expect(
        judgePick(
          timed(BeatKind.open, perfect, ms: thinking, sound: true),
          strongestOption: false,
        ),
        PickQuality.weak,
      );
    });
  });
}
