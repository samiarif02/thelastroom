import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../title/title_screen.dart';

/// The title card as the way in: once it has played, "Tap to begin" fades up, and a tap
/// anywhere (also during the card) goes to the intro. The title card itself is 06's.
class TitleGate extends StatelessWidget {
  const TitleGate({super.key});

  static const String prompt = 'Tap to begin';

  /// The prompt waits for the title to land before it appears.
  static const Duration _promptDelay = Duration(milliseconds: 3800);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    void begin() => context.go(Routes.intro);
    final wait = still ? Duration.zero : _promptDelay;
    return Stack(
      fit: StackFit.expand,
      children: [
        const TitleScreen(),
        // The whole frame is the way in; the prompt is its accessible button.
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: begin),
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.paddingOf(context).bottom + BrandSpace.xl,
          child: Semantics(
            button: true,
            label: prompt,
            onTap: begin,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: begin,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: BrandSpace.minTarget,
                ),
                child: Center(
                  child: _FadeUpAfter(
                    wait: wait,
                    child: Text(
                      prompt.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: BrandType.eyebrow.copyWith(
                        color: ChapterGrade.lobby.key,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Invisible for [wait], then fades up.
class _FadeUpAfter extends StatelessWidget {
  const _FadeUpAfter({required this.wait, required this.child});

  final Duration wait;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = MediaQuery.disableAnimationsOf(context)
        ? BrandMotion.reducedMotionFade
        : BrandMotion.cinematic;
    final total = wait + fade;
    final from = wait.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) => Opacity(
        opacity: t <= from ? 0 : (t - from) / (1 - from),
        child: child,
      ),
      child: child,
    );
  }
}
