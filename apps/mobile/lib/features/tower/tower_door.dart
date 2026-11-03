import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';

/// How a room's door stands on the tower (the owner, 2026-11-03: "these small windows should be
/// like doors, so the user knows to click here to play").
enum DoorState {
  /// Played: a honey door with a check.
  done,

  /// The room to play: ajar, warm light in the doorway, the interviewer looking out.
  next,

  /// Not reached yet on an open floor: closed, panelled, a knob.
  closed,

  /// On a floor not open yet: closed, with a small lock.
  locked,

  /// The last room, from day one: lit, with Sam waiting in it.
  waiting,
}

/// One door of the tower, drawn in the arch motif (a 28 × 44 arch, flat sill): a frame, a leaf
/// with two panels and a knob, and for the room to play, the leaf swung in, honey light inside
/// and the interviewer in the doorway. [leaf] and [panel] are the floor's colours for a closed
/// door. [lighting] (0 → 1) is the moment a finished room lights up: the leaf turns honey and
/// the check lands.
class TowerDoor extends StatelessWidget {
  const TowerDoor({
    super.key,
    required this.state,
    required this.width,
    required this.leaf,
    required this.panel,
    required this.frame,
    this.person,
    this.lighting = 1,
  });

  final DoorState state;
  final double width;
  final Color leaf;
  final Color panel;
  final Color frame;
  final CastPerson? person;
  final double lighting;

  static const double aspect = 44 / 28;
  double get height => width * aspect;

  static const double _glyph = 0.5;
  static const double _lock = 0.42;
  static const double _peek = 1.5;
  static const double _checkFrom = 0.6;
  static const double _spill = 6;

  @override
  Widget build(BuildContext context) {
    final t = lighting.clamp(0.0, 1.0);
    final leafColour = switch (state) {
      DoorState.done => Color.lerp(leaf, DaylightColors.honey, t)!,
      DoorState.waiting => DaylightColors.honey,
      _ => leaf,
    };
    final panelColour = switch (state) {
      DoorState.done || DoorState.waiting => DaylightColors.honeyEdge,
      _ => panel,
    };
    final who = person;
    final checkT = ((t - _checkFrom) / (1 - _checkFrom)).clamp(0.0, 1.0);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (state == DoorState.next) ...[
            // Warm light spilling out over the threshold.
            Positioned(
              left: -width * 0.25,
              right: -width * 0.25,
              bottom: -_spill,
              height: _spill,
              child: const CustomPaint(painter: _SpillPainter()),
            ),
            // The doorway: warm light, and who's waiting in it.
            Positioned.fill(
              child: ArchFrame(
                ground: DaylightColors.honeyTint,
                bottomRadius: 0,
                child: who == null
                    ? const SizedBox.shrink()
                    : OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minWidth: width * _peek,
                        maxWidth: width * _peek,
                        minHeight: width * _peek,
                        maxHeight: width * _peek,
                        child: CastFigure(person: who, idle: false),
                      ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _AjarPainter(leaf: leaf, panel: panel, frame: frame),
              ),
            ),
          ] else
            Positioned.fill(
              child: CustomPaint(
                painter: _DoorPainter(
                  leaf: leafColour,
                  panel: panelColour,
                  frame: frame,
                  knob: state == DoorState.done || state == DoorState.waiting
                      ? DaylightColors.onHoney
                      : DaylightColors.honey,
                  // A finished door carries its check where the upper panel was.
                  upperPanel: state != DoorState.done,
                ),
              ),
            ),
          if (state == DoorState.done && checkT > 0)
            Align(
              alignment: const Alignment(0, -0.3),
              child: Opacity(
                opacity: checkT,
                child: Icon(
                  PhosphorBold.check,
                  size: width * _glyph,
                  color: DaylightColors.onHoney,
                ),
              ),
            ),
          if (state == DoorState.locked)
            Align(
              alignment: const Alignment(0, 0.25),
              child: Icon(
                PhosphorFill.lockSimple,
                size: width * _lock,
                color: panel,
              ),
            ),
          if (state == DoorState.waiting)
            const Align(
              alignment: Alignment.bottomCenter,
              child: _Silhouette(),
            ),
        ],
      ),
    );
  }
}

/// The arch of a door of [size]: straight sides, a round top, a flat sill.
Path _archPath(Rect r) {
  final radius = r.width / 2;
  return Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + radius)
    ..arcToPoint(
      Offset(r.right, r.top + radius),
      radius: Radius.circular(radius),
    )
    ..lineTo(r.right, r.bottom)
    ..close();
}

/// A closed door: the frame, the leaf, two recessed panels (an arched one above, a square one
/// below) and the knob.
class _DoorPainter extends CustomPainter {
  const _DoorPainter({
    required this.leaf,
    required this.panel,
    required this.frame,
    required this.knob,
    this.upperPanel = true,
  });

  final Color leaf;
  final Color panel;
  final Color frame;
  final Color knob;
  final bool upperPanel;

  static const double _frame = 2;
  static const double _stroke = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    canvas
      ..drawPath(_archPath(outer), Paint()..color = frame)
      ..drawPath(
        _archPath(
          Rect.fromLTRB(_frame, _frame, size.width - _frame, size.height),
        ),
        Paint()..color = leaf,
      );
    final inset = size.width * 0.22;
    final line = Paint()
      ..color = panel
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    // The upper panel follows the arch; the lower one is square.
    final upper = Rect.fromLTRB(
      inset,
      inset + _frame,
      size.width - inset,
      size.height * 0.52,
    );
    if (upperPanel) canvas.drawPath(_archPath(upper), line);
    final lower = Rect.fromLTRB(
      inset,
      size.height * 0.6,
      size.width - inset,
      size.height - inset * 0.8,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(lower, const Radius.circular(1.5)),
        line,
      )
      ..drawCircle(
        Offset(size.width - inset * 0.9, size.height * 0.56),
        math.max(1.4, size.width * 0.06),
        Paint()..color = knob,
      );
  }

  @override
  bool shouldRepaint(_DoorPainter old) =>
      old.leaf != leaf ||
      old.panel != panel ||
      old.frame != frame ||
      old.knob != knob ||
      old.upperPanel != upperPanel;
}

/// The door to play: the frame round a lit doorway, the leaf swung in on its left hinge (a
/// narrowing trapezoid with its panels and knob), so the room reads "open, come in".
class _AjarPainter extends CustomPainter {
  const _AjarPainter({
    required this.leaf,
    required this.panel,
    required this.frame,
  });

  final Color leaf;
  final Color panel;
  final Color frame;

  static const double _frame = 2;
  static const double _open = 0.38;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    // The frame as a ring round the doorway.
    final ring = Path.combine(
      PathOperation.difference,
      _archPath(outer),
      _archPath(
        Rect.fromLTRB(_frame, _frame, size.width - _frame, size.height),
      ),
    );
    canvas.drawPath(ring, Paint()..color = frame);
    // The leaf, swung in: hinged on the left, its free edge shorter (it's further away).
    final w = size.width * _open;
    final r = size.width / 2;
    final leafPath = Path()
      ..moveTo(_frame, size.height)
      ..lineTo(_frame, r)
      ..quadraticBezierTo(_frame + w * 0.2, r * 0.25, _frame + w, r * 0.55)
      ..lineTo(_frame + w, size.height - size.height * 0.06)
      ..close();
    canvas.drawPath(leafPath, Paint()..color = leaf);
    final line = Paint()
      ..color = panel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas
      ..drawLine(
        Offset(_frame + w * 0.35, size.height * 0.3),
        Offset(_frame + w * 0.35, size.height * 0.85),
        line,
      )
      ..drawCircle(
        Offset(_frame + w * 0.8, size.height * 0.56),
        math.max(1.2, size.width * 0.05),
        Paint()..color = DaylightColors.honey,
      );
  }

  @override
  bool shouldRepaint(_AjarPainter old) =>
      old.leaf != leaf || old.panel != panel || old.frame != frame;
}

/// Sam in the lit doorway at the top: head and shoulders in the dusk colour.
class _Silhouette extends StatelessWidget {
  const _Silhouette();

  static const double _head = 9;
  static const double _shoulders = 18;

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: _head,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DaylightColors.dusk,
            shape: BoxShape.circle,
          ),
        ),
      ),
      SizedBox(height: 2),
      SizedBox(
        width: _shoulders,
        height: _shoulders / 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DaylightColors.dusk,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_shoulders / 2),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The cue over the door to play: a small honey tile with a play glyph that bobs gently, so a
/// first-time player sees where to tap. Reduced motion: it stays still.
class PlayCue extends StatefulWidget {
  const PlayCue({super.key});

  static const double size = 18;

  @override
  State<PlayCue> createState() => _PlayCueState();
}

class _PlayCueState extends State<PlayCue> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: _period,
  );

  static const Duration _period = Duration(milliseconds: 1400);
  static const double _lift = 3;
  static const double _glyph = 11;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _bob.stop();
      _bob.value = 0;
    } else if (!_bob.isAnimating) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  late final Animation<double> _eased = CurvedAnimation(
    parent: _bob,
    curve: DaylightMotion.ease,
  );

  // The bob moves the painted tile on its own layer and rebuilds nothing (NFR-3): a rebuild
  // under the room's LayoutBuilder lays it out again, which repainted the whole tower (some
  // 390 render objects) every frame.
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: _Lifted(
      by: _eased,
      lift: _lift,
      child: Container(
        width: PlayCue.size,
        height: PlayCue.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DaylightColors.honey,
          borderRadius: BorderRadius.circular(DaylightRadius.tag),
          boxShadow: DaylightElevation.edgeOf(
            DaylightColors.honeyEdge,
            depth: DaylightSize.edgeSmall,
          ),
        ),
        child: const Icon(
          PhosphorFill.play,
          size: _glyph,
          color: DaylightColors.onHoney,
        ),
      ),
    ),
  );
}

/// Paints [child] raised by [lift] × [by]'s value. It repaints when [by] ticks and never
/// rebuilds or lays out: the paint-only twin of `Transform.translate` in an `AnimatedBuilder`.
class _Lifted extends SingleChildRenderObjectWidget {
  const _Lifted({required this.by, required this.lift, super.child});

  final Animation<double> by;
  final double lift;

  @override
  _RenderLifted createRenderObject(BuildContext context) =>
      _RenderLifted(by: by, lift: lift);

  @override
  void updateRenderObject(BuildContext context, _RenderLifted renderObject) =>
      renderObject
        ..by = by
        ..lift = lift;
}

/// [_Lifted]'s render object.
class _RenderLifted extends RenderProxyBox {
  _RenderLifted({required this._by, required this._lift});

  Animation<double> _by;
  set by(Animation<double> value) {
    if (value == _by) return;
    if (attached) _by.removeListener(markNeedsPaint);
    _by = value;
    if (attached) _by.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double _lift;
  set lift(double value) {
    if (value == _lift) return;
    _lift = value;
    markNeedsPaint();
  }

  Offset get _shift => Offset(0, -_lift * _by.value);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _by.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _by.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset + _shift);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _shift,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(_shift.dx, _shift.dy, 0, 1);
}

/// The light from the open door, fanning out on the floor below its sill.
class _SpillPainter extends CustomPainter {
  const _SpillPainter();

  static const double _alpha = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.2;
    final path = Path()
      ..moveTo(inset, 0)
      ..lineTo(size.width - inset, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = DaylightColors.honey.withValues(alpha: _alpha),
    );
  }

  @override
  bool shouldRepaint(_SpillPainter old) => false;
}
