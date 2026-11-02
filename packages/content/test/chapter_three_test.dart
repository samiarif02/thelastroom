import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'paths.dart';

/// Brief 38: Chapter 3, "The Final Round", seven missions, three answered by choices and four
/// by voice. Checked as the game will ship them once Chapter 3 opens, before the flip.
void main() {
  /// The shipped content with Chapters 2 and 3 open (they open together, once the voice player
  /// is in): what the flip will ship.
  final opened = ContentBundle(
    chapters: [
      for (final c in chapters)
        c.number >= 2
            ? Chapter(
                number: c.number,
                title: c.title,
                missionTitles: c.missionTitles,
                playable: true,
              )
            : c,
    ],
    interviewers: interviewers,
    lessons: lessons,
    missions: writtenMissions,
  );
  final chapterThree = chapters.singleWhere((c) => c.number == 3);
  final cast = {for (final i in interviewers) i.id};

  test('Chapter 3 validates as it will ship when it opens', () {
    expect(validateContent(opened), isEmpty);
  });

  test(
    'Chapter 3 waits for the voice player: locked, its missions not yet played',
    () {
      expect(chapterThree.playable, isFalse);
      for (final m in chapterThreeMissions) {
        expect(missions.any((p) => p.id == m.id), isFalse, reason: m.id);
      }
    },
  );

  test('missions 15–21, titled as the tower teases them', () {
    expect(
      [for (final m in chapterThreeMissions) m.number],
      [15, 16, 17, 18, 19, 20, 21],
    );
    expect(chapterThreeMissions.every((m) => m.chapter == 3), isTrue);
    expect([
      for (final m in chapterThreeMissions) m.title,
    ], chapterThree.missionTitles);
  });

  test(
    'three choices missions and four voice ones, as brief 38 assigns them',
    () {
      expect(
        {for (final m in chapterThreeMissions) m.number: m.answerMode},
        {
          15: AnswerMode.choices,
          16: AnswerMode.voice,
          17: AnswerMode.voice,
          18: AnswerMode.choices,
          19: AnswerMode.choices,
          20: AnswerMode.voice,
          21: AnswerMode.voice,
        },
      );
    },
  );

  test('every mission says what it practises, in one line', () {
    for (final m in chapterThreeMissions) {
      final practises = m.practises;
      expect(practises, isNotNull, reason: m.id);
      expect(wordCount(practises!), lessThanOrEqualTo(maxOptionWords));
      expect(practises, endsWith('.'), reason: m.id);
    }
  });

  test('only The Decision, the last room, has an epilogue, and it fits', () {
    expect(
      [
        for (final m in chapterThreeMissions)
          if (m.epilogue.isNotEmpty) m.id,
      ],
      [missionTheDecision.id],
    );
    final epilogue = missionTheDecision.epilogue;
    expect(epilogue.length, inInclusiveRange(1, maxSceneLines));
    for (final line in epilogue) {
      expect(cast, contains(line.speakerId));
      expect(line.text.length, lessThanOrEqualTo(maxSubtitleChars));
    }
    expect(chapterThreeMissions.last, same(missionTheDecision));
  });

  test('Sam, the head of product, runs the final round', () {
    final speakers = {
      for (final m in chapterThreeMissions) ...[
        m.question.speakerId,
        for (final line in m.scene) line.speakerId,
      ],
    };
    expect(speakers, contains(samId));
    expect(cast.containsAll(speakers), isTrue);
  });

  group('voice missions', () {
    final voiced = [
      for (final m in chapterThreeMissions)
        if (m.answerMode == AnswerMode.voice) m,
    ];

    for (final mission in voiced) {
      group(mission.id, () {
        final voice = mission.voice!;

        test('listens for 3–4 points across at least three dimensions', () {
          expect(voice.listenFor.length, inInclusiveRange(3, 4));
          expect(
            {for (final p in voice.listenFor) p.dimension}.length,
            greaterThanOrEqualTo(3),
          );
        });

        test('the spoken follow-up listens for 1–3 points, adaptability among them', () {
          expect(voice.followUpListenFor.length, inInclusiveRange(1, 3));
          expect(
            voice.followUpListenFor.map((p) => p.dimension),
            contains(Dimension.adaptability),
          );
        });

        test('point ids carry the mission prefix', () {
          final prefix = '${mission.id.substring(0, 3)}_';
          for (final p in [...voice.listenFor, ...voice.followUpListenFor]) {
            expect(p.id, startsWith(prefix));
          }
        });

        test(
          'teaches a lesson from the campaign, and has no lines to pick',
          () {
            expect(lessons.map((l) => l.id), contains(voice.lessonId));
            expect(mission.beats, isEmpty);
            expect(mission.followUps, isEmpty);
          },
        );

        test('no figure outside the character sheet (note 3)', () {
          final figure = RegExp(r'\d[\d,.]*%?');
          final texts = [
            for (final p in [...voice.listenFor, ...voice.followUpListenFor])
              p.text,
            for (final line in [
              ...mission.scene,
              mission.question,
              voice.followUp,
              ...mission.epilogue,
            ])
              line.text,
          ];
          for (final text in texts) {
            for (final match in figure.allMatches(text)) {
              expect(player.figures, contains(match[0]), reason: text);
            }
          }
        });
      });
    }

    test('the four teach four different lessons', () {
      expect({for (final m in voiced) m.voice!.lessonId}, hasLength(4));
    });
  });

  group('choices missions', () {
    /// As in Chapter 1: a strong answer can feel strong, a weak one reads as weak.
    const minBestTotal = 85;
    const maxWorstTotal = 35;

    for (final mission in [
      for (final m in chapterThreeMissions)
        if (m.answerMode == AnswerMode.choices) m,
    ]) {
      group(mission.id, () {
        final paths = allPaths(mission);
        final totals = [for (final p in paths) p.score.total];
        final options = allOptions(mission);

        test(
          'the best path scores at least $minBestTotal, the worst at most $maxWorstTotal',
          () {
            expect(
              totals.reduce((a, b) => a > b ? a : b),
              greaterThanOrEqualTo(minBestTotal),
            );
            expect(
              totals.reduce((a, b) => a < b ? a : b),
              lessThanOrEqualTo(maxWorstTotal),
            );
          },
        );

        test('every follow-up can actually be asked', () {
          expect(
            {for (final p in paths) p.followUp.id},
            {for (final f in mission.followUps) f.id},
          );
        });

        test('every flag it can raise is taught by a lesson for it', () {
          final lessonsById = {for (final l in lessons) l.id: l};
          for (final flag in {for (final o in options) ...o.flags}) {
            expect(
              options.any(
                (o) =>
                    o.flags.contains(flag) &&
                    lessonsById[o.lessonId]?.flag == flag,
              ),
              isTrue,
              reason: '${flag.wireName} is never taught',
            );
          }
        });

        test('beat lines carry no adaptability: only the reply earns it', () {
          for (final beat in mission.beats) {
            for (final option in beat.options) {
              expect(option.scores.adaptability, 0, reason: option.id);
            }
          }
        });
      });
    }

    test(
      'Solve the Problem builds its plan from fragments, as Chapter 1 does',
      () {
        final build = missionSolveTheProblem.beats[1].build!;
        expect(build.strongAnswer.flags, isEmpty);
        expect(
          missionSolveTheProblem.beats[1].isStrongest(build.strongAnswer.id),
          isTrue,
        );
      },
    );
  });
}
