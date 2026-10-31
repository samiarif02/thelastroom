import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';

/// The Morning Office set (brief 16, the owner's pick): what is behind the interviewer. A
/// cream wall, tall glass full of pale sky, the city soft and far, sunlight slanting in, a
/// plant by the window. The sky takes the chapter's shadow and the sun its tint.
class OfficeBackdrop extends StatelessWidget {
  const OfficeBackdrop({super.key, required this.grade});

  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _WallPainter(grade: grade)),
  );
}

/// The near plane: the pale desk, its accent edge, and the mug on it.
class OfficeDesk extends StatelessWidget {
  const OfficeDesk({super.key, required this.grade, required this.deskLine});

  final ChapterGrade grade;

  /// Where the desk's edge sits, as a share of the height.
  final double deskLine;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DeskPainter(
      grade: grade,
      deskLine: deskLine,
      clock: AmbientClock.of(context),
    ),
  );
}

/// The office's practical: a mug in the chapter's accent with steam rising from it, on a
/// [aspectRatio] box. [hot] false is the offline state: the coffee has gone cold, no steam.
class DeskMug extends StatelessWidget {
  const DeskMug({super.key, required this.grade, this.hot = true});

  /// Width / height of the mug's box.
  static const double aspectRatio = 1.4;

  final ChapterGrade grade;
  final bool hot;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _MugPainter(
          grade: grade,
          clock: hot ? AmbientClock.of(context) : null,
        ),
      ),
    ),
  );
}

// The window takes this share of the wall.
const double _glassInset = 0.1;
const double _glassBottom = 0.7;

Rect _glass(Size size) => Rect.fromLTRB(
  size.width * _glassInset,
  0,
  size.width * (1 - _glassInset),
  size.height * _glassBottom,
);

/// Morning office: a cream wall, tall glass full of pale sky, the city soft and far, sunlight
/// slanting in, and a leafy plant by the window.
class _WallPainter extends CustomPainter {
  const _WallPainter({required this.grade});

  final ChapterGrade grade;

  @override
  void paint(Canvas canvas, Size size) {
    final glass = _glass(size);
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = BrandColors.surface)
      ..drawRect(
        glass,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [grade.shadow, BrandColors.void_],
          ).createShader(glass),
      );
    // The far city: pale blocks low in the glass.
    final city = Paint()..color = BrandColors.line.withValues(alpha: 0.55);
    final r = math.Random(3);
    for (var x = glass.left; x < glass.right; x += glass.width / 9) {
      final h = glass.height * (0.12 + r.nextDouble() * 0.22);
      canvas.drawRect(
        Rect.fromLTRB(
          x + 2,
          glass.bottom - h,
          x + glass.width / 9 - 2,
          glass.bottom,
        ),
        city,
      );
    }
    // Sun: a warm bloom in the top corner, and shafts of light across the room.
    canvas.drawCircle(
      Offset(glass.left + glass.width * 0.18, glass.top + glass.height * 0.16),
      size.width * 0.22,
      Paint()
        ..color = grade.tint.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.08),
    );
    final shaft = Paint()..color = BrandColors.void_.withValues(alpha: 0.35);
    for (final (from, width) in [(0.05, 0.12), (0.3, 0.07), (0.48, 0.1)]) {
      final x = size.width * from;
      final w = size.width * width;
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + w, 0)
          ..lineTo(x + w + size.width * 0.35, size.height)
          ..lineTo(x + size.width * 0.35, size.height)
          ..close(),
        shaft,
      );
    }
    // Window frame: white mullions at the thirds, never down the middle.
    final frame = Paint()
      ..color = BrandColors.surfaceRaised
      ..strokeWidth = 4;
    canvas.drawRect(
      glass,
      Paint()
        ..color = BrandColors.surfaceRaised
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    for (final third in [1 / 3, 2 / 3]) {
      final x = glass.left + glass.width * third;
      canvas.drawLine(Offset(x, glass.top), Offset(x, glass.bottom), frame);
    }
    _plant(
      canvas,
      Offset(size.width * 0.88, size.height * 0.7),
      size.width * 0.2,
    );
  }

  /// A plant in a pot, by the window: overlapping leaves in two greens.
  void _plant(Canvas canvas, Offset base, double width) {
    final pot = Rect.fromCenter(
      center: base.translate(0, -width * 0.2),
      width: width * 0.5,
      height: width * 0.42,
    );
    final r = math.Random(11);
    for (var i = 0; i < 9; i++) {
      final angle = -math.pi / 2 + (i - 4) * 0.32 + r.nextDouble() * 0.1;
      final length = width * (0.55 + r.nextDouble() * 0.45);
      final tip =
          pot.topCenter + Offset(math.cos(angle), math.sin(angle)) * length;
      final mid = Offset.lerp(pot.topCenter, tip, 0.5)!;
      final normal = Offset(-math.sin(angle), math.cos(angle)) * width * 0.11;
      canvas.drawPath(
        Path()
          ..moveTo(pot.topCenter.dx, pot.topCenter.dy)
          ..quadraticBezierTo(
            mid.dx + normal.dx,
            mid.dy + normal.dy,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            mid.dx - normal.dx,
            mid.dy - normal.dy,
            pot.topCenter.dx,
            pot.topCenter.dy,
          ),
        Paint()..color = i.isEven ? BrandColors.leaf : BrandColors.leafLit,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        pot,
        bottomLeft: Radius.circular(width * 0.08),
        bottomRight: Radius.circular(width * 0.08),
      ),
      Paint()..color = BrandColors.surfaceRaised,
    );
  }

  @override
  bool shouldRepaint(_WallPainter oldDelegate) => oldDelegate.grade != grade;
}

class _DeskPainter extends CustomPainter {
  _DeskPainter({
    required this.grade,
    required this.deskLine,
    required this.clock,
  }) : super(repaint: clock);

  final ChapterGrade grade;
  final double deskLine;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final deskY = size.height * deskLine;
    final desk = Rect.fromLTRB(0, deskY, size.width, size.height);
    canvas
      ..drawRect(
        desk,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrandColors.surfaceRaised, BrandColors.surface],
          ).createShader(desk),
      )
      ..drawRect(
        Rect.fromLTWH(0, deskY, size.width, 2),
        Paint()..color = grade.key.withValues(alpha: 0.55),
      );
    _MugPainter(grade: grade, clock: clock).paintAt(
      canvas,
      Offset(size.width * 0.14, deskY + size.height * 0.015),
      size.width * 0.05,
    );
  }

  @override
  bool shouldRepaint(_DeskPainter oldDelegate) =>
      oldDelegate.grade != grade || oldDelegate.deskLine != deskLine;
}

class _MugPainter extends CustomPainter {
  _MugPainter({required this.grade, this.clock}) : super(repaint: clock);

  final ChapterGrade grade;

  /// Null: no steam.
  final ValueListenable<double>? clock;

  // On its own box, the mug stands on the bottom edge and is this share of the width.
  static const double _unitShare = 0.14;

  @override
  void paint(Canvas canvas, Size size) => paintAt(
    canvas,
    Offset(size.width / 2, size.height * 0.95),
    size.width * _unitShare,
  );

  /// Draws the mug standing on [base], [u] its unit size.
  void paintAt(Canvas canvas, Offset base, double u) => _mug(canvas, base, u);

  void _mug(Canvas canvas, Offset base, double u) {
    final body = Rect.fromLTRB(
      base.dx - u,
      base.dy - u * 2.1,
      base.dx + u,
      base.dy,
    );
    canvas
      ..drawCircle(
        Offset(body.right, body.center.dy),
        u * 0.55,
        Paint()
          ..color = grade.key
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.28,
      )
      ..drawRRect(
        RRect.fromRectAndCorners(
          body,
          bottomLeft: Radius.circular(u * 0.4),
          bottomRight: Radius.circular(u * 0.4),
        ),
        Paint()..color = grade.key,
      );
    // Steam, rising and swaying; a cold mug has none.
    final clock = this.clock;
    if (clock == null) return;
    final t = clock.value;
    final steam = Paint()
      ..color = BrandColors.textSecondary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.14
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.4, 0.4]) {
      final sway = math.sin(t * 1.3 + dx * 4) * u * 0.25;
      final x = body.center.dx + dx * u;
      canvas.drawPath(
        Path()
          ..moveTo(x, body.top - u * 0.3)
          ..cubicTo(
            x + sway,
            body.top - u * 0.9,
            x - sway,
            body.top - u * 1.3,
            x + sway * 0.5,
            body.top - u * 1.9,
          ),
        steam,
      );
    }
  }

  @override
  bool shouldRepaint(_MugPainter oldDelegate) =>
      oldDelegate.grade != grade || oldDelegate.clock != clock;
}
