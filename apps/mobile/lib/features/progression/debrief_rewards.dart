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
import '../../ui/daylight/daylight_kit.dart';
import 'progression.dart';
import 'skill_badges.dart' show SkillCopy;

/// The debrief's reward moment (brief 32): "+N XP" for the attempt, and, the first time a skill
/// is demonstrated, a "Skill unlocked" card with its sound and `skill_unlocked`. Each skill is
/// celebrated once, ever; the card stays for this debrief.
class DebriefRewards extends ConsumerStatefulWidget {
  const DebriefRewards({
    super.key,
    required this.mission,
    required this.grade,
    this.ready = true,
  });

  final Mission mission;
  final ChapterGrade grade;

  /// The debrief has settled, so the attempt is stored and progression has been read again:
  /// only then is what to celebrate decided. Until then the tower's progress card can still
  /// hold the reading from before this mission (brief 44: every debrief showed the first
  /// mission's XP, and later skills were never celebrated).
  final bool ready;

  static String xpGained(int xp) => '+$xp XP';
  static const String unlockedKicker = 'Skill unlocked';

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
    final reading = ref.watch(progressionProvider);
    final p = reading.value;
    // Never a number from before this attempt: nothing while it's being read again.
    if (p == null || reading.isLoading) return const SizedBox.shrink();
    if (_celebrating == null && widget.ready) {
      final fresh = p.uncelebrated;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _celebrating == null) setState(() => _celebrate(fresh));
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Tag(
            label: DebriefRewards.xpGained(p.lastXp),
            icon: PhosphorFill.lightning,
            tone: TagTone.honeySolid,
          ),
        ),
        for (final s in _celebrating ?? const <Skill>{}) ...[
          const SizedBox(height: DaylightSpace.s16),
          Entrance(
            child: Semantics(
              liveRegion: true,
              child: DaylightPanel(
                color: DaylightColors.honeyTint,
                edge: DaylightColors.honey,
                child: Row(
                  children: [
                    // The skill's enamel arch, as on the tower's shelf.
                    SizedBox(
                      width: _badge,
                      height: _badge * _aspect,
                      child: ArchFrame(
                        ground: widget.grade.floor.deep,
                        border: _rim,
                        borderColor: DaylightColors.honey,
                        child: Icon(
                          SkillCopy.icon(s),
                          size: _badge * _glyph,
                          color: DaylightColors.honey,
                        ),
                      ),
                    ),
                    const SizedBox(width: DaylightSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DebriefRewards.unlockedKicker,
                            style: DaylightType.caption3.copyWith(
                              color: DaylightColors.honeyInk,
                            ),
                          ),
                          const SizedBox(height: DaylightSpace.s4),
                          Text(SkillCopy.name(s), style: DaylightType.heading6),
                          Text(
                            SkillCopy.meaning(s),
                            style: DaylightType.body5.copyWith(
                              color: DaylightColors.ink2,
                            ),
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

  static const double _badge = 48;
  static const double _aspect = 76 / 64;
  static const double _rim = 3;
  static const double _glyph = 0.44;
}
