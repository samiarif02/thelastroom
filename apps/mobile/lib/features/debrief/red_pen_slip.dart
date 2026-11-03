import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart' show DaylightPanel;
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

  static const String heading = 'The line that cost the most';
  static const String nextTime = 'Next time';

  @override
  Widget build(BuildContext context) {
    final soft = SlipType.label.copyWith(color: SlipInk.soft);
    return PaperSlip(
      trap: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(heading, style: soft.copyWith(color: SlipInk.mark)),
          const SizedBox(height: DaylightSpace.s8),
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
              style: SlipType.quote.copyWith(color: SlipInk.text),
            ),
          ),
          const SizedBox(height: DaylightSpace.s16),
          Text(lesson.flaw, style: SlipType.body.copyWith(color: SlipInk.mark)),
          const SizedBox(height: DaylightSpace.s16),
          Text(nextTime, style: soft),
          const SizedBox(height: DaylightSpace.s4),
          Semantics(
            header: true,
            child: Text(
              lesson.title,
              style: SlipType.title.copyWith(color: SlipInk.text),
            ),
          ),
          const SizedBox(height: DaylightSpace.s4),
          Text(
            lesson.takeaway,
            style: SlipType.body.copyWith(color: SlipInk.text),
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
    child: Text(text, style: SlipType.body.copyWith(color: SlipInk.text)),
  );
}

/// No line had a lesson, but some were guessed: the guess is what cost the points, so that's
/// what the slip says. Never "nothing to mark" over a guessed beat.
class GuessedSlip extends StatelessWidget {
  const GuessedSlip({super.key, required this.beats});

  /// The guessed beats, in order ("the open", "the evidence").
  final List<BeatKind> beats;

  static const String heading = 'What cost you';
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
    trap: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(heading, style: SlipType.label.copyWith(color: SlipInk.mark)),
        const SizedBox(height: DaylightSpace.s8),
        Text(line(beats), style: SlipType.body.copyWith(color: SlipInk.mark)),
        const SizedBox(height: DaylightSpace.s8),
        Text(takeaway, style: SlipType.body.copyWith(color: SlipInk.text)),
      ],
    ),
  );
}

/// A card under the sheet, in Daylight (brief 46, mockup `05`): white on the paper with the
/// sand edge, r24, 16 inside. [trap] is the one card about what cost points ("the line that
/// cost the most"): the trap's clay tint, no edge, never alarm red.
class PaperSlip extends StatelessWidget {
  const PaperSlip({
    super.key,
    required this.child,
    this.grade = ChapterGrade.lobby,
    this.trap = false,
  });

  final Widget child;
  final ChapterGrade grade;
  final bool trap;

  @override
  Widget build(BuildContext context) => DaylightPanel(
    color: trap ? DaylightColors.trapTint : DaylightColors.raised,
    edge: trap ? null : DaylightColors.sand2,
    child: child,
  );
}

/// The cards' inks: ink for what you said and what to do, ink-2 for the small headings, and
/// the trap's clay for what went wrong (AA on white and on its tint).
abstract final class SlipInk {
  /// Body text and quoted lines.
  static const Color text = DaylightColors.ink;

  /// The small headings.
  static const Color soft = DaylightColors.ink2;

  /// What went wrong.
  static const Color mark = DaylightColors.trap;
}

/// The cards' type: a sentence-case kicker, the body, a quoted line, a title.
abstract final class SlipType {
  static final TextStyle label = DaylightType.caption3;
  static final TextStyle body = DaylightType.body5;
  static final TextStyle quote = DaylightType.body2;
  static final TextStyle title = DaylightType.heading6;
}
