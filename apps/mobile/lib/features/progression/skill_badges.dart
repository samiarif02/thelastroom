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

  /// Where it's earned, as the tower names its rooms and floors ("Room 7", "Floor 2").
  static String where(Skill skill) =>
      earnedIn(skill)
          .replaceFirst('Mission', 'Room')
          .replaceFirst('Chapter', 'Floor');

  /// The skill's glyph on its Daylight badge.
  static IconData icon(Skill skill) => switch (skill) {
    Skill.clearIntroductions => PhosphorBold.hand,
    Skill.evidenceBuilder => PhosphorFill.chartBar,
    Skill.conflictNavigator => PhosphorBold.handshake,
    Skill.thinkUnderPressure => PhosphorBold.lightning,
  };

  /// The order they're earned in, as the campaign runs.
  static const List<Skill> order = [
    Skill.clearIntroductions,
    Skill.evidenceBuilder,
    Skill.conflictNavigator,
    Skill.thinkUnderPressure,
  ];
}

/// One skill as a small arch medal (Daylight, brief 48): the skill's glyph on the floor's deep
/// colour inside a honey rim once earned; a sand arch with a muted glyph until then. No
/// initials: the glyph and, where there's room, the name beside it say which skill it is.
/// It reads on paper, on white and on a dark panel alike (the debrief's unlock card).
class SkillBadge extends StatelessWidget {
  const SkillBadge({
    super.key,
    required this.skill,
    required this.earned,
    this.size = defaultSize,
    this.floor = DaylightFloors.one,
  });

  final Skill skill;
  final bool earned;

  /// The arch's width; it stands a fifth taller.
  final double size;
  final FloorColours floor;

  static const double defaultSize = 44;
  static const double _aspect = 1.2;
  static const double _rimShare = 0.08;
  static const double _iconShare = 0.46;

  @override
  Widget build(BuildContext context) {
    final label = earned
        ? '${SkillCopy.name(skill)}, earned'
        : '${SkillCopy.name(skill)}, earned in ${SkillCopy.earnedIn(skill)}';
    final radius = BorderRadius.vertical(
      top: const Radius.circular(DaylightRadius.archTop),
      bottom: Radius.circular(size * _rimShare * 2),
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size * _aspect,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: earned ? floor.deep : DaylightColors.sand,
            borderRadius: radius,
            border: Border.all(
              color: earned ? DaylightColors.honey : DaylightColors.sand2,
              width: size * _rimShare,
            ),
          ),
          child: Center(
            child: Icon(
              SkillCopy.icon(skill),
              size: size * _iconShare,
              color: earned ? DaylightColors.honey : DaylightColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
