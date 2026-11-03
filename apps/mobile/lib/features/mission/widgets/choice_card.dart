import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/choice/answer_card.dart' show AnswerCardState;
import '../../../ui/daylight/daylight_kit.dart';

/// A line the player can say (an answer, a reply or a reason), as Daylight's pick card
/// (direction.md §2): white on a hard edge, a letter tile (A, B, C) or a principle's icon
/// tile, the line in Body 3. Picked, it lifts with the floor's ring; said, its tile shows a
/// check and the others dim.
///
/// [state] reuses the kit's [AnswerCardState]; one tap ([onTap]) picks, a second says it.
/// Wraps its text (2x text grows the card, never clips it).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.numeral,
    required this.text,
    required this.grade,
    this.state = AnswerCardState.idle,
    this.icon,
    this.onTap,
  });

  /// The card's letter ("A").
  final String numeral;
  final String text;
  final ChapterGrade grade;
  final AnswerCardState state;

  /// A principle's glyph instead of the letter (the reason cards).
  final IconData? icon;

  /// Ignored when [state] is locked or disabled.
  final VoidCallback? onTap;

  /// "A", "B", "C" for the card at [index].
  static String letterFor(int index) => String.fromCharCode(_a + index);
  static const int _a = 65;

  @override
  Widget build(BuildContext context) {
    final pick = switch (state) {
      AnswerCardState.idle || AnswerCardState.focused => PickState.idle,
      AnswerCardState.selected => PickState.selected,
      AnswerCardState.locked => PickState.locked,
      AnswerCardState.disabled => PickState.dimmed,
    };
    final enabled =
        state != AnswerCardState.locked && state != AnswerCardState.disabled;
    return PickCard(
      text: text,
      letter: icon == null ? numeral : null,
      icon: icon,
      lockedIcon: PhosphorBold.check,
      state: pick,
      floor: grade.floor,
      onTap: enabled ? onTap : null,
    );
  }
}
