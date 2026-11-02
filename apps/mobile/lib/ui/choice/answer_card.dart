import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../vivid/pressable.dart';

/// The five states of an answer card.
enum AnswerCardState {
  /// Offered, waiting.
  idle,

  /// Under the finger, the pointer or keyboard focus. An idle card shows this by itself on
  /// hover, focus and press; pass it to force the look (the catalog).
  focused,

  /// Picked, but the player can still change their mind.
  selected,

  /// The committed answer: lit, sealed with a brass bar, no longer tappable.
  locked,

  /// Not available: the other answers once one is locked, or before the question lands.
  disabled,
}

/// An answer as a vivid card (brief 23: the mission's `ChoiceCard` look, everywhere): the
/// chapter's gradient lifted off the sky with a soft deep shadow, the italic numeral in soft
/// white. Focused, its edge brightens; selected, a sunflower ring lights it; locked, the
/// ring holds and a sunflower bar marks it; disabled, it fades back. It sinks under the finger
/// (`Pressable`). At least [BrandSpace.minTarget] tall; the text wraps (2x text grows the card,
/// never clips it).
class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.numeral,
    required this.text,
    this.state = AnswerCardState.idle,
    this.grade = ChapterGrade.lobby,
    this.onTap,
  });

  /// "i.", "ii.", "iii." (see [numeralFor]).
  final String numeral;
  final String text;
  final AnswerCardState state;
  final ChapterGrade grade;

  /// Ignored when [state] is locked or disabled. Null makes the card inert.
  final VoidCallback? onTap;

  /// The italic roman numeral for the card at [index] (0-based).
  static String numeralFor(int index) => '${_romans[index]}.';

  static const List<String> _romans = ['i', 'ii', 'iii', 'iv', 'v', 'vi'];

  static const double _radius = 18;
  static const double _ring = 2;
  static const double _bar = 4;
  static const double _numeralWidth = 30;
  static const double _disabledOpacity = 0.4;
  static const double _focusedEdge = 0.55;

  bool get _interactive =>
      onTap != null &&
      state != AnswerCardState.locked &&
      state != AnswerCardState.disabled;

  @override
  Widget build(BuildContext context) {
    final lit =
        state == AnswerCardState.selected || state == AnswerCardState.locked;
    final focused = state == AnswerCardState.focused;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? BrandMotion.quick
        : BrandMotion.standard;
    final card = AnimatedOpacity(
      duration: duration,
      opacity: state == AnswerCardState.disabled ? _disabledOpacity : 1,
      child: AnimatedContainer(
        duration: duration,
        curve: BrandMotion.enter,
        constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: grade.cardGradient,
          ),
          border: Border.all(
            color: lit
                ? BrandVivid.accent
                : BrandVivid.hairline(focused ? _focusedEdge : 0.18),
            width: lit || focused ? _ring : 1,
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
                              // Glow isn't AA on a card's lit side in every theme; soft white is (brief 31).
                              color: lit
                                  ? BrandVivid.accent
                                  : BrandVivid.onDeepSoft,
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
    return Pressable(
      label: '$numeral $text',
      selected: lit,
      onTap: _interactive ? onTap : null,
      child: card,
    );
  }
}
