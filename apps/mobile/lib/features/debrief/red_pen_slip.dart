import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
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
    final soft = BrandType.label.copyWith(color: SlipInk.soft);
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
                  child: PenStroke(
                    t: play ? t : 0,
                    path: PenStroke.underline,
                    color: SlipInk.mark,
                  ),
                ),
              ],
            ),
            child: Text(
              '“$line”',
              style: BrandType.choice.copyWith(
                color: SlipInk.text,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: BrandSpace.md),
          Text(
            lesson.flaw,
            style: BrandType.body.copyWith(color: SlipInk.mark),
          ),
          const SizedBox(height: BrandSpace.md),
          Text(nextTime, style: soft),
          const SizedBox(height: BrandSpace.xs),
          Semantics(
            header: true,
            child: Text(
              lesson.title,
              style: BrandType.display.copyWith(
                color: SlipInk.text,
                fontSize: _lessonTitleSize,
              ),
            ),
          ),
          const SizedBox(height: BrandSpace.xs),
          Text(
            lesson.takeaway,
            style: BrandType.body.copyWith(color: SlipInk.text),
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
    child: Text(text, style: BrandType.body.copyWith(color: SlipInk.text)),
  );
}

/// No line had a lesson, but some were guessed: the guess is what cost the points, so that's
/// what the slip says. Never "nothing to mark" over a guessed beat.
class GuessedSlip extends StatelessWidget {
  const GuessedSlip({super.key, required this.beats});

  /// The guessed beats, in order ("the open", "the evidence").
  final List<BeatKind> beats;

  static const String heading = 'WHAT COST YOU';
  static const String takeaway =
      'Read every line before you answer. A line picked before you could have read it earns '
      'nothing, however good it is.';

  static String line(List<BeatKind> beats) {
    final names = [for (final b in beats) 'the ${b.name}'];
    final list = names.length == 1
        ? names.single
        : '${names.take(names.length - 1).join(', ')} and ${names.last}';
    return 'You picked $list before you could have read the options.';
  }

  @override
  Widget build(BuildContext context) => PaperSlip(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: BrandType.label.copyWith(color: SlipInk.soft)),
        const SizedBox(height: BrandSpace.sm),
        Text(line(beats), style: BrandType.body.copyWith(color: SlipInk.mark)),
        const SizedBox(height: BrandSpace.sm),
        Text(takeaway, style: BrandType.body.copyWith(color: SlipInk.text)),
      ],
    ),
  );
}

/// A slip under the file, as a vivid card (brief 17's look): the chapter's deepest colour,
/// lifted off the sky with a soft shadow. Text on it is white; what went wrong is in sunset
/// orange ([SlipInk]).
class PaperSlip extends StatelessWidget {
  const PaperSlip({
    super.key,
    required this.child,
    this.grade = ChapterGrade.lobby,
  });

  final Widget child;
  final ChapterGrade grade;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [grade.deeper, BrandVivid.night],
      ),
      border: Border.all(color: BrandVivid.hairline()),
      boxShadow: BrandVivid.cardShadow,
    ),
    child: Padding(padding: const EdgeInsets.all(BrandSpace.md), child: child),
  );
}

/// The slips' inks on the chapter's deepest colour (each pair AA on `deeper` and on `night`).
abstract final class SlipInk {
  /// Body text and quoted lines.
  static final Color text = BrandVivid.onDeep;

  /// Small caps headings.
  static final Color soft = BrandVivid.onDeepSoft;

  /// What went wrong: the red pen's job, in sunset orange.
  static final Color mark = BrandVivid.horizon;
}
