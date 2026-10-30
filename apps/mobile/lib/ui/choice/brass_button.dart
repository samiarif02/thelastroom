import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';

/// A small engraved brass plate with a tracked caps label: "TRY AGAIN", "BACK TO THE LOBBY".
/// The quiet action under a state scene, never a Material button. The brass brightens on hover,
/// focus and press. At least [BrandSpace.minTarget] in both directions; the label wraps at 2x
/// text rather than clipping.
class BrassButton extends StatefulWidget {
  const BrassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.grade = ChapterGrade.lobby,
  });

  /// Shown in capitals; screen readers get it as written.
  final String label;

  /// Null shows the plate dimmed and inert.
  final VoidCallback? onTap;
  final ChapterGrade grade;

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _lit = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _tap() {
    if (!_enabled) return;
    choiceTick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final brass = widget.grade.key;
    final rule = !_enabled
        ? _ruleDisabled
        : _pressed
        ? _rulePressed
        : _lit
        ? _ruleLit
        : _ruleIdle;
    final plate = AnimatedContainer(
      duration: still ? BrandMotion.quick : BrandMotion.standard,
      curve: BrandMotion.enter,
      constraints: const BoxConstraints(
        minHeight: BrandSpace.minTarget,
        minWidth: BrandSpace.minTarget,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.lg,
        vertical: BrandSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Color.lerp(
          BrandColors.surfaceRaised,
          widget.grade.tint,
          _pressed ? _warmPressed : 0,
        ),
        border: Border.all(color: brass.withValues(alpha: rule)),
        boxShadow: [
          BoxShadow(
            color: brass.withValues(alpha: _lit && _enabled ? _glow : 0),
            blurRadius: _glowBlur,
          ),
        ],
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          widget.label.toUpperCase(),
          textAlign: TextAlign.center,
          style: BrandType.eyebrow.copyWith(
            color: _enabled ? brass : BrandColors.textSecondary,
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: _enabled ? _tap : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _lit = v),
        onShowFocusHighlight: (v) => setState(() => _lit = v),
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
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _enabled ? _tap : null,
          child: Opacity(
            opacity: _enabled ? 1 : _disabledOpacity,
            child: plate,
          ),
        ),
      ),
    );
  }

  static const double _ruleIdle = 0.55;
  static const double _ruleLit = 0.9;
  static const double _rulePressed = 1;
  static const double _ruleDisabled = 0.3;
  static const double _warmPressed = 0.35;
  static const double _glow = 0.25;
  static const double _glowBlur = 16;
  static const double _disabledOpacity = 0.6;
}
