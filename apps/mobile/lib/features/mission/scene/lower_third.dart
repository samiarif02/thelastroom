import 'package:brand/brand.dart';
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
    // On the speech panel: it falls over the interviewer's jacket, and the panel keeps it AA
    // over every cast colour (brief 16).
    child: SpeechPanel(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: BrandType.choice.copyWith(
          color: BrandColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
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

/// Above the reasons, when the interviewer asks why.
const String reasonLabel = 'YOUR REASON';

/// Replaces the label while a pick can still be changed.
const String changeHint = 'TAP ANOTHER LINE TO CHANGE';

/// Lines as engraved plaques, arriving one after another: a beat's answers, a follow-up's
/// replies or the reasons for "why that line?". **One tap picks** ([onPick]); the picked card
/// lights ([selected]) and, once [locked], the others go dark. [onArrived] fires when the last
/// card has arrived: the moment the player can read them all, when the stopwatch starts.
///
/// No instruction text sits under the cards to be scrolled to: the [label] above them says
/// what the cards are, and the screen swaps it for a short hint while a pick can be changed.
class AnswerCards<T extends Object> extends StatelessWidget {
  const AnswerCards({
    super.key,
    required this.label,
    required this.items,
    required this.textOf,
    required this.grade,
    required this.onPick,
    this.selected,
    this.locked,
    this.onArrived,
  });

  final String label;

  /// In the attempt's shuffled order.
  final List<T> items;
  final String Function(T) textOf;
  final ChapterGrade grade;
  final T? selected;
  final T? locked;
  final ValueChanged<T> onPick;
  final VoidCallback? onArrived;

  static const double _stagger = 0.16;
  static const double _arriveFrom = 0.97;

  AnswerCardState _stateOf(T item) {
    if (locked != null) {
      return item == locked ? AnswerCardState.locked : AnswerCardState.disabled;
    }
    return item == selected ? AnswerCardState.selected : AnswerCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: BrandType.label.copyWith(color: grade.key),
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        Timeline(
          duration: BrandMotion.cinematic,
          onFinished: onArrived,
          builder: (context, t, _) {
            final last = items.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : BrandSpace.xs),
                    child: _arrive(
                      cue(
                        t,
                        _stagger * i,
                        1 - _stagger * (last - i),
                        BrandMotion.enter,
                      ),
                      AnswerCard(
                        numeral: AnswerCard.numeralFor(i),
                        text: textOf(items[i]),
                        grade: grade,
                        state: _stateOf(items[i]),
                        onTap: () => onPick(items[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _arrive(double t, Widget card) => Opacity(
    opacity: t,
    child: Transform.scale(scale: mix(_arriveFrom, 1, t), child: card),
  );
}
