import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Draws a widget that is never on screen into a PNG: its own render tree (a [RenderView] with
/// a [RenderRepaintBoundary]), built, laid out at a logical size and painted once, then read
/// back at a pixel ratio. The floor card is made this way, so the screen behind the share link
/// doesn't change.
abstract interface class CardRenderer {
  /// [child] laid out at [size] and drawn at [pixelRatio]: PNG bytes.
  Future<Uint8List> render(
    Widget child, {
    required Size size,
    required double pixelRatio,
    required ui.FlutterView view,
  });
}

/// Thrown when the picture can't be encoded (the engine returned no bytes).
class CardRenderException implements Exception {
  const CardRenderException(this.message);

  final String message;

  @override
  String toString() => 'CardRenderException: $message';
}

/// The real one, off screen. Fonts: the bundled ones (Bricolage Grotesque, Geist, Phosphor)
/// are in the app's font manifest, which the engine registers before the first frame on every
/// platform (on the web it fetches the manifest's files while it starts). A player can only tap
/// "Share" on a screen already drawn with them, so they are loaded when the card is laid out.
class OffscreenCardRenderer implements CardRenderer {
  const OffscreenCardRenderer();

  @override
  Future<Uint8List> render(
    Widget child, {
    required Size size,
    required double pixelRatio,
    required ui.FlutterView view,
  }) async {
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(child: boundary),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final build = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: pixelRatio,
          textScaler: TextScaler.noScaling,
          disableAnimations: true,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: DaylightType.body5.copyWith(color: DaylightColors.ink),
            child: child,
          ),
        ),
      ),
    ).attachToRenderTree(build);
    try {
      build
        ..buildScope(root)
        ..finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw const CardRenderException('no PNG bytes');
        }
        return bytes.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      // Unmount the tree, so every State is disposed (the cast's controllers among them).
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
          .attachToRenderTree(build, root);
      build
        ..buildScope(root)
        ..finalizeTree();
      pipeline.rootNode = null;
    }
  }
}

/// The renderer the share link uses; tests swap in a fake.
final cardRendererProvider = Provider<CardRenderer>(
  (ref) => const OffscreenCardRenderer(),
);
