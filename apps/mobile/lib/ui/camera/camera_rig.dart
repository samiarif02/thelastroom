import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'camera_shot.dart';

/// Frames a layered set between its wide shot and its close-up, driven by the caller's clock:
/// [t] 0 is wide, 1 is close. Layers are painted back to front.
///
/// Under reduced motion there is no move: each layer cross-fades between its two framings
/// (docs/rules/components.md).
class CameraRig extends StatelessWidget {
  const CameraRig({super.key, required this.t, required this.layers});

  final double t;

  /// Back to front.
  final List<CameraLayer> layers;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final layer in layers)
          if (still)
            Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 1 - t,
                  child: Framed(shot: layer.wide, child: layer.child),
                ),
                Opacity(
                  opacity: t,
                  child: Framed(shot: layer.close, child: layer.child),
                ),
              ],
            )
          else
            Framed(
              shot: CameraShot.lerp(layer.wide, layer.close, t),
              child: layer.child,
            ),
      ],
    );
  }
}

/// The dolly push: [CameraRig] with its own clock. Set [closeUp] and the camera glides in over
/// [BrandMotion.dolly] (or back out), with [onPushStart] and [onPushEnd] for sound.
class DollyCamera extends StatefulWidget {
  const DollyCamera({
    super.key,
    required this.closeUp,
    required this.layers,
    this.onPushStart,
    this.onPushEnd,
  });

  final bool closeUp;
  final List<CameraLayer> layers;
  final VoidCallback? onPushStart;
  final VoidCallback? onPushEnd;

  @override
  State<DollyCamera> createState() => _DollyCameraState();
}

class _DollyCameraState extends State<DollyCamera>
    with SingleTickerProviderStateMixin {
  late final AnimationController _push = AnimationController(
    vsync: this,
    value: widget.closeUp ? 1 : 0,
  );

  @override
  void didUpdateWidget(DollyCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.closeUp == widget.closeUp) return;
    final still = MediaQuery.disableAnimationsOf(context);
    widget.onPushStart?.call();
    _push
        .animateTo(
          widget.closeUp ? 1 : 0,
          duration: still ? BrandMotion.reducedMotionFade : BrandMotion.dolly,
          curve: still ? Curves.linear : BrandMotion.dollyCurve,
        )
        .whenCompleteOrCancel(() {
          if (mounted) widget.onPushEnd?.call();
        });
  }

  @override
  void dispose() {
    _push.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _push,
    builder: (context, _) => CameraRig(t: _push.value, layers: widget.layers),
  );
}

/// [child] seen through one [CameraShot].
class Framed extends StatelessWidget {
  const Framed({super.key, required this.shot, required this.child});

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
