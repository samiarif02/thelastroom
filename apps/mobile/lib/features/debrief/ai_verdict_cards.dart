import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart' show Tag, TagTone;
import '../../ui/film_kit.dart';
import 'ai_score.dart';
import 'debrief_facts.dart';
import 'red_pen_slip.dart';

/// While the AI recruiter grades the answer: the panel deliberating, in Daylight. Three honey
/// lights pulse in turn; under reduced motion they hold still. At most [AiScorer.timeout] long.
class DeliberatingCard extends StatelessWidget {
  const DeliberatingCard({super.key, this.grade = ChapterGrade.lobby});

  final ChapterGrade grade;

  static const String title = 'The panel is deliberating…';
  static const String line =
      'A senior recruiter is reading your answer and your reasons.';

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: title,
    child: PaperSlip(
      grade: grade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingLights(grade: grade),
          const SizedBox(height: DaylightSpace.s16),
          ExcludeSemantics(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: DaylightType.heading6,
            ),
          ),
          const SizedBox(height: DaylightSpace.s8),
          Text(line, textAlign: TextAlign.center, style: DaylightType.body5),
        ],
      ),
    ),
  );
}

class _PulsingLights extends StatelessWidget {
  const _PulsingLights({required this.grade});

  final ChapterGrade grade;

  static const int _count = 3;
  static const double _size = 10;
  static const double _period = 1.2;
  static const double _dim = 0.25;

  @override
  Widget build(BuildContext context) {
    final clock = AmbientClock.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      builder: (context, seconds, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s4),
              child: Opacity(
                opacity: _lit(seconds, i),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DaylightColors.honey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Each light peaks a third of a period after the one before.
  double _lit(double seconds, int i) {
    final phase = (seconds / _period - i / _count) % 1;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return _dim + (1 - _dim) * wave;
  }
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
