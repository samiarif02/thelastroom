import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../ui/film_kit.dart';
import 'progression.dart';
import 'skill_badges.dart';

/// The debrief's reward moment (brief 32): "+N XP" for the attempt, and, the first time a skill
/// is demonstrated, a "Skill unlocked" card with its sound and `skill_unlocked`. Each skill is
/// celebrated once, ever; the card stays for this debrief.
class DebriefRewards extends ConsumerStatefulWidget {
  const DebriefRewards({super.key, required this.mission, required this.grade});

  final Mission mission;
  final ChapterGrade grade;

  static String xpGained(int xp) => '+$xp XP';
  static const String unlockedKicker = 'SKILL UNLOCKED';

  @override
  ConsumerState<DebriefRewards> createState() => _DebriefRewardsState();
}

class _DebriefRewardsState extends ConsumerState<DebriefRewards> {
  // The skills this debrief celebrates, kept once known (the record then marks them done).
  Set<Skill>? _celebrating;

  void _celebrate(Set<Skill> skills) {
    _celebrating = skills;
    if (skills.isEmpty) return;
    ref.read(gameSoundsProvider).skillUnlocked();
    final analytics = ref.read(analyticsProvider);
    for (final s in skills) {
      analytics.track(AnalyticsEvent.skillUnlocked, {
        'skill_id': EventValue.name(s),
      });
    }
    unawaited(ref.read(progressionActionsProvider).celebrate(skills));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressionProvider).value;
    if (p == null) return const SizedBox.shrink();
    if (_celebrating == null) {
      final fresh = p.uncelebrated;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _celebrating == null) setState(() => _celebrate(fresh));
      });
    }
    final grade = widget.grade;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BrandVivid.accent,
              borderRadius: BorderRadius.circular(BrandRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandSpace.md,
                vertical: BrandSpace.xs,
              ),
              child: Text(
                DebriefRewards.xpGained(p.lastXp),
                style: BrandVividType.row.copyWith(color: BrandVivid.onAccent),
              ),
            ),
          ),
        ),
        for (final s in _celebrating ?? const <Skill>{}) ...[
          const SizedBox(height: BrandSpace.md),
          StaggeredEntrance(
            index: 0,
            child: Semantics(
              liveRegion: true,
              child: VividPanel(
                colors: grade.cardGradient,
                glow: BrandVivid.accent,
                child: Row(
                  children: [
                    SkillBadge(skill: s, earned: true, size: _badge),
                    const SizedBox(width: BrandSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DebriefRewards.unlockedKicker,
                            style: BrandVividType.kicker.copyWith(
                              color: BrandVivid.accent,
                            ),
                          ),
                          const SizedBox(height: BrandSpace.xs),
                          Text(SkillCopy.name(s), style: BrandVividType.title),
                          Text(
                            SkillCopy.meaning(s),
                            style: BrandVividType.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static const double _badge = 56;
}
