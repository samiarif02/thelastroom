import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';
import 'ring_painter.dart';

/// The debrief's score (direction.md, moment 4): a 112 dial in the floor's colour on sand, the
/// numeral in Heading 2 (tabular) and "of 100" under it. It sweeps 0 → [score] while the
/// numeral counts in step over [DaylightMotion.countUp]; under reduced motion (or [animate]
/// off) it's simply there.
class ScoreDial extends StatelessWidget {
  const ScoreDial({
    super.key,
    required this.score,
    this.max = 100,
    this.floor,
    this.size = defaultSize,
    this.animate = true,
  });

  final int score;
  final int max;
  final FloorColours? floor;
  final double size;
  final bool animate;

  static const double defaultSize = 112;
  static const double _stroke = 10;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final still = !animate || MediaQuery.disableAnimationsOf(context);
    Widget dial(double t) {
      final shown = (score * t).round();
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: RingPainter(
            value: shown / max,
            fill: f.base,
            track: DaylightColors.sand,
            stroke: _stroke,
          ),
          // The numeral is part of the graphic: at large text it scales down inside the ring.
          child: Padding(
            padding: const EdgeInsets.all(_stroke * 1.5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$shown',
                    style: DaylightType.tabular(DaylightType.heading2),
                  ),
                  Text(
                    'of $max',
                    style: DaylightType.caption4.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Score $score of $max',
      excludeSemantics: true,
      child: still
          ? dial(1)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: DaylightMotion.countUp,
              curve: DaylightMotion.ease,
              builder: (context, t, _) => dial(t),
            ),
    );
  }
}
