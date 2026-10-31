import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The app's title (brief 20): on the evening sky, the tower's windows light up floor by
/// floor from the street to the top, the last room glows raspberry, then the name arrives.
/// About [length] long; under reduced motion it shows its last frame at once. [onLanded] fires
/// when the name has arrived. Not interactive: the screen around it decides what a tap does.
class VividTitle extends StatelessWidget {
  const VividTitle({super.key, this.onLanded, this.footer});

  final VoidCallback? onLanded;

  /// Below the name once it has landed: "Begin" on the first launch.
  final Widget? footer;

  static const String title = 'THE LAST ROOM';
  static const String tagline = 'One room left between you and the offer.';

  /// The whole title, from the first window to the name settled.
  static const Duration length = Duration(milliseconds: 1400);

  // The cue sheet, as shares of [length].
  static const double _lightsTo = 0.7;
  static const double _nameFrom = 0.45;
  static const double _footFrom = 0.8;
  static const double _rise = 18;
  static const double _towerShare = 0.42;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const VividBackdrop(),
        Timeline(
          duration: still ? Duration.zero : length,
          onFinished: onLanded,
          builder: (context, t, _) {
            final at = still ? 1.0 : t;
            final lights = cue(at, 0, _lightsTo, BrandMotion.camera);
            final name = cue(at, _nameFrom, 1, BrandMotion.enter);
            final foot = cue(at, _footFrom, 1, BrandMotion.enter);
            return SafeArea(
              child: LayoutBuilder(
                // Fills the frame, and scrolls only when large text makes it taller.
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(),
                          SizedBox(
                            height: box.maxHeight * _towerShare,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: TowerPainter(lit: lights),
                            ),
                          ),
                          const SizedBox(height: BrandSpace.lg),
                          Opacity(
                            opacity: name,
                            child: Transform.translate(
                              offset: Offset(0, _rise * (1 - name)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BrandSpace.lg,
                                ),
                                child: Column(
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: BrandVividType.hero.copyWith(
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: BrandSpace.sm),
                                    const Text(
                                      tagline,
                                      textAlign: TextAlign.center,
                                      style: BrandVividType.body,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (footer case final f?)
                            Opacity(
                              opacity: foot,
                              child: IgnorePointer(
                                ignoring: foot < 1,
                                child: f,
                              ),
                            ),
                          const SizedBox(height: BrandSpace.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

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
