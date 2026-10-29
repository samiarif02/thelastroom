import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/cue.dart';
import '../shared/timeline.dart';
import 'bokeh.dart';

/// C · title card. Symmetrical, centred, engraved: a brass frame draws itself, the title
/// tracks in wide and settles, a lamp warms the room from below.
class BoardroomTitle extends StatelessWidget {
  const BoardroomTitle({super.key});

  static const CinematicDirection _d = boardroom;

  static const double _trackFrom = 22;
  static const double _pushFrom = 1.06;
  static const double _maxTitleScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.void_,
      child: Timeline(
        duration: _d.motion.titleCard,
        builder: (context, t, _) {
          final lamp = cue(t, 0, 0.6, BrandMotion.enter);
          final frame = cue(t, 0.1, 0.55, BrandMotion.camera);
          final title = cue(t, 0.2, 0.95, _d.motion.cutCurve);
          final sub = cue(t, 0.6, 0.95, BrandMotion.enter);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: lamp,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 1.2),
                      radius: 1.2,
                      colors: [
                        grade.tint.withValues(alpha: 0.9),
                        grade.shadow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: lamp * 0.7,
                child: Bokeh(
                  colors: [grade.key, grade.tint],
                  count: 14,
                  seed: 21,
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(BrandSpace.lg),
                child: CustomPaint(
                  painter: _BrassFrame(color: grade.key, t: frame),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: _maxTitleScale,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(BrandSpace.lg),
                        child: Transform.scale(
                          scale: mix(_pushFrom, 1, title),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: frame,
                                child: _Ornament(
                                  text: MissionOne.chapterNumber,
                                  style: type.eyebrow,
                                  rule: grade.key,
                                ),
                              ),
                              const SizedBox(height: BrandSpace.lg),
                              Semantics(
                                header: true,
                                label:
                                    '${MissionOne.chapterNumber}: ${MissionOne.chapterTitle}',
                                child: ExcludeSemantics(
                                  child: Opacity(
                                    opacity: title,
                                    child: Text(
                                      'GET THROUGH\nTHE DOOR',
                                      textAlign: TextAlign.center,
                                      style: type.titleCard.copyWith(
                                        letterSpacing: mix(
                                          _trackFrom,
                                          type.titleCard.letterSpacing!,
                                          title,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: BrandSpace.lg),
                              Opacity(
                                opacity: sub,
                                child: Text(
                                  'in which we meet ${MissionOne.interviewer}',
                                  textAlign: TextAlign.center,
                                  style: type.display.copyWith(
                                    fontSize: 20,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "— ◆ CHAPTER ONE ◆ —", in brass.
class _Ornament extends StatelessWidget {
  const _Ornament({
    required this.text,
    required this.style,
    required this.rule,
  });

  final String text;
  final TextStyle style;
  final Color rule;

  @override
  Widget build(BuildContext context) {
    Widget line() =>
        SizedBox(width: 28, height: 0.8, child: ColoredBox(color: rule));
    Widget diamond() => Transform.rotate(
      angle: 0.785,
      child: SizedBox.square(dimension: 4, child: ColoredBox(color: rule)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        const SizedBox(width: BrandSpace.sm),
        diamond(),
        const SizedBox(width: BrandSpace.sm),
        Flexible(
          child: Text(text, style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: BrandSpace.xs),
        diamond(),
        const SizedBox(width: BrandSpace.sm),
        line(),
      ],
    );
  }
}

/// A double brass rule round the frame, drawn from the top centre outwards.
class _BrassFrame extends CustomPainter {
  _BrassFrame({required this.color, required this.t});

  final Color color;
  final double t;

  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final inset in [0.0, _gap]) {
      final r = (Offset.zero & size).deflate(inset);
      final path = Path()
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.center.dx, r.bottom)
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.center.dx, r.bottom);
      for (final m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * t), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BrassFrame oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
