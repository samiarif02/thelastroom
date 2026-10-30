import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// Cinema bars, driven by the caller's clock. [t] 0 is open frame, 1 fully letterboxed. Under
/// reduced motion the bars fade in place rather than slide.
class Letterbox extends StatelessWidget {
  const Letterbox({
    super.key,
    required this.t,
    this.color = BrandColors.void_,
    this.fraction = defaultFraction,
  });

  /// Each bar's height as a share of the screen at full letterbox (roughly 2.39:1 on a phone).
  static const double defaultFraction = 0.13;

  final double t;
  final Color color;
  final double fraction;

  /// One bar's height at progress [t] in a box [height] tall: what content inside the frame
  /// must clear.
  static double barHeight(
    double height,
    double t, {
    double fraction = defaultFraction,
  }) => height * fraction * t;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final height = barHeight(
            box.maxHeight,
            still ? 1 : t,
            fraction: fraction,
          );
          Widget bar() => Opacity(
            opacity: still ? t : 1,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: ColoredBox(color: color),
            ),
          );
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [bar(), bar()],
          );
        },
      ),
    );
  }
}

/// [Letterbox] with its own clock: the bars slide in when [shown] turns true and out when it
/// turns false, over [BrandMotion.letterbox], then [onSettled].
class AnimatedLetterbox extends StatelessWidget {
  const AnimatedLetterbox({
    super.key,
    required this.shown,
    this.color = BrandColors.void_,
    this.fraction = Letterbox.defaultFraction,
    this.onSettled,
  });

  final bool shown;
  final Color color;
  final double fraction;
  final VoidCallback? onSettled;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: shown ? 1 : 0),
      duration: still ? BrandMotion.reducedMotionFade : BrandMotion.letterbox,
      curve: BrandMotion.letterboxCurve,
      onEnd: onSettled,
      builder: (context, t, _) =>
          Letterbox(t: t, color: color, fraction: fraction),
    );
  }
}
