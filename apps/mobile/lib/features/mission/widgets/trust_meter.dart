import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// The trust meter as a heartbeat (FR-15): a brass trace across the top of the frame whose
/// beat is calm and strong when the interviewer trusts the answer, and thin and flat when they
/// don't. [trust] is the engine's `trustAfter`; this only draws it. When it changes the trace
/// jumps once, so a pick is felt within the beat.
///
/// Still under reduced motion (the [AmbientClock] stops): the trace holds its shape.
class TrustMeter extends StatelessWidget {
  const TrustMeter({
    super.key,
    required this.trust,
    this.grade = ChapterGrade.lobby,
  });

  /// 0–100.
  final int trust;
  final ChapterGrade grade;

  static const String label = 'TRUST';
  static const double height = 28;
  static const double _labelGap = BrandSpace.sm;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trust: $trust out of 100',
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        children: [
          Text(label, style: BrandType.label.copyWith(color: grade.key)),
          const SizedBox(width: _labelGap),
          Expanded(
            child: SizedBox(
              height: height,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: trust / 100),
                duration: BrandMotion.cinematic,
                curve: BrandMotion.enter,
                builder: (context, level, _) => _Jolt(
                  trust: trust,
                  builder: (jolt) => RepaintBoundary(
                    child: CustomPaint(
                      painter: _HeartbeatPainter(
                        clock: AmbientClock.of(context),
                        level: level,
                        jolt: jolt,
                        color: grade.key,
                      ),
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

/// A 0→1→0 kick each time [trust] changes.
class _Jolt extends StatefulWidget {
  const _Jolt({required this.trust, required this.builder});

  final int trust;
  final Widget Function(double jolt) builder;

  @override
  State<_Jolt> createState() => _JoltState();
}

class _JoltState extends State<_Jolt> with SingleTickerProviderStateMixin {
  late final AnimationController _kick = AnimationController(
    vsync: this,
    duration: BrandMotion.cinematic,
  );

  @override
  void didUpdateWidget(_Jolt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trust != widget.trust &&
        !MediaQuery.disableAnimationsOf(context)) {
      _kick.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _kick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _kick,
    builder: (context, _) => widget.builder(math.sin(_kick.value * math.pi)),
  );
}

class _HeartbeatPainter extends CustomPainter {
  _HeartbeatPainter({
    required this.clock,
    required this.level,
    required this.jolt,
    required this.color,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;

  /// Trust, 0–1.
  final double level;
  final double jolt;
  final Color color;

  // A beat crosses the trace every [_period] seconds; calmer (slower) at high trust.
  static const double _fastPeriod = 1.1;
  static const double _slowPeriod = 2.2;
  static const double _beatWidth = 0.12;
  static const double _minAmplitude = 0.12;
  static const double _joltAmplitude = 0.35;
  static const int _steps = 96;

  @override
  void paint(Canvas canvas, Size size) {
    final period = _fastPeriod + (_slowPeriod - _fastPeriod) * level;
    final head = (clock.value / period) % 1;
    final amplitude = math.min(
      1.0,
      _minAmplitude + (1 - _minAmplitude) * level + _joltAmplitude * jolt,
    );
    final mid = size.height / 2;
    final path = Path()..moveTo(0, mid);
    for (var i = 1; i <= _steps; i++) {
      final x = i / _steps;
      path.lineTo(x * size.width, mid - _beat(x - head) * amplitude * mid);
    }
    final faint = color.withValues(alpha: 0.18 + 0.5 * level);
    canvas
      ..drawLine(
        Offset(0, mid),
        Offset(size.width, mid),
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..strokeWidth = 0.6,
      )
      ..drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [faint.withValues(alpha: 0), faint, color],
            stops: const [0, 0.5, 1],
          ).createShader(Offset.zero & size)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round,
      );
  }

  /// One ECG complex centred on 0: a small dip, the spike, a deeper rebound. Flat elsewhere.
  static double _beat(double dx) {
    final x = dx / _beatWidth;
    if (x < -1 || x > 1) return 0;
    if (x < -0.3) return -0.15 * math.sin((x + 1) / 0.7 * math.pi);
    if (x < 0.3) return math.cos(x / 0.3 * math.pi / 2);
    return -0.35 * math.sin((x - 0.3) / 0.7 * math.pi);
  }

  @override
  bool shouldRepaint(_HeartbeatPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.jolt != jolt ||
      oldDelegate.color != color;
}
