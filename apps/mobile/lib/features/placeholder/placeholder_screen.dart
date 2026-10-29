import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// Foundation placeholder: proves the app boots on every platform with the brand theme.
/// Replaced by the splash and intro in the design session.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  static const String title = 'THE LAST ROOM';
  static const String tagline = 'One room left between you and the offer.';
  static const String eyebrow = 'NORTHSTAR LABS';

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ColoredBox(
      color: BrandColors.void_,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The spotlight: a soft pool of the chapter's key light falling from above.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.1),
                radius: 1.1,
                colors: [grade.key.withValues(alpha: 0.22), BrandColors.clear],
              ),
            ),
          ),
          // The vignette: edges fall to the grade's shadow colour.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.2,
                colors: [
                  BrandColors.clear,
                  grade.shadow.withValues(alpha: 0.9),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
          // Scrolls only when large text doesn't fit (brief §9: text survives font scaling).
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: BrandSpace.lg),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: reduceMotion
                      ? BrandMotion.reducedMotionFade
                      : BrandMotion.titleCard,
                  curve: BrandMotion.enter,
                  builder: (context, t, child) =>
                      Opacity(opacity: t, child: child),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BrandSpace.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(eyebrow, style: BrandType.label),
                        const SizedBox(height: BrandSpace.md),
                        Semantics(
                          header: true,
                          child: const Text(
                            title,
                            style: BrandType.titleCard,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: BrandSpace.md),
                        const Text(
                          tagline,
                          style: BrandType.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
