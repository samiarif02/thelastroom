import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// A framing of the set: how far in ([scale]), which point of the set the camera is on
/// ([focus]), and where on screen that point ends up ([target]). A wide shot has
/// `target == focus`.
@immutable
class CameraShot {
  const CameraShot({
    this.scale = 1,
    this.focus = Alignment.center,
    Alignment? target,
  }) : target = target ?? focus;

  /// The whole set, unmoved.
  static const CameraShot wide = CameraShot();

  final double scale;
  final Alignment focus;
  final Alignment target;

  static CameraShot lerp(CameraShot a, CameraShot b, double t) => CameraShot(
    scale: lerpDouble(a.scale, b.scale, t)!,
    focus: Alignment.lerp(a.focus, b.focus, t)!,
    target: Alignment.lerp(a.target, b.target, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is CameraShot &&
      other.scale == scale &&
      other.focus == focus &&
      other.target == target;

  @override
  int get hashCode => Object.hash(scale, focus, target);
}

/// One plane of the set, with its own close-up. Parallax comes from giving far layers a
/// gentler [close] than near ones: the window moves less than the person.
@immutable
class CameraLayer {
  const CameraLayer({
    required this.child,
    required this.close,
    this.wide = CameraShot.wide,
  });

  final Widget child;
  final CameraShot wide;
  final CameraShot close;
}
