import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ambient_clock.dart';

/// Grain + vignette over [child] (brief §9: very subtle). The grain is a few pre-baked noise
/// tiles swapped at film rate behind a [RepaintBoundary], so it costs one textured rect per
/// frame. It holds still under reduced motion (the [AmbientClock] stops).
///
/// The vignette is an ellipse fitted to the frame. **Lay it under text, never over it**: it
/// darkens the edges by up to [vignette], which would take edge text below AA. So the app
/// wraps every route in grain only (`vignette: 0`), and scenes put a vignette-only overlay
/// (`grain: 0`) round their set, beneath their subtitles and cards.
///
/// Needs an [AmbientClock] above it to move; without one the grain is a still frame.
class FilmOverlay extends StatelessWidget {
  const FilmOverlay({
    super.key,
    required this.child,
    this.grain = BrandFilm.grain,
    this.vignette = BrandFilm.vignette,
    this.vignetteColor = BrandColors.void_,
  });

  final Widget child;

  /// Grain opacity, 0–1.
  final double grain;

  /// How far the vignette reaches in: 0 none, 1 heavy.
  final double vignette;

  /// The colour the corners fall to. Pass the grade's shadow to tint it.
  final Color vignetteColor;

  static const double _reach = 0.6;
  static const double _radius = 1.05;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (vignette > 0)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: _radius,
                  transform: const _FitEllipse(),
                  colors: [
                    BrandColors.clear,
                    vignetteColor.withValues(alpha: vignette),
                  ],
                  stops: [1 - vignette * _reach, 1],
                ),
              ),
            ),
          ),
        if (grain > 0)
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
}

/// Stretches a radial gradient (measured on the box's shortest side) into an ellipse that
/// fits the whole box, so a tall phone's top and bottom aren't swallowed by the vignette.
class _FitEllipse extends GradientTransform {
  const _FitEllipse();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final c = bounds.center;
    final side = bounds.shortestSide;
    return Matrix4.translationValues(c.dx, c.dy, 0)
      ..scaleByDouble(bounds.width / side, bounds.height / side, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.clock, required this.opacity})
    : super(repaint: Listenable.merge([clock, _NoiseTiles.instance]));

  final ValueListenable<double> clock;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final tiles = _NoiseTiles.instance.tiles;
    if (tiles == null) return;
    final frame = (clock.value * BrandFilm.frameRate).floor();
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
