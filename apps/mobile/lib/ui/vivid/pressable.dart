import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';

/// Anything tappable on the vivid screens (brief 17: a press state on every tappable): it
/// sinks a little under the finger and springs back, ticks, and is a 44 pt button to screen
/// readers and the keyboard. Null [onTap] is inert (and dimmed by its owner, not here).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.label,
    this.pressedScale = 0.96,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// What a screen reader announces.
  final String label;

  /// How far it sinks while held.
  final double pressedScale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _enabled => widget.onTap != null;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _tap() {
    if (!_enabled) return;
    if (widget.haptic) choiceTick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
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
              minWidth: BrandSpace.minTarget,
              minHeight: BrandSpace.minTarget,
            ),
            child: AnimatedScale(
              scale: _down && !still ? widget.pressedScale : 1,
              duration: BrandMotion.quick,
              curve: BrandMotion.enter,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
