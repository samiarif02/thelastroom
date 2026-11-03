import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

const thinking = Duration(seconds: 4);
const instant = Duration(milliseconds: 300);

/// A pick on [beat] with an optional reason; [asked] false is a reason stored on a beat that
/// never asked (a built beat, before QA 51's fix).
BeatPick pick(
  BeatKind beat, {
  ScoredChoice? choice,
  Duration? decidedIn = thinking,
  bool? sound,
  bool counts = true,
  bool asked = true,
}) => BeatPick(
  beat: beat,
  choice: choice ?? even('p${beat.index}', 3),
  decidedIn: decidedIn,
  reason: sound == null
      ? null
      : ReasonPick(
          reasonId: 'r${beat.index}',
          sound: sound,
          counts: counts,
          asked: asked,
        ),
);

MissionScore scoredPicks(List<BeatPick> picks) => scoreAttempt(
  AttemptInput(picks: picks, followUpReply: even('reply', 3), hinted: false),
);

PlayedMission playedPicks(String id, List<BeatPick> picks) => PlayedMission(
  missionId: id,
  score: scoredPicks(picks),
  hinted: false,
  requirements: const [],
);

void main() {
  group('ReasonVerdict', () {
    test('the numbers: sound 10, close 5, a guess 0', () {
      expect(ReasonVerdict.sound.xp, reasonSoundXp);
      expect(ReasonVerdict.close.xp, reasonCloseXp);
      expect(ReasonVerdict.guessed.xp, 0);
      expect([reasonSoundXp, reasonCloseXp, voicePointXp], [10, 5, 5]);
    });

    test('a sound reason after thinking is sound', () {
      expect(
        ReasonVerdict.of(pick(BeatKind.open, sound: true)),
        ReasonVerdict.sound,
      );
    });

    test(
      'a considered wrong principle is close, on a strong line or a weak one',
      () {
        expect(
          ReasonVerdict.of(pick(BeatKind.open, sound: false)),
          ReasonVerdict.close,
        );
        expect(
          ReasonVerdict.of(
            pick(
              BeatKind.open,
              choice: even('weak', 1),
              sound: false,
              counts: false,
            ),
          ),
          ReasonVerdict.close,
        );
      },
    );

    test('a guessed line earns nothing for its reason, sound or not', () {
      for (final sound in [true, false]) {
        expect(
          ReasonVerdict.of(
            pick(BeatKind.open, decidedIn: instant, sound: sound),
          ),
          ReasonVerdict.guessed,
        );
      }
    });

    test('no why step (a built beat, an old attempt): no verdict', () {
      expect(ReasonVerdict.of(pick(BeatKind.open)), isNull);
      expect(ReasonVerdict.of(pick(BeatKind.open, decidedIn: null)), isNull);
      expect(
        ReasonVerdict.of(pick(BeatKind.open, sound: true, asked: false)),
        isNull,
      );
    });

    test(
      'a reason stored on a beat that never asked still scores as it did',
      () {
        final asked = scoredPicks([
          pick(BeatKind.open, sound: false),
          pick(BeatKind.evidence),
          pick(BeatKind.land),
        ]);
        final stored = scoredPicks([
          pick(BeatKind.open, sound: false, asked: false),
          pick(BeatKind.evidence),
          pick(BeatKind.land),
        ]);
        expect(stored.total, asked.total);
        expect(stored.beatCredits, asked.beatCredits);
        expect(stored.reasonVerdicts, isEmpty);
        expect(reasonXp(stored), 0);
      },
    );
  });

  group('reasonXp', () {
    test('sums the verdicts of the beats that asked why, in beat order', () {
      final score = scoredPicks([
        pick(BeatKind.open, sound: true),
        pick(BeatKind.evidence, sound: false),
        pick(BeatKind.land, decidedIn: instant, sound: true),
      ]);
      expect(score.reasonVerdicts, [
        ReasonVerdict.sound,
        ReasonVerdict.close,
        ReasonVerdict.guessed,
      ]);
      expect(reasonXp(score), 10 + 5 + 0);
    });

    test('a built beat (no why step) adds nothing', () {
      // Rooms 4, 6, 7 and 15 build one beat from fragments: two why steps at most.
      final score = scoredPicks([
        pick(BeatKind.open, sound: true),
        pick(BeatKind.evidence),
        pick(BeatKind.land, sound: true),
      ]);
      expect(score.reasonVerdicts, [ReasonVerdict.sound, ReasonVerdict.sound]);
      expect(reasonXp(score), 20);
    });

    test(
      'an attempt saved before wave 5 earns its room XP and nothing more',
      () {
        final old = scoreAttempt(
          attempt([even('o', 3), even('e', 3), even('l', 3)], even('r', 3)),
        );
        expect(reasonXp(old), 0);
        final p = PlayedMission(
          missionId: 'm1',
          score: old,
          hinted: false,
          requirements: const [],
        );
        expect(totalXp([p]), missionXp(total: old.total, firstClear: true));
      },
    );

    test('a voice answer earns 5 per point made, none for a point missed', () {
      const points = [
        VoicePoint(id: 'a', dimension: Dimension.relevance),
        VoicePoint(id: 'b', dimension: Dimension.specificity),
        VoicePoint(id: 'c', dimension: Dimension.structure),
        VoicePoint(id: 'd', dimension: Dimension.structure),
        VoicePoint(id: 'e', dimension: Dimension.adaptability),
        VoicePoint(id: 'f', dimension: Dimension.adaptability),
      ];
      int voiceXp(Set<String> made) =>
          reasonXp(scoreVoiceAnswer(points: points, made: made).score);
      expect(voiceXp({}), 0);
      expect(voiceXp({'a', 'c', 'e'}), 15);
      expect(voiceXp({'a', 'b', 'c', 'd', 'e', 'f'}), 30);
      // An id the mission doesn't listen for earns nothing.
      expect(voiceXp({'a', 'zzz'}), 5);
    });

    test(
      'a full choice room and a full voice room are worth about the same',
      () {
        final threeSound = scoredPicks([
          for (final b in BeatKind.values) pick(b, sound: true),
        ]);
        expect(reasonXp(threeSound), 30);
        // Voice rooms listen for 6–7 points.
        expect(6 * voicePointXp, 30);
        expect(7 * voicePointXp, 35);
      },
    );
  });

  group('attempt XP: the room plus its reasons', () {
    test('the debrief breakdown adds up', () {
      final attempts = [
        playedPicks('m1', [
          pick(BeatKind.open, sound: true),
          pick(BeatKind.evidence, sound: false),
          pick(BeatKind.land, sound: true),
        ]),
      ];
      final xp = lastAttemptXp(attempts);
      final total = attempts.single.score.total;
      expect(xp.room, missionXp(total: total, firstClear: true));
      expect(xp.reasons, 25);
      expect(xp.total, xp.room + 25);
      expect(totalXp(attempts), xp.total);
    });

    test('no double award: the same attempt scored again, as a resume or restore does', () {
      final picks = [
        pick(BeatKind.open, sound: true),
        pick(BeatKind.evidence, sound: true),
        pick(BeatKind.land, sound: false),
      ];
      final once = [playedPicks('m2', picks)];
      // Restored from storage: rescored from the same picks.
      final restored = [playedPicks('m2', List.of(picks))];
      expect(restored.single.score, once.single.score);
      expect(totalXp(restored), totalXp(once));
      expect(lastAttemptXp(restored), lastAttemptXp(once));
    });

    test('a changed reason replaces the old one, never adds to it', () {
      // Only the final picks are stored: a reason given, then the beat resumed and answered
      // again, is one reason.
      final answered = [
        pick(BeatKind.open, sound: false),
        pick(BeatKind.evidence, sound: true),
        pick(BeatKind.land, sound: true),
      ];
      expect(lastAttemptXp([playedPicks('m3', answered)]).reasons, 5 + 10 + 10);
    });

    test(
      'a replay earns its reasons again, but the first-clear bonus once',
      () {
        final picks = [for (final b in BeatKind.values) pick(b, sound: true)];
        final first = playedPicks('m5', picks);
        final again = playedPicks('m5', picks);
        expect(lastAttemptXp([first]).reasons, 30);
        expect(lastAttemptXp([first, again]).reasons, 30);
        expect(
          lastAttemptXp([first]).room - lastAttemptXp([first, again]).room,
          firstClearBonusXp,
        );
      },
    );

    test('a perfect first clear with every reason sound: 130', () {
      final perfect = playedPicks('m6', [
        for (final b in BeatKind.values) pick(b, sound: true),
      ]);
      expect(perfect.score.total, maxMissionScore);
      expect(lastAttemptXp([perfect]).total, 100 + 30);
    });
  });

  group('properties', () {
    // Every way a beat can be answered: no why step, guessed, close, sound; on a strong or a
    // weak line.
    final ways = <BeatPick Function(BeatKind)>[
      pick,
      (b) => pick(b, decidedIn: instant, sound: true),
      (b) => pick(b, decidedIn: instant, sound: false),
      (b) => pick(b, sound: false),
      (b) => pick(b, sound: true),
      (b) => pick(b, choice: even('w', 1), sound: false, counts: false),
      (b) => pick(b, choice: even('w', 1), decidedIn: instant, sound: false),
    ];
    final attempts = <List<BeatPick>>[
      for (final a in ways)
        for (final b in ways)
          for (final c in ways)
            [a(BeatKind.open), b(BeatKind.evidence), c(BeatKind.land)],
    ];

    test('reason XP is between 0 and 30, and a multiple of 5', () {
      for (final picks in attempts) {
        final xp = reasonXp(scoredPicks(picks));
        expect(xp, inInclusiveRange(0, BeatKind.values.length * reasonSoundXp));
        expect(xp % reasonCloseXp, 0);
      }
    });

    test('total XP never decreases as attempts are added', () {
      // Every attempt shape, played in turn on a handful of missions, replays included.
      final history = <PlayedMission>[];
      var before = totalXp(history, recallRoundXp: 7);
      for (var i = 0; i < attempts.length; i++) {
        history.add(playedPicks('m${i % 5}', attempts[i]));
        final now = totalXp(history, recallRoundXp: 7);
        expect(now, greaterThanOrEqualTo(before));
        expect(now - before, lastAttemptXp(history).total);
        before = now;
      }
    });

    test('making a reason sound never earns less XP for the attempt', () {
      for (final picks in attempts) {
        for (var i = 0; i < picks.length; i++) {
          final reason = picks[i].reason;
          if (reason == null || reason.sound) continue;
          final better = [
            for (var j = 0; j < picks.length; j++)
              j == i
                  ? BeatPick(
                      beat: picks[j].beat,
                      choice: picks[j].choice,
                      decidedIn: picks[j].decidedIn,
                      reason: ReasonPick(
                        reasonId: reason.reasonId,
                        sound: true,
                        counts: reason.counts,
                      ),
                    )
                  : picks[j],
          ];
          AttemptXp xp(List<BeatPick> p) =>
              attemptXp(playedPicks('m', p), firstClear: true);
          expect(xp(better).total, greaterThanOrEqualTo(xp(picks).total));
          expect(xp(better).reasons, greaterThanOrEqualTo(xp(picks).reasons));
        }
      }
    });

    test('the same picks always earn the same XP', () {
      for (final picks in attempts.take(50)) {
        expect(
          attemptXp(playedPicks('m', picks), firstClear: false),
          attemptXp(playedPicks('m', picks), firstClear: false),
        );
      }
    });
  });
}
