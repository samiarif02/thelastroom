import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// The tower, drawn: a slim block a shade lighter than the sky, its windows lighting floor by
/// floor as [lit] goes 0 → 1, the top floor (the last room) in raspberry.
class TowerPainter extends CustomPainter {
  const TowerPainter({required this.lit});

  final double lit;

  static const int floors = 12;
  static const int columns = 4;
  static const double _aspect = 0.42;
  static const double _gap = 0.28;
  static const double _bodyAlpha = 0.9;
  static const double _darkAlpha = 0.16;
  static const double _glowBlur = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = math.min(size.width * 0.6, h * _aspect);
    final body = Rect.fromLTWH((size.width - w) / 2, 0, w, h);
    final top = body.top + h * 0.08;
    // A stepped crown, then the shaft.
    canvas
      ..drawRect(
        Rect.fromLTRB(
          body.left + w * 0.25,
          body.top,
          body.right - w * 0.25,
          top,
        ),
        Paint()..color = BrandVivid.locked.withValues(alpha: _bodyAlpha),
      )
      ..drawRect(
        Rect.fromLTRB(body.left, top, body.right, body.bottom),
        Paint()..color = BrandVivid.locked.withValues(alpha: _bodyAlpha),
      );
    final cellW = w / columns;
    final cellH = (body.bottom - top) / floors;
    for (var f = 0; f < floors; f++) {
      // Floor 0 is the street; each lights in turn on the way up.
      final from = f / floors;
      final on = ((lit - from) * floors).clamp(0.0, 1.0);
      final lastRoom = f == floors - 1;
      final light = lastRoom ? ChapterGrade.finalRound.glow : BrandVivid.accent;
      final y = body.bottom - (f + 1) * cellH;
      for (var c = 0; c < columns; c++) {
        final r = Rect.fromLTWH(
          body.left + c * cellW + cellW * _gap / 2,
          y + cellH * _gap / 2,
          cellW * (1 - _gap),
          cellH * (1 - _gap),
        );
        canvas.drawRect(
          r,
          Paint()..color = BrandVivid.onDeep.withValues(alpha: _darkAlpha),
        );
        if (on <= 0) continue;
        canvas
          ..drawRect(
            r.inflate(1.5),
            Paint()
              ..color = light.withValues(alpha: 0.5 * on)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlur),
          )
          ..drawRect(r, Paint()..color = light.withValues(alpha: on));
      }
    }
  }

  @override
  bool shouldRepaint(TowerPainter old) => old.lit != lit;
}
