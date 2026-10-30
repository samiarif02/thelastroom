import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The interviewer's slip clipped under the file: the line that cost the most, quoted and
/// underlined in red pen, the hidden flaw, and the one thing to do next time (FR-15).
class RedPenSlip extends StatelessWidget {
  const RedPenSlip({
    super.key,
    required this.line,
    required this.lesson,
    this.play = true,
  });

  /// The costliest line, as the player picked it.
  final String line;
  final Lesson lesson;

  /// False holds the pen still (before the slip is shown).
  final bool play;

  static const String heading = 'THE LINE THAT COST YOU';
  static const String nextTime = 'NEXT TIME';

  static const double _lessonTitleSize = 24;

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(heading, style: soft),
          const SizedBox(height: BrandSpace.sm),
          Timeline(
            key: ValueKey(play),
            duration: BrandMotion.pen,
            play: play,
            builder: (context, t, child) => Stack(
              clipBehavior: Clip.none,
              children: [
                child!,
                Positioned.fill(
                  child: PenStroke(t: play ? t : 0, path: PenStroke.underline),
                ),
              ],
            ),
            child: Text(
              '“$line”',
              style: BrandType.choice.copyWith(
                color: BrandColors.ink,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: BrandSpace.md),
          Text(
            lesson.flaw,
            style: BrandType.body.copyWith(color: BrandColors.redPen),
          ),
          const SizedBox(height: BrandSpace.md),
          Text(nextTime, style: soft),
          const SizedBox(height: BrandSpace.xs),
          Semantics(
            header: true,
            child: Text(
              lesson.title,
              style: BrandType.display.copyWith(
                color: BrandColors.ink,
                fontSize: _lessonTitleSize,
              ),
            ),
          ),
          const SizedBox(height: BrandSpace.xs),
          Text(
            lesson.takeaway,
            style: BrandType.body.copyWith(color: BrandColors.ink),
          ),
        ],
      ),
    );
  }
}

/// No line had a lesson: the slip says so instead of inventing a fault.
class CleanRunSlip extends StatelessWidget {
  const CleanRunSlip({super.key});

  static const String text =
      'Nothing to mark. Every line answered the question, with your own part in it.';

  @override
  Widget build(BuildContext context) => PaperSlip(
    child: Text(text, style: BrandType.body.copyWith(color: BrandColors.ink)),
  );
}

/// A cream slip of paper on the desk, under the file: the debrief's slips and the progress file's.
class PaperSlip extends StatelessWidget {
  const PaperSlip({super.key, required this.child});

  final Widget child;

  static const double _shadowBlur = 20;
  static const Offset _shadowOffset = Offset(-4, 12);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: BrandColors.paper,
      boxShadow: [
        BoxShadow(
          color: BrandColors.void_.withValues(alpha: 0.7),
          blurRadius: _shadowBlur,
          offset: _shadowOffset,
        ),
      ],
    ),
    child: Padding(padding: const EdgeInsets.all(BrandSpace.md), child: child),
  );
}
