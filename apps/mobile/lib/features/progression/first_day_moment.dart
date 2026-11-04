import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import 'debrief_rewards.dart' show DebriefRewards;
import 'first_day.dart';
import 'skill_badges.dart' show SkillCopy;

/// The first-day moment (brief 61; the reviewer: "as soon as someone opens the app they do the
/// first lesson and their streak goes to one, which is the reason to come back tomorrow"). The
/// room's interviewer smiles in her arch, "Day 1 of your prep", the weekly ring fills its first
/// segment, the XP (and a skill) the room earned, and tomorrow's concrete hook. Gentle: the ring
/// is weekly, nothing is lost by a day off.
class FirstDayMoment extends StatefulWidget {
  const FirstDayMoment({super.key, required this.day, required this.onDone});

  final FirstDay day;
  final VoidCallback onDone;

  static const double _maxWidth = 420;
  static const double _face = 96;
  static const double _faceHeight = 112;
  static const double _ring = 72;

  @override
  State<FirstDayMoment> createState() => _FirstDayMomentState();
}

class _FirstDayMomentState extends State<FirstDayMoment> {
  /// The ring starts empty and fills its first segment once the card is up (motion 6's sweep;
  /// under reduced motion the ring draws full at once).
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _filled = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final floor = day.room.grade.floor;
    final still = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      child: Center(
        // Scrolls when it doesn't fit (2x text on a small phone): the button stays reachable.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DaylightSpace.s16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FirstDayMoment._maxWidth,
            ),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: FirstDay.title,
              child: DaylightPanel(
                edge: null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ArchPortrait(
                        person: CastPeople.byId(day.room.lead.id),
                        expression: CastExpression.smile,
                        width: FirstDayMoment._face,
                        height: FirstDayMoment._faceHeight,
                        ground: floor.soft,
                        semanticLabel: day.room.lead.name,
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s12),
                    Text(
                      FirstDay.kicker,
                      textAlign: TextAlign.center,
                      style: DaylightType.caption3.copyWith(color: floor.deep),
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        FirstDay.title,
                        textAlign: TextAlign.center,
                        style: DaylightType.heading4,
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s8),
                    Text(
                      FirstDay.line(day.weeklyGoal),
                      textAlign: TextAlign.center,
                      style: DaylightType.body6.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: DaylightSpace.s16,
                      runSpacing: DaylightSpace.s12,
                      children: [
                        WeeklyRing(
                          done: _filled || still ? day.sessions : 0,
                          goal: day.weeklyGoal,
                          floor: floor,
                          size: FirstDayMoment._ring,
                          caption: FirstDay.week(day.sessions, day.weeklyGoal),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tag(
                              label: DebriefRewards.xpGained(day.xp),
                              icon: PhosphorFill.lightning,
                              tone: TagTone.honeySolid,
                            ),
                            if (day.skill case final skill?) ...[
                              const SizedBox(height: DaylightSpace.s8),
                              Tag(
                                label: SkillCopy.name(skill),
                                icon: SkillCopy.icon(skill),
                                tone: TagTone.floor(floor),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: DaylightSpace.s16),
                    DaylightPanel(
                      color: DaylightColors.recallTint,
                      edge: null,
                      radius: DaylightRadius.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                PhosphorBold.calendarBlank,
                                size: DaylightSpace.s16,
                                color: DaylightColors.recall,
                              ),
                              const SizedBox(width: DaylightSpace.s4),
                              Text(
                                FirstDay.tomorrowKicker,
                                style: DaylightType.caption3.copyWith(
                                  color: DaylightColors.recall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DaylightSpace.s4),
                          Text(day.tomorrow, style: DaylightType.heading6),
                        ],
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s16),
                    TactileButton(
                      label: FirstDay.done,
                      icon: PhosphorBold.check,
                      onPressed: widget.onDone,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
