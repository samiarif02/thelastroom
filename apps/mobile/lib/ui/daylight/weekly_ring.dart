import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';
import 'ring_painter.dart';

/// The habit gauge (direction.md, "Reward and retention"): weekly and forgiving, never a
/// streak. A ring of [done] out of [goal] sessions with "2/3" in it and an optional [caption]
/// under it ("this week"). A change sweeps over [DaylightMotion.ringClose]; a closed week gets
/// a honey ring.
class WeeklyRing extends StatelessWidget {
  const WeeklyRing({
    super.key,
    required this.done,
    this.goal = 3,
    this.caption,
    this.floor,
    this.size = defaultSize,
  });

  final int done;
  final int goal;
  final String? caption;
  final FloorColours? floor;
  final double size;

  static const double defaultSize = 56;
  static const double _stroke = 7;

  bool get closed => done >= goal;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final value = goal == 0 ? 0.0 : done / goal;
    Widget ring(double v) => SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: RingPainter(
          value: v,
          fill: closed ? DaylightColors.honey : f.base,
          track: DaylightColors.sand2,
          stroke: _stroke,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_stroke * 1.5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${done.clamp(0, goal)}/$goal',
              style: DaylightType.tabular(DaylightType.body4),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: '$done of $goal sessions this week',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (still)
            ring(value)
          else
            TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: DaylightMotion.ringClose,
              curve: DaylightMotion.ease,
              builder: (context, v, _) => ring(v),
            ),
          if (caption case final caption?) ...[
            const SizedBox(height: DaylightSpace.s2),
            Text(
              caption,
              style: DaylightType.caption4.copyWith(color: DaylightColors.ink2),
            ),
          ],
        ],
      ),
    );
  }
}
