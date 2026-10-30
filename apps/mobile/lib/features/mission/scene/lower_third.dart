import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// The lower third of the frame: subtitles and cards sit low, like film subtitles, and scroll
/// from the top only when they don't fit (2x text on a small phone), so the first card is
/// what's seen first.
class LowerThird extends StatelessWidget {
  const LowerThird({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

/// The question, once it's been asked, as a small reminder above the cards: the subtitle has
/// gone, the way a line of dialogue does, but the player can still see what they're answering.
class QuestionReminder extends StatelessWidget {
  const QuestionReminder({super.key, required this.text, required this.grade});

  final String text;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BrandSpace.sm),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: BrandType.choice.copyWith(
        color: BrandColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

/// "OPEN · 1 OF 3": which beat of the answer the cards build.
String beatLabel(BeatKind kind, int index, int count) =>
    '${_beatNames[kind]}  ·  ${index + 1} OF $count';

const Map<BeatKind, String> _beatNames = {
  BeatKind.open: 'OPEN',
  BeatKind.evidence: 'EVIDENCE',
  BeatKind.land: 'LAND',
};

/// Above the follow-up's replies.
const String replyLabel = 'YOUR REPLY';

/// One beat's lines as engraved plaques, arriving one after another. Tap one to choose it, tap
/// it again to say it; once one is [locked], the others go dark.
class AnswerCards extends StatelessWidget {
  const AnswerCards({
    super.key,
    required this.label,
    required this.options,
    required this.grade,
    required this.selected,
    required this.locked,
    required this.onPick,
    this.hint,
  });

  final String label;

  /// In the attempt's shuffled order.
  final List<AnswerOption> options;
  final ChapterGrade grade;
  final AnswerOption? selected;
  final AnswerOption? locked;
  final ValueChanged<AnswerOption> onPick;

  /// Under the cards while one is selected but not yet said.
  final String? hint;

  static const double _stagger = 0.16;
  static const double _arriveFrom = 0.97;

  AnswerCardState _stateOf(AnswerOption option) {
    if (locked != null) {
      return option == locked
          ? AnswerCardState.locked
          : AnswerCardState.disabled;
    }
    return option == selected ? AnswerCardState.selected : AnswerCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: BrandType.label.copyWith(color: grade.key),
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        Timeline(
          duration: BrandMotion.cinematic,
          builder: (context, t, _) {
            final last = options.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < options.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : BrandSpace.sm),
                    child: _arrive(
                      cue(
                        t,
                        _stagger * i,
                        1 - _stagger * (last - i),
                        BrandMotion.enter,
                      ),
                      AnswerCard(
                        numeral: AnswerCard.numeralFor(i),
                        text: options[i].text,
                        grade: grade,
                        state: _stateOf(options[i]),
                        onTap: () => onPick(options[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Holds its height with no hint, so the cards don't jump when one is chosen.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BrandSpace.lg),
          child: Padding(
            padding: const EdgeInsets.only(top: BrandSpace.sm),
            child: Text(
              hint ?? '',
              textAlign: TextAlign.center,
              style: BrandType.label.copyWith(color: BrandColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _arrive(double t, Widget card) => Opacity(
    opacity: t,
    child: Transform.scale(scale: mix(_arriveFrom, 1, t), child: card),
  );
}
