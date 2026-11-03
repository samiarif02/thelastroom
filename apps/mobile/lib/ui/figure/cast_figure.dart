import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../film/ambient_clock.dart';
import 'cast_painter.dart';

/// One of the cast, drawn live (direction.md, "Characters"): [person] wearing [expression],
/// with the idle every state shares (a blink every 4–6 s, a breath, a ±1° sway) on the
/// [AmbientClock]. A change of expression blends over [DaylightMotion.colour] on the base curve
/// (the brows and the open eyes morph, the rest cross-fades); entering
/// [CastExpression.nod] dips the head 4 and brings it back over [DaylightMotion.nod].
///
/// Reduced motion (`MediaQuery.disableAnimations`) stops the idle and makes every change
/// instant; the nod then holds the head down, like the cast sheet. Off screen (`TickerMode`
/// off, as under a covering route) the idle rests too.
///
/// Fills its box with the 200 × 200 bust standing on the bottom edge; in an unbounded box it
/// takes a square. Crop or frame it from outside (`ArchFrame`, a `ClipRRect`).
class CastFigure extends StatefulWidget {
  const CastFigure({
    super.key,
    required this.person,
    this.expression = CastExpression.neutral,
    this.idle = true,
    this.semanticLabel,
    this.extendBelow = 0,
  });

  final CastPerson person;
  final CastExpression expression;

  /// Breathing, blinking and swaying. Off for small faces in long lists, where the motion
  /// barely shows but each one would repaint every frame.
  final bool idle;

  /// What a screen reader hears ("Marcus, the hiring manager, listening"). Null leaves it
  /// decorative.
  final String? semanticLabel;

  /// Grid units the torso continues below the bust, for a frame taller than it.
  final double extendBelow;

  @override
  State<CastFigure> createState() => _CastFigureState();
}

class _CastFigureState extends State<CastFigure> with TickerProviderStateMixin {
  late final AnimationController _blend = AnimationController(
    vsync: this,
    duration: DaylightMotion.colour,
    value: 1,
  );
  late final AnimationController _nod = AnimationController(
    vsync: this,
    duration: DaylightMotion.nod,
  );
  late CastPose _from = widget.expression.pose;

  @override
  void didUpdateWidget(CastFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression == widget.expression) return;
    // Mid-blend, the new blend starts from where the face was heading.
    _from = oldWidget.expression.pose;
    if (MediaQuery.disableAnimationsOf(context)) {
      _blend.value = 1;
      _nod.value = 0;
      return;
    }
    _blend.forward(from: 0);
    if (widget.expression == CastExpression.nod) _nod.forward(from: 0);
  }

  @override
  void dispose() {
    _blend.dispose();
    _nod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    // A face on a screen that's covered (the tower under a room) doesn't breathe: nothing would
    // see it, and its clock would ask for every frame (NFR-3).
    final shown = TickerMode.valuesOf(context).enabled;
    final painter = CastPainter(
      person: widget.person,
      from: _from,
      to: widget.expression.pose,
      blend: _blend,
      nod: _nod,
      clock: widget.idle && !still && shown ? AmbientClock.of(context) : null,
      nodMoves: !still,
      extendBelow: widget.extendBelow,
    );
    final painted = LayoutBuilder(
      builder: (context, box) {
        final paint = RepaintBoundary(child: CustomPaint(painter: painter));
        return box.hasBoundedWidth && box.hasBoundedHeight
            ? SizedBox.expand(child: paint)
            : AspectRatio(aspectRatio: 1, child: paint);
      },
    );
    final label = widget.semanticLabel;
    if (label == null) return ExcludeSemantics(child: painted);
    return Semantics(image: true, label: label, child: painted);
  }
}
