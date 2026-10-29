import 'dimension.dart';
import 'scoring.dart';

/// The skill tree (brief §6, FR-32).
enum Skill {
  clearIntroductions('clear_introductions'),
  evidenceBuilder('evidence_builder'),
  conflictNavigator('conflict_navigator'),
  thinkUnderPressure('think_under_pressure');

  const Skill(this.wireName);

  /// The name used in content, the database and analytics (`skill_id`).
  final String wireName;
}

/// What a mission demands before it unlocks a skill: a minimum score on one dimension.
/// Missions declare these in content.
class SkillRequirement {
  const SkillRequirement({
    required this.skill,
    required this.dimension,
    required this.minScore,
  });

  final Skill skill;
  final Dimension dimension;

  /// The 0–100 dimension score the attempt must reach.
  final int minScore;
}

/// The skills this attempt unlocks that weren't unlocked before.
///
/// Empty when the attempt was hinted: a skill unlocks only when it's demonstrated without help
/// (FR-32). Otherwise, every requirement whose dimension score is at least its minimum, minus
/// [alreadyUnlocked].
Set<Skill> newlyUnlockedSkills({
  required MissionScore score,
  required bool hinted,
  required List<SkillRequirement> requirements,
  required Set<Skill> alreadyUnlocked,
}) {
  if (hinted) return const {};
  return {
    for (final requirement in requirements)
      if (score.dimensions[requirement.dimension]! >= requirement.minScore &&
          !alreadyUnlocked.contains(requirement.skill))
        requirement.skill,
  };
}
