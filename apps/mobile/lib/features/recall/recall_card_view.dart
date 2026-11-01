import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/choice/answer_card.dart';
import '../../ui/vivid/staggered_entrance.dart';
import '../../ui/vivid/vivid_button.dart';
import '../../ui/vivid/vivid_panel.dart';
import 'recall_controller.dart';
import 'recall_deck.dart';

/// One card of a round: the misconception (or the lesson's question) on a lit panel, the
/// choices as the mission's answer cards, one tap to answer, then what it meant and "Next".
class RecallCardView extends StatelessWidget {
  const RecallCardView({
    super.key,
    required this.playing,
    required this.onAnswer,
    required this.onNext,
  });

  final RecallPlaying playing;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;

  static const String next = 'Next';
  static const String finish = 'Finish';
  static const String known = 'Right. This card moves up a box.';
  static const String guessed =
      "Right, but that was a guess. It'll come back tomorrow.";
  static const String missed = "Not quite. Here's the one that holds.";

  static String verdictLine(RecallVerdict verdict) => switch (verdict) {
    RecallVerdict.known => known,
    RecallVerdict.guessed => guessed,
    RecallVerdict.missed => missed,
  };

  AnswerCardState _stateOf(RecallQuestion q, RecallChoice choice) {
    if (!playing.answered) return AnswerCardState.idle;
    if (choice.id == q.correctChoiceId) return AnswerCardState.locked;
    // A wrong pick keeps a bright edge but no sunflower: the sunflower ring is the right answer's
    // alone, so the two never look alike (brief 23).
    if (choice.id == playing.chosenId) return AnswerCardState.focused;
    return AnswerCardState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final q = playing.question;
    final grade = q.kind == RecallCardKind.trap
        ? ChapterGrade.lobby
        : ChapterGrade.pressure;
    final last = playing.index == playing.round.length - 1;
    final verdict = playing.verdict;
    return Column(
      key: ValueKey(q.cardId),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggeredEntrance(
          index: 0,
          child: VividPanel(
            colors: grade.cardGradient,
            glow: grade.glow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.kicker, style: BrandVividType.kicker),
                const SizedBox(height: BrandSpace.sm),
                Semantics(
                  header: true,
                  child: Text(
                    q.kind == RecallCardKind.trap ? '“${q.prompt}”' : q.prompt,
                    style: BrandVividType.title,
                  ),
                ),
                if (q.quote case final quote?) ...[
                  const SizedBox(height: BrandSpace.sm),
                  Text(
                    'It led you to: “$quote”',
                    style: BrandVividType.body.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: BrandSpace.md),
                Text(q.ask, style: BrandVividType.row),
              ],
            ),
          ),
        ),
        const SizedBox(height: BrandSpace.md),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: BrandSpace.sm),
            child: StaggeredEntrance(
              index: i + 1,
              child: AnswerCard(
                numeral: AnswerCard.numeralFor(i),
                text: q.choices[i].text,
                grade: grade,
                state: _stateOf(q, q.choices[i]),
                onTap: playing.answered
                    ? null
                    : () => onAnswer(q.choices[i].id),
              ),
            ),
          ),
        if (verdict != null) ...[
          const SizedBox(height: BrandSpace.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              verdictLine(verdict),
              style: BrandVividType.row.copyWith(
                color: verdict == RecallVerdict.known
                    ? BrandVivid.accent
                    : BrandVivid.onDeep,
              ),
            ),
          ),
          if (q.takeaway case final takeaway?) ...[
            const SizedBox(height: BrandSpace.xs),
            Text(takeaway, style: BrandVividType.body),
          ],
          const SizedBox(height: BrandSpace.md),
          VividButton(label: last ? finish : next, onPressed: onNext),
        ],
      ],
    );
  }
}
