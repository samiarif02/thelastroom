import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'skill_badges.dart' show SkillCopy;

/// The skills shelf on the tower (direction.md §1, mockup `01b`): the four skills as arch
/// badges in the order they're earned. Earned ones are enamel (the floor's deep with a honey
/// glyph), the next one is ringed in honey with where it's earned, the rest wait in sand.
class SkillsShelf extends StatelessWidget {
  const SkillsShelf({super.key, required this.unlocked});

  final Set<Skill> unlocked;

  static const String title = 'Skills';
  static const String allEarned = 'All four earned';
  static String nextIn(Skill s) =>
      'Next one in ${SkillCopy.where(s).toLowerCase()}';

  /// The next skill to earn, or null once all are.
  static Skill? next(Set<Skill> unlocked) {
    for (final s in SkillCopy.order) {
      if (!unlocked.contains(s)) return s;
    }
    return null;
  }

  static const double _badge = 64;

  @override
  Widget build(BuildContext context) {
    final upcoming = next(unlocked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          title: title,
          aside: upcoming == null ? allEarned : nextIn(upcoming),
        ),
        const SizedBox(height: DaylightSpace.s12),
        LayoutBuilder(
          builder: (context, box) {
            // Four across while they fit; at large text they wrap two by two.
            final width = (box.maxWidth / 4 - DaylightSpace.s16).clamp(
              DaylightSpace.s48,
              _badge,
            );
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: DaylightSpace.s16,
              children: [
                for (final s in SkillCopy.order)
                  SkillBadge(
                    icon: SkillCopy.icon(s),
                    name: SkillCopy.name(s),
                    hint: unlocked.contains(s) ? null : SkillCopy.where(s),
                    width: width,
                    state: unlocked.contains(s)
                        ? SkillState.earned
                        : s == upcoming
                        ? SkillState.next
                        : SkillState.locked,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
