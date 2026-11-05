import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../leaderboard/league_badge.dart';
import 'explainer_art.dart';
import 'explainer_copy.dart';

/// Page 3: a still of a Candidate assessment, drawn from the Daylight kit with an example's
/// numbers. It is a picture of the sheet, not the sheet: the debrief's `ui/paper` widgets are
/// left alone.
class ScoreArt extends StatelessWidget {
  const ScoreArt({super.key});

  static const double _dial = 88;

  @override
  Widget build(BuildContext context) {
    const f = DaylightFloors.three;
    return ExplainerArt(
      label: ExplainerCopy.scoreArt,
      child: DaylightPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ExplainerCopy.sheetTitle,
                        style: DaylightType.heading6,
                      ),
                      const SizedBox(height: DaylightSpace.s4),
                      const Tag(
                        label: ExplainerCopy.scoredBy,
                        icon: PhosphorBold.sparkle,
                        tone: TagTone.honey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DaylightSpace.s12),
                const ScoreDial(
                  score: ExplainerCopy.exampleTotal,
                  size: _dial,
                  floor: f,
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s16),
            for (final (i, d) in ExplainerCopy.dimensions.indexed) ...[
              if (i > 0) const SizedBox(height: DaylightSpace.s12),
              DimensionRow(
                name: d.name,
                score: d.score,
                basis: d.basis,
                weakest: d.name == ExplainerCopy.weakest,
                floor: f,
                delay: DaylightMotion.stagger * (i + 1),
              ),
            ],
            const SizedBox(height: DaylightSpace.s16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Tag(
                label: ExplainerCopy.offline,
                icon: PhosphorBold.wifiSlash,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 4: the Recall schedule (day 1, day 3, day 7, each a stop on one track) and the note
/// Priya brings back, with the one-reminder promise.
class RecallArt extends StatelessWidget {
  const RecallArt({super.key});

  static const double _stop = 40;
  static const double _track = 8;

  /// Three equal columns: the first stop's centre to the last's is two thirds of the width.
  static const double _trackShare = 2 / 3;
  static const double _iconSize = 18;
  static const double _portrait = 56;
  static const double _portraitHeight = 68;

  @override
  Widget build(BuildContext context) => ExplainerArt(
    label: ExplainerCopy.recallArt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DaylightPanel(
          child: Stack(
            children: [
              // One track through the three stops: centre of the first to centre of the last.
              const Positioned(
                top: _stop / 2 - _track / 2,
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: _trackShare,
                  child: ProgressTrack(
                    value: 1,
                    fill: DaylightColors.recallSoft,
                    track: DaylightColors.recallTint,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final day in ExplainerCopy.recallDays)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: _stop,
                            height: _stop,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: DaylightColors.recall,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              PhosphorBold.arrowCounterClockwise,
                              size: _iconSize,
                              color: DaylightColors.raised,
                            ),
                          ),
                          const SizedBox(height: DaylightSpace.s4),
                          Text(
                            day,
                            textAlign: TextAlign.center,
                            style: DaylightType.caption3.copyWith(
                              color: DaylightColors.recallDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DaylightSpace.s16),
        DaylightPanel(
          color: DaylightColors.recallTint,
          child: Row(
            children: [
              const ArchPortrait(
                person: CastPeople.priya,
                expression: CastExpression.smile,
                width: _portrait,
                height: _portraitHeight,
                ground: DaylightColors.recallSoft,
                idle: false,
              ),
              const SizedBox(width: DaylightSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ExplainerCopy.recallNote, style: DaylightType.body2),
                    const SizedBox(height: DaylightSpace.s8),
                    const Tag(
                      label: ExplainerCopy.reminderTag,
                      icon: PhosphorBold.bell,
                      tone: TagTone.raised,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Page 5: what climbing earns. XP for the week, the five leagues from Bronze to Diamond, and
/// a skill on the shelf.
class RewardsArt extends StatelessWidget {
  const RewardsArt({super.key});

  static const double _badge = 40;

  @override
  Widget build(BuildContext context) => ExplainerArt(
    label: ExplainerCopy.rewardsArt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DaylightPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Wrap(
                spacing: DaylightSpace.s8,
                runSpacing: DaylightSpace.s8,
                children: [
                  Tag(
                    label: ExplainerCopy.xpTag,
                    icon: PhosphorBold.lightning,
                    tone: TagTone.honeySolid,
                  ),
                  Tag(
                    label: ExplainerCopy.weekTag,
                    icon: PhosphorBold.calendarBlank,
                  ),
                ],
              ),
              const SizedBox(height: DaylightSpace.s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final league in League.values)
                    Flexible(
                      child: Column(
                        children: [
                          LeagueBadge(
                            league: league,
                            size: _badge,
                            label: false,
                          ),
                          const SizedBox(height: DaylightSpace.s4),
                          Text(
                            league.title,
                            textAlign: TextAlign.center,
                            style: DaylightType.caption4.copyWith(
                              color: DaylightColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DaylightSpace.s16),
        const Center(
          child: SkillBadge(
            icon: PhosphorFill.chartBar,
            name: ExplainerCopy.skillName,
            hint: ExplainerCopy.skillHint,
            state: SkillState.earned,
          ),
        ),
      ],
    ),
  );
}
