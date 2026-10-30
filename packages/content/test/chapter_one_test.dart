import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'paths.dart';

/// Brief 07's checks over the whole of Chapter 1: every mission scores, branches and teaches
/// as specified, and Mission 6 can challenge any Mission 5 answer.
void main() {
  /// Every mission's best path reaches this, so a strong answer can feel strong.
  const minBestTotal = 85;

  /// Every mission's worst path stays under this, so a weak answer reads as weak.
  const maxWorstTotal = 35;

  test('the shipped content passes validateContent', () {
    expect(validateContent(gameContent), isEmpty);
  });

  test('Chapter 1 is the seven missions of brief §6, in order', () {
    expect(
      [for (final m in gameContent.missions) m.number],
      [1, 2, 3, 4, 5, 6, 7],
    );
    expect(gameContent.missions.every((m) => m.chapter == 1), isTrue);
    expect([
      for (final m in gameContent.missions) m.title,
    ], gameContent.chapters.first.missionTitles);
  });

  test('Missions 1, 3 and 7 are unhinted; the rest may hint (FR-30)', () {
    expect(
      [
        for (final m in gameContent.missions)
          if (!m.hinted) m.number,
      ],
      [1, 3, 7],
    );
  });

  test(
    'Chapters 2 and 3 are locked, with seven mission titles each (FR-31)',
    () {
      expect([for (final c in gameContent.chapters) c.number], [1, 2, 3]);
      expect(gameContent.chapters.first.playable, isTrue);
      for (final chapter in gameContent.chapters.skip(1)) {
        expect(chapter.playable, isFalse);
        expect(chapter.missionTitles, hasLength(7));
      }
    },
  );

  test('each interviewer runs the missions brief §6 gives them', () {
    const expected = {
      1: {priyaId},
      2: {priyaId},
      3: {priyaId},
      4: {marcusId},
      5: {marcusId},
      6: {lenaId},
      7: {priyaId, marcusId},
    };
    for (final mission in gameContent.missions) {
      final speakers = {
        for (final line in mission.scene) line.speakerId,
        mission.question.speakerId,
        for (final followUp in mission.followUps) followUp.line.speakerId,
        for (final variant
            in mission.continuity?.variants ?? <ContinuityVariant>[])
          variant.line.speakerId,
        for (final line in mission.epilogue) line.speakerId,
      };
      expect(speakers, expected[mission.number], reason: mission.id);
    }
    expect(
      [for (final i in gameContent.interviewers) i.id],
      [priyaId, marcusId, lenaId, samId],
    );
  });

  test('only Mission 7 has an epilogue: the cliffhanger', () {
    expect(
      [
        for (final m in gameContent.missions)
          if (m.epilogue.isNotEmpty) m.id,
      ],
      [missionFirstRoundReview.id],
    );
  });

  for (final mission in gameContent.missions) {
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

      test('every flag the mission can raise is taught by a lesson for it', () {
        final lessonsById = {for (final l in gameContent.lessons) l.id: l};
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

  group('skills unlock only on a strong, unhinted run (FR-32)', () {
    for (final (mission, skill) in [
      (missionTheExperienceGap, Skill.clearIntroductions),
      (missionFirstRoundReview, Skill.evidenceBuilder),
    ]) {
      test('${mission.id}: ${skill.wireName}', () {
        expect(mission.hinted, isFalse);
        expect([for (final r in mission.skillRequirements) r.skill], [skill]);
        final byTotal = allPaths(mission)
          ..sort((a, b) => a.score.total.compareTo(b.score.total));
        Set<Skill> unlocked(MissionPath path, {bool hinted = false}) =>
            newlyUnlockedSkills(
              score: path.score,
              hinted: hinted,
              requirements: mission.skillRequirements,
              alreadyUnlocked: const {},
            );
        expect(unlocked(byTotal.last), {skill});
        expect(unlocked(byTotal.first), isEmpty);
        expect(unlocked(byTotal.last, hinted: true), isEmpty);
      });
    }
  });

  group('Mission 6 challenges the costliest Mission 5 line (FR-30)', () {
    const source = missionSomethingWentWrong;
    final continuity = missionTheFollowUpTrap.continuity!;
    final beatOptionIds = {
      for (final beat in source.beats)
        for (final option in beat.options) option.id,
    };
    final paths = allPaths(source);

    test('it continues Mission 5', () {
      expect(continuity.fromMissionId, source.id);
    });

    test(
      'every Mission 5 answer gets the challenge for its costliest beat line',
      () {
        for (final path in paths) {
          final byCost = path.score.optionIdsByCost;
          final costliestBeat = byCost.firstWhere(beatOptionIds.contains);
          final variant = continuity.variants.singleWhere(
            (v) => v.sourceOptionId == costliestBeat,
          );
          expect(continuity.lineFor(byCost), same(variant.line));
        }
      },
    );

    test('there is a variant for exactly the lines that can be costliest', () {
      final canBeCostliest = {
        for (final path in paths)
          path.score.optionIdsByCost.firstWhere(beatOptionIds.contains),
      };
      expect({
        for (final v in continuity.variants) v.sourceOptionId,
      }, canBeCostliest);
    });

    test('with no Mission 5 attempt, there is no challenge line', () {
      expect(continuity.lineFor(const []), isNull);
    });
  });
}
