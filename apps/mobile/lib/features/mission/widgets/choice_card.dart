import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// A line the player can say (an answer, a reply or a reason), as a vivid card lifted off the
/// chapter's colour (brief 17's look): the chapter's gradient, a soft deep shadow, the numeral
/// in the chapter's glow. Picked, it lights with a sunflower ring; said, the ring holds and a
/// sunflower bar marks it; the others fade back.
///
/// [state] reuses the kit's [AnswerCardState]; one tap ([onTap]) is all it takes. Wraps its
/// text (2x text grows the card, never clips it).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.numeral,
    required this.text,
    required this.grade,
    this.state = AnswerCardState.idle,
    this.onTap,
  });

  final String numeral;
  final String text;
  final ChapterGrade grade;
  final AnswerCardState state;

  /// Ignored when [state] is locked or disabled.
  final VoidCallback? onTap;

  static const double _radius = 18;
  static const double _ring = 2;
  static const double _bar = 4;
  static const double _numeralWidth = 30;
  static const double _disabledOpacity = 0.4;

  bool get _interactive =>
      onTap != null &&
      state != AnswerCardState.locked &&
      state != AnswerCardState.disabled;

  @override
  Widget build(BuildContext context) {
    final lit =
        state == AnswerCardState.selected || state == AnswerCardState.locked;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? BrandMotion.quick
        : BrandMotion.standard;
    final card = AnimatedOpacity(
      duration: duration,
      opacity: state == AnswerCardState.disabled ? _disabledOpacity : 1,
      child: AnimatedContainer(
        duration: duration,
        curve: BrandMotion.enter,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: grade.cardGradient,
          ),
          border: Border.all(
            color: lit ? BrandVivid.accent : BrandVivid.hairline(),
            width: lit ? _ring : 1,
          ),
          boxShadow: lit
              ? BrandVivid.glowShadow(BrandVivid.accent)
              : BrandVivid.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius - _ring),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: state == AnswerCardState.locked ? _bar : 0,
                  color: BrandVivid.accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BrandSpace.md,
                      vertical: BrandSpace.sm + BrandSpace.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _numeralWidth,
                          child: Text(
                            numeral,
                            style: BrandVividType.row.copyWith(
                              color: lit ? BrandVivid.accent : grade.glow,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Expanded(child: Text(text, style: BrandVividType.row)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: lit,
      child: Pressable(
        label: '$numeral $text',
        onTap: _interactive ? onTap : null,
        child: card,
      ),
    );
  }
}
