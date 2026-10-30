import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';

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

/// An answer as an engraved plaque: walnut, an inset brass hairline, an italic roman numeral.
/// Brass brightens as the card is focused, selected and locked. At least
/// [BrandSpace.minTarget] tall; the text wraps (2x text grows the card, never clips it).
class AnswerCard extends StatefulWidget {
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

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive =>
      widget.onTap != null &&
      widget.state != AnswerCardState.locked &&
      widget.state != AnswerCardState.disabled;

  AnswerCardState get _shown {
    if (widget.state == AnswerCardState.idle &&
        _interactive &&
        (_hovered || _focused || _pressed)) {
      return AnswerCardState.focused;
    }
    return widget.state;
  }

  void _tap() {
    if (!_interactive) return;
    choiceTick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final look = _Look.of(_shown);
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? BrandMotion.quick : BrandMotion.standard;
    final brass = widget.grade.key;
    final plaque = AnimatedOpacity(
      duration: duration,
      opacity: look.opacity,
      child: AnimatedContainer(
        duration: duration,
        curve: BrandMotion.enter,
        padding: const EdgeInsets.all(_bevel),
        decoration: BoxDecoration(
          color: Color.lerp(
            BrandColors.surfaceRaised,
            widget.grade.tint,
            look.warmth,
          )!.withValues(alpha: _walnutAlpha),
          border: Border.all(color: brass.withValues(alpha: look.outer)),
          boxShadow: [
            BoxShadow(
              color: brass.withValues(alpha: look.glow),
              blurRadius: _glowBlur,
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: duration,
          curve: BrandMotion.enter,
          constraints: const BoxConstraints(
            minHeight: BrandSpace.minTarget - _bevel * 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BrandSpace.md,
            vertical: _padY,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: brass.withValues(alpha: look.bar),
                width: look.bar > 0 ? _barWidth : _hairline,
              ),
              top: BorderSide(
                color: brass.withValues(alpha: look.inner),
                width: _hairline,
              ),
              right: BorderSide(
                color: brass.withValues(alpha: look.inner),
                width: _hairline,
              ),
              bottom: BorderSide(
                color: brass.withValues(alpha: look.inner),
                width: _hairline,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _numeralWidth,
                child: Text(
                  widget.numeral,
                  style: BrandType.numeral.copyWith(color: brass),
                ),
              ),
              Expanded(child: Text(widget.text, style: BrandType.choice)),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: _interactive,
      selected:
          widget.state == AnswerCardState.selected ||
          widget.state == AnswerCardState.locked,
      // Only an interactive card is a focus stop; null leaves the flag off entirely.
      focusable: _interactive ? true : null,
      focused: _interactive ? _focused : null,
      label: '${widget.numeral} ${widget.text}',
      excludeSemantics: true,
      onTap: _interactive ? _tap : null,
      child: FocusableActionDetector(
        enabled: _interactive,
        mouseCursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _tap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _interactive
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _interactive ? _tap : null,
          child: plaque,
        ),
      ),
    );
  }

  static const double _bevel = 3;
  static const double _padY = 10;
  static const double _hairline = 0.6;
  static const double _barWidth = 3;
  static const double _numeralWidth = 30;
  static const double _glowBlur = 18;
  static const double _walnutAlpha = 0.92;
}

/// How much brass, warmth and glow each state gets.
class _Look {
  const _Look({
    required this.outer,
    required this.inner,
    required this.bar,
    required this.glow,
    required this.warmth,
    required this.opacity,
  });

  /// Brass alpha on the outer and inner rules, and the locked bar.
  final double outer;
  final double inner;
  final double bar;

  /// The lamp's glow round the plaque.
  final double glow;

  /// How far the walnut warms toward the grade's tint.
  final double warmth;
  final double opacity;

  static _Look of(AnswerCardState state) => switch (state) {
    AnswerCardState.idle => const _Look(
      outer: 0.35,
      inner: 0.14,
      bar: 0,
      glow: 0,
      warmth: 0,
      opacity: 1,
    ),
    AnswerCardState.focused => const _Look(
      outer: 0.7,
      inner: 0.3,
      bar: 0,
      glow: 0.12,
      warmth: 0.15,
      opacity: 1,
    ),
    AnswerCardState.selected => const _Look(
      outer: 0.95,
      inner: 0.5,
      bar: 0,
      glow: 0.22,
      warmth: 0.35,
      opacity: 1,
    ),
    AnswerCardState.locked => const _Look(
      outer: 1,
      inner: 0.6,
      bar: 1,
      glow: 0.3,
      warmth: 0.5,
      opacity: 1,
    ),
    AnswerCardState.disabled => const _Look(
      outer: 0.2,
      inner: 0.08,
      bar: 0,
      glow: 0,
      warmth: 0,
      opacity: 0.42,
    ),
  };
}
