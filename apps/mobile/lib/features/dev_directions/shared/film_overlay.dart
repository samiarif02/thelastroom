import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ambient.dart';

/// The global grain + vignette laid over every frame (brief §9: very subtle). The grain is a
/// few pre-baked noise tiles swapped at film rate, behind a [RepaintBoundary], so it costs one
/// textured rect per frame. It holds still under reduced motion.
class FilmOverlay extends StatelessWidget {
  const FilmOverlay({
    super.key,
    required this.grain,
    required this.vignette,
    required this.vignetteStrength,
    required this.child,
  });

  /// Grain opacity, 0–1. Night Glass barely has any; Concrete Noir wears it.
  final double grain;

  /// The colour the corners fall to.
  final Color vignette;

  /// How far the vignette reaches in: 0 none, 1 heavy.
  final double vignetteStrength;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.05,
                colors: [
                  BrandColors.clear,
                  vignette.withValues(alpha: vignetteStrength),
                ],
                stops: [1 - vignetteStrength * _vignetteReach, 1],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GrainPainter(
                clock: AmbientClock.of(context),
                opacity: grain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const double _vignetteReach = 0.6;
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.clock, required this.opacity})
    : super(repaint: Listenable.merge([clock, _NoiseTiles.instance]));

  final ValueListenable<double> clock;
  final double opacity;

  /// Film runs at 24 frames a second; grain that changes faster reads as video noise.
  static const double _filmRate = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final tiles = _NoiseTiles.instance.tiles;
    if (tiles == null || opacity <= 0) return;
    final frame = (clock.value * _filmRate).floor();
    final tile = tiles[frame % tiles.length];
    // A different offset every frame so the eye never catches the tile seam.
    final jitter = math.Random(frame);
    final matrix = Matrix4.translationValues(
      jitter.nextDouble() * _NoiseTiles.size,
      jitter.nextDouble() * _NoiseTiles.size,
      0,
    );
    final paint = Paint()
      ..shader = ui.ImageShader(
        tile,
        TileMode.repeated,
        TileMode.repeated,
        matrix.storage,
      )
      ..blendMode = BlendMode.overlay
      ..color = BrandColors.textPrimary.withValues(alpha: opacity);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.clock != clock;
}

/// Grey noise tiles, generated once from a fixed seed (no image assets, no network). Notifies
/// once they're ready, so a still (reduced-motion) frame still gets its grain.
class _NoiseTiles extends ChangeNotifier {
  _NoiseTiles._() {
    unawaited(_generate());
  }

  static final _NoiseTiles instance = _NoiseTiles._();

  static const int size = 128;
  static const int _count = 4;
  static const int _seed = 1977;
  static const int _opaque = 255;

  List<ui.Image>? tiles;

  Future<void> _generate() async {
    final random = math.Random(_seed);
    final images = <ui.Image>[];
    for (var i = 0; i < _count; i++) {
      final pixels = Uint8List(size * size * 4);
      for (var p = 0; p < pixels.length; p += 4) {
        final v = random.nextInt(_opaque + 1);
        pixels[p] = v;
        pixels[p + 1] = v;
        pixels[p + 2] = v;
        pixels[p + 3] = _opaque;
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: size,
        height: size,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final codec = await descriptor.instantiateCodec();
      images.add((await codec.getNextFrame()).image);
    }
    tiles = images;
    notifyListeners();
  }
}
