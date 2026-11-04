import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart'
    show Tactile, TactileStyle, Tag, TagTone;
import 'ai_score.dart';
import 'debrief_facts.dart';
import 'red_pen_slip.dart';

/// The recruiter's verdict came after the offline score was already on the sheet (the AI was
/// slower than [AiScorer.timeout]): a quiet card at the foot of the screen, once the sheet has
/// played, that swaps the recruiter's numbers in when tapped. Never a swap on its own, so the
/// numbers the player is reading don't change under them.
class LateVerdictBanner extends StatelessWidget {
  const LateVerdictBanner({
    super.key,
    required this.onTap,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onTap;
  final ChapterGrade grade;

  static const String title = "The recruiter's score is ready";
  static const String hint = 'Tap to see it';

  static const double _glyph = 20;
  static const double _tile = 40;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Tactile(
      label: '$title. $hint',
      onTap: onTap,
      style: TactileStyle(
        face: DaylightColors.raised,
        edge: DaylightColors.honeyEdge,
        radius: BorderRadius.circular(DaylightRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Row(
          children: [
            Container(
              width: _tile,
              height: _tile,
              decoration: BoxDecoration(
                color: DaylightColors.honeyTint,
                borderRadius: BorderRadius.circular(DaylightRadius.inner),
              ),
              child: const Icon(
                PhosphorBold.sparkle,
                size: _glyph,
                color: DaylightColors.honeyInk,
              ),
            ),
            const SizedBox(width: DaylightSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: DaylightType.body4),
                  Text(
                    hint,
                    style: DaylightType.caption4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorBold.arrowRight,
              size: _glyph,
              color: grade.floor.deep,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Above the dossier: who scored it. "Scored by AI · Senior recruiter", or "Offline score" when
/// the engine's fixed parameters stand in (no backend, no network, a timeout, an error).
class ScoreSourceLabel extends StatelessWidget {
  const ScoreSourceLabel({
    super.key,
    required this.ai,
    this.grade = ChapterGrade.lobby,
  });

  final bool ai;
  final ChapterGrade grade;

  static const String aiLabel = 'Scored by AI · Senior recruiter';
  static const String offlineLabel = 'Offline score';

  @override
  Widget build(BuildContext context) => Tag(
    label: ai ? aiLabel : offlineLabel,
    icon: ai ? PhosphorBold.sparkle : PhosphorBold.wifiSlash,
    tone: ai ? TagTone.honey : TagTone.sand,
  );
}

/// Under the dossier when the AI scored it: the basis for every number, one sentence each.
/// A score and its reason, never advice (brief 22: not a coach).
class AiBasisSlip extends StatelessWidget {
  const AiBasisSlip({
    super.key,
    required this.score,
    this.grade = ChapterGrade.lobby,
  });

  final AiScore score;
  final ChapterGrade grade;

  static const String heading = 'Why these scores';
  static const String overallLabel = 'Overall';

  @override
  Widget build(BuildContext context) => PaperSlip(
    grade: grade,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            heading,
            style: SlipType.label.copyWith(color: SlipInk.soft),
          ),
        ),
        for (final d in Dimension.values)
          _Row(
            label: dimensionLabel(d),
            graded: score.dimensions[d]!,
            grade: grade,
          ),
        _Row(label: overallLabel, graded: score.overall, grade: grade),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.graded, required this.grade});

  final String label;
  final AiGraded graded;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: DaylightSpace.s16),
    child: Semantics(
      label: '$label ${graded.score} out of 100. ${graded.basis}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: DaylightType.caption3.copyWith(
                    color: grade.floor.deep,
                  ),
                ),
              ),
              Text(
                '${graded.score}',
                style: DaylightType.body2.copyWith(color: SlipInk.text),
              ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s4),
          Text(
            graded.basis,
            style: SlipType.body.copyWith(color: SlipInk.text),
          ),
        ],
      ),
    ),
  );
}
