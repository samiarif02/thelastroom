import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';

/// How a [Tactile] looks: its face, the hard edge under it, its corners, and the ring it gains
/// when selected.
@immutable
class TactileStyle {
  const TactileStyle({
    required this.face,
    required this.edge,
    required this.radius,
    this.depth = DaylightSize.edge,
    this.ring,
  });

  final Color face;
  final Color edge;
  final BorderRadius radius;

  /// How deep the edge is, and how far the face sinks when pressed.
  final double depth;

  /// A 2 px ring round the face (a selected card).
  final Color? ring;
}

/// Anything pressable in Daylight: a flat face on a hard edge (no drop shadow). Pressed, the face
/// sinks [TactileStyle.depth] onto its edge over [DaylightMotion.press] (transform only); under
/// reduced motion it just darkens a touch. A light haptic on press, a visible focus ring for the
/// keyboard, a 48 dp minimum target, and a button to screen readers. Null [onTap] is disabled:
/// the caller picks the disabled style.
class Tactile extends StatefulWidget {
  const Tactile({
    super.key,
    required this.style,
    required this.child,
    required this.onTap,
    required this.label,
    this.lift = 0,
    this.pressed,
    this.selected,
    this.haptic = true,
  });

  final TactileStyle style;
  final Widget child;
  final VoidCallback? onTap;

  /// What a screen reader announces.
  final String label;

  /// How far the face rises off its edge (a selected card lifts 2).
  final double lift;

  /// Forces the pressed look (the catalog's still of a press); null follows the finger.
  final bool? pressed;

  /// For choices: whether it's the picked one (null: not a choice).
  final bool? selected;
  final bool haptic;

  /// The focus ring's width and its gap from the face.
  static const double focusRing = 2;
  static const double focusGap = 2;

  @override
  State<Tactile> createState() => _TactileState();
}

class _TactileState extends State<Tactile> {
  bool _down = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _tap() {
    if (!_enabled) return;
    if (widget.haptic) pressTap();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final s = widget.style;
    final down = widget.pressed ?? _down;
    final sink = down ? s.depth : -widget.lift;
    final ring = s.ring;
    final face = DecoratedBox(
      decoration: BoxDecoration(color: s.face, borderRadius: s.radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: s.radius,
          border: ring == null
              ? null
              : Border.all(color: ring, width: Tactile.focusRing),
          // Under reduced motion the press reads as a shade, not a move.
          color: down && still
              ? DaylightColors.shadow.withValues(alpha: 0.08)
              : null,
        ),
        position: DecorationPosition.foreground,
        child: widget.child,
      ),
    );
    final body = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: s.depth,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(color: s.edge, borderRadius: s.radius),
          ),
        ),
        if (_focused)
          Positioned(
            left: -Tactile.focusRing - Tactile.focusGap,
            right: -Tactile.focusRing - Tactile.focusGap,
            top: -Tactile.focusRing - Tactile.focusGap,
            bottom: -Tactile.focusRing - Tactile.focusGap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    s.radius + BorderRadius.circular(Tactile.focusGap),
                border: Border.all(
                  color: DaylightColors.ink,
                  width: Tactile.focusRing,
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: s.depth),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: still ? 0 : sink),
            duration: DaylightMotion.press,
            curve: DaylightMotion.ease,
            builder: (context, dy, child) =>
                Transform.translate(offset: Offset(0, dy), child: child),
            child: face,
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      focusable: _enabled ? true : null,
      label: widget.label,
      excludeSemantics: true,
      onTap: _enabled ? _tap : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
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
          onTapDown: _enabled ? (_) => _set(true) : null,
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: _enabled ? _tap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: DaylightSize.hit,
              minHeight: DaylightSize.hit,
            ),
            // Its own size, centred in the target: the target never stretches the edge.
            child: Align(widthFactor: 1, heightFactor: 1, child: body),
          ),
        ),
      ),
    );
  }
}
