import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';
import 'flicker.dart';

/// The Boardroom's practical light: a green-shaded banker's lamp on a brass stem. The bulb's
/// glow under the shade flickers with [lampFlicker], in step with any [Spotlight] and rim light.
/// [lit] false is the lamp switched off (the offline state, "the lights are out").
///
/// Drawn in code on a [aspectRatio] box; give it a width and it sizes itself.
class BankersLamp extends StatelessWidget {
  const BankersLamp({
    super.key,
    this.grade = ChapterGrade.lobby,
    this.lit = true,
    this.semanticLabel,
  });

  /// Width / height of the lamp's box.
  static const double aspectRatio = 1.4;

  final ChapterGrade grade;
  final bool lit;

  /// Null leaves it decorative (excluded from semantics).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final lamp = AspectRatio(
      aspectRatio: aspectRatio,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _LampPainter(
            clock: AmbientClock.of(context),
            grade: grade,
            lit: lit,
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: lamp);
    return Semantics(image: true, label: label, child: lamp);
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({required this.clock, required this.grade, required this.lit})
    : super(repaint: lit ? clock : null);

  final ValueListenable<double> clock;
  final ChapterGrade grade;
  final bool lit;

  // Designed on a 140 × 100 box.
  static const double _w = 140;
  static const double _h = 100;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _w, size.height / _h);
    final light = lit ? lampFlicker(clock.value) : 0.0;
    final brass = grade.key;

    // The pool on the desk, under everything.
    if (lit) {
      canvas.drawOval(
        const Rect.fromLTRB(4, 84, 136, 104),
        Paint()
          ..color = grade.key.withValues(alpha: 0.28 * light)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Base and stem.
    canvas
      ..drawOval(
        const Rect.fromLTRB(44, 90, 96, 99),
        Paint()..color = brass.withValues(alpha: lit ? 0.75 : 0.35),
      )
      ..drawLine(
        const Offset(70, 92),
        const Offset(70, 46),
        Paint()
          ..color = brass.withValues(alpha: lit ? 0.85 : 0.4)
          ..strokeWidth = 2.4,
      );

    // The glow of the bulb, spilling out under the shade.
    if (lit) {
      canvas.drawOval(
        const Rect.fromLTRB(26, 40, 114, 62),
        Paint()
          ..color = grade.key.withValues(alpha: 0.75 * light)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // The green glass shade: a long half-cylinder, lit from inside along its lower edge.
    final shade = Path()
      ..moveTo(20, 46)
      ..cubicTo(24, 22, 46, 14, 70, 14)
      ..cubicTo(94, 14, 116, 22, 120, 46)
      ..quadraticBezierTo(70, 50, 20, 46)
      ..close();
    canvas.drawPath(
      shade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BrandColors.lampGlass,
            Color.lerp(BrandColors.lampGlass, BrandColors.lampGlassLit, light)!,
          ],
        ).createShader(const Rect.fromLTRB(20, 14, 120, 48)),
    );
    // A highlight along the glass, and the brass rim at its lip.
    canvas
      ..drawPath(
        Path()
          ..moveTo(34, 30)
          ..cubicTo(44, 21, 58, 18, 72, 18),
        Paint()
          ..color = BrandColors.textPrimary.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        Path()
          ..moveTo(20, 46)
          ..quadraticBezierTo(70, 50, 120, 46),
        Paint()
          ..color = brass.withValues(alpha: lit ? 0.9 : 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      )
      // The pull chain and its bead.
      ..drawLine(
        const Offset(92, 48),
        const Offset(92, 62),
        Paint()
          ..color = brass.withValues(alpha: 0.6)
          ..strokeWidth = 0.6,
      )
      ..drawCircle(
        const Offset(92, 63.5),
        1.6,
        Paint()..color = brass.withValues(alpha: 0.8),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LampPainter oldDelegate) =>
      oldDelegate.grade != grade || oldDelegate.lit != lit;
}
