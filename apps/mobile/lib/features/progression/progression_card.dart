import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/film_kit.dart';
import 'progression.dart';
import 'skill_badges.dart';

/// The player's progress at a glance, on the tower and in Your file (brief 32): XP, the soft
/// weekly goal as a ring, the skill badges (the Evidence Builder badge among them), and the
/// interview countdown when a date is set. Never punishing: a quiet week is just "so far".
class ProgressionCard extends ConsumerWidget {
  const ProgressionCard({super.key});

  static const String kicker = 'YOUR PROGRESS';
  static const String xpLabel = 'XP';
  static const String skills = 'SKILLS';

  static String weekLine(int done, int goal) {
    if (done >= goal) return 'Goal met this week. Anything more is a bonus.';
    if (done == 0) return 'A new week: 0 of $goal sessions so far.';
    return '$done of $goal sessions this week.';
  }

  static String countdown(int days) => switch (days) {
    0 => 'Your interview is today. You are ready.',
    1 => 'Your interview is tomorrow.',
    _ => 'Your interview is in $days days.',
  };

  static const double _ring = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressionProvider).value ?? Progression.empty;
    final today = dayOf(ref.watch(progressionClockProvider)());
    final interview = p.interviewDate;
    final daysLeft = interview == null ? null : today.daysUntil(interview);
    return VividPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(kicker, style: BrandVividType.kicker),
          const SizedBox(height: BrandSpace.sm),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: '${p.xp} $xpLabel',
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${p.xp}',
                          style: BrandVividType.numeral,
                        ),
                        TextSpan(text: ' $xpLabel', style: BrandVividType.row),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                label: weekLine(p.sessionsThisWeek, p.weeklyGoal),
                excludeSemantics: true,
                child: ProgressRing(
                  value: (p.sessionsThisWeek / p.weeklyGoal).clamp(0, 1),
                  color: BrandVivid.accent,
                  size: _ring,
                  child: Text(
                    '${p.sessionsThisWeek}/${p.weeklyGoal}',
                    style: BrandVividType.row,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BrandSpace.xs),
          Text(
            weekLine(p.sessionsThisWeek, p.weeklyGoal),
            style: BrandVividType.body,
          ),
          if (daysLeft != null && daysLeft >= 0) ...[
            const SizedBox(height: BrandSpace.xs),
            Text(countdown(daysLeft), style: BrandVividType.row),
          ],
          const SizedBox(height: BrandSpace.md),
          Text(skills, style: BrandVividType.kicker),
          const SizedBox(height: BrandSpace.sm),
          Wrap(
            spacing: BrandSpace.sm,
            runSpacing: BrandSpace.sm,
            children: [
              for (final s in Skill.values)
                SkillBadge(skill: s, earned: p.unlocked.contains(s)),
            ],
          ),
        ],
      ),
    );
  }
}
