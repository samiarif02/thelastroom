import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  // Relevance 100, specificity 67, structure 67, adaptability 67.
  final score = scoreAttempt(
    attempt([
      line('o', 3, 2, 2),
      line('e', 3, 2, 2),
      line('l', 3, 2, 2),
    ], line('r', 3, 2, 2, 2)),
  );
  const requirements = [
    SkillRequirement(
      skill: Skill.clearIntroductions,
      dimension: Dimension.relevance,
      minScore: 70,
    ),
    SkillRequirement(
      skill: Skill.evidenceBuilder,
      dimension: Dimension.specificity,
      minScore: 70,
    ),
    SkillRequirement(
      skill: Skill.thinkUnderPressure,
      dimension: Dimension.adaptability,
      minScore: 67,
    ),
  ];

  Set<Skill> unlocked({bool hinted = false, Set<Skill> already = const {}}) =>
      newlyUnlockedSkills(
        score: score,
        hinted: hinted,
        requirements: requirements,
        alreadyUnlocked: already,
      );

  test('unlocks every skill whose minimum is met, the minimum included', () {
    expect(unlocked(), {Skill.clearIntroductions, Skill.thinkUnderPressure});
  });

  test('a hinted attempt unlocks nothing (FR-32)', () {
    expect(unlocked(hinted: true), isEmpty);
  });

  test('a skill already unlocked is not unlocked again', () {
    expect(unlocked(already: {Skill.clearIntroductions}), {
      Skill.thinkUnderPressure,
    });
  });

  test('no requirements, no skills', () {
    expect(
      newlyUnlockedSkills(
        score: score,
        hinted: false,
        requirements: const [],
        alreadyUnlocked: const {},
      ),
      isEmpty,
    );
  });
}
