import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// A framing of the scene: how far in, which point of the set the camera is on ([focus]), and
/// where on screen that point ends up ([target]). A wide shot has `target == focus`.
class CameraShot {
  const CameraShot({
    this.scale = 1,
    this.focus = Alignment.center,
    Alignment? target,
  }) : target = target ?? focus;

  final double scale;
  final Alignment focus;
  final Alignment target;

  static CameraShot lerp(CameraShot a, CameraShot b, double t) => CameraShot(
    scale: lerpDouble(a.scale, b.scale, t)!,
    focus: Alignment.lerp(a.focus, b.focus, t)!,
    target: Alignment.lerp(a.target, b.target, t)!,
  );
}

/// Moves the camera from [wide] to [close] as [t] goes 0 → 1. Under reduced motion there is no
/// move: the two framings cross-fade instead (docs/rules/components.md).
class CameraRig extends StatelessWidget {
  const CameraRig({
    super.key,
    required this.t,
    required this.wide,
    required this.close,
    required this.child,
  });

  final double t;
  final CameraShot wide;
  final CameraShot close;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 1 - t,
            child: _Framed(shot: wide, child: child),
          ),
          Opacity(
            opacity: t,
            child: _Framed(shot: close, child: child),
          ),
        ],
      );
    }
    return _Framed(shot: CameraShot.lerp(wide, close, t), child: child);
  }
}

class _Framed extends StatelessWidget {
  const _Framed({required this.shot, required this.child});

  final CameraShot shot;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final focus = shot.focus.alongSize(size);
        final target = shot.target.alongSize(size);
        final m = Matrix4.translationValues(target.dx, target.dy, 0)
          ..scaleByDouble(shot.scale, shot.scale, 1, 1)
          ..translateByDouble(-focus.dx, -focus.dy, 0, 1);
        return Transform(transform: m, child: child);
      },
    ),
  );
}
