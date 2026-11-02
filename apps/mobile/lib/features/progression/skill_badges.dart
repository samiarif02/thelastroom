import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

/// The skills' names and what each one means, as the player reads them.
abstract final class SkillCopy {
  static String name(Skill skill) => switch (skill) {
    Skill.clearIntroductions => 'Clear Introductions',
    Skill.evidenceBuilder => 'Evidence Builder',
    Skill.conflictNavigator => 'Conflict Navigator',
    Skill.thinkUnderPressure => 'Think Under Pressure',
  };

  static String meaning(Skill skill) => switch (skill) {
    Skill.clearIntroductions =>
      'You answer the question they asked, first time.',
    Skill.evidenceBuilder => 'You prove it with your own part and a number.',
    Skill.conflictNavigator => 'You own a hard moment without blaming anyone.',
    Skill.thinkUnderPressure => 'You stay clear when the clock is running.',
  };

  /// Where a locked skill is earned, so a dark badge reads as "next", never as failure.
  static String earnedIn(Skill skill) => switch (skill) {
    Skill.clearIntroductions => 'Mission 3',
    Skill.evidenceBuilder => 'Mission 7',
    Skill.conflictNavigator => 'Chapter 2',
    Skill.thinkUnderPressure => 'Chapter 3',
  };

  static String initials(Skill skill) =>
      name(skill).split(' ').map((w) => w[0]).join();
}

/// One skill as a round badge: lit in sunflower once earned, a quiet outline until then.
class SkillBadge extends StatelessWidget {
  const SkillBadge({
    super.key,
    required this.skill,
    required this.earned,
    this.size = defaultSize,
  });

  final Skill skill;
  final bool earned;
  final double size;

  static const double defaultSize = 44;
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final label = earned
        ? '${SkillCopy.name(skill)}, earned'
        : '${SkillCopy.name(skill)}, earned in ${SkillCopy.earnedIn(skill)}';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? BrandVivid.accent : BrandVivid.night,
            border: Border.all(
              color: earned ? BrandVivid.accent : BrandVivid.hairline(),
              width: _ring,
            ),
            boxShadow: earned ? BrandVivid.glowShadow(BrandVivid.accent) : null,
          ),
          child: Center(
            child: Text(
              SkillCopy.initials(skill),
              style: BrandVividType.row.copyWith(
                color: earned ? BrandVivid.onAccent : BrandVivid.onDeepSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
