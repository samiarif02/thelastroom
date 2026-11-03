import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';

/// Who says a tip, and in which colours: the cast member, their arch's ground, their name's ink.
@immutable
class TipVoice {
  const TipVoice({
    required this.person,
    required this.ground,
    required this.ink,
  });

  /// Someone in their room, in the floor's colours (the floor's deep is AA on white).
  TipVoice.inRoom(this.person, FloorColours floor)
    : ground = floor.soft,
      ink = floor.deep;

  final CastPerson person;
  final Color ground;
  final Color ink;

  /// Priya on the tower, in Recall's colours.
  static const TipVoice priya = TipVoice(
    person: CastPeople.priya,
    ground: DaylightColors.recallSoft,
    ink: DaylightColors.recall,
  );
}

/// One tip in a speech bubble: the speaker in a small arch, their name, the line, "Got it".
class TipBubble extends StatelessWidget {
  const TipBubble({
    super.key,
    required this.voice,
    required this.line,
    required this.onGotIt,
  });

  final TipVoice voice;
  final String line;
  final VoidCallback onGotIt;

  static const String gotIt = 'Got it';

  static const double _face = 48;
  static const double _faceHeight = 56;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DaylightColors.raised,
      borderRadius: BorderRadius.circular(DaylightRadius.panel),
      boxShadow: DaylightElevation.lift,
    ),
    child: Padding(
      padding: const EdgeInsets.all(DaylightSpace.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArchPortrait(
                person: voice.person,
                expression: CastExpression.smile,
                width: _face,
                height: _faceHeight,
                ground: voice.ground,
                idle: false,
              ),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voice.person.name,
                        style: DaylightType.caption3.copyWith(color: voice.ink),
                      ),
                      const SizedBox(height: DaylightSpace.s2),
                      Text(line, style: DaylightType.body2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s12),
          Align(
            alignment: Alignment.centerRight,
            child: TactileButton(
              label: gotIt,
              tone: TactileTone.quiet,
              compact: true,
              expand: false,
              onPressed: onGotIt,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The cut-out's shape: an arch round a door, a rounded card round anything else.
enum TipShape { arch, card }

/// What the target under a tip is, and so what a tap on it through the cut-out does.
enum TipTarget {
  /// One obvious action (the door, a tab, the recorder): the tap goes through and does it.
  action,

  /// Things to choose between (answer cards, reason cards): the tap only puts the tip away and
  /// leaves them lit, never picks one (QA 51, BUG-2: a tap meant for the tip gave a reason the
  /// player never saw). The player then picks on purpose.
  choice,
}

/// A tip over its target (the tower tour, generalised): the screen dims except for a lit
/// cut-out round [target], and the cast member says the line in a bubble beside it. A tap on
/// the target puts the tip away ([onTarget]); on an [TipTarget.action] target it also goes
/// through and does its normal action, on a [TipTarget.choice] it picks nothing. "Got it" or a
/// tap anywhere else is [onDismiss]. Under reduced motion it simply appears.
class TipOverlay extends StatelessWidget {
  const TipOverlay({
    super.key,
    required this.voice,
    required this.line,
    required this.target,
    required this.onTarget,
    required this.onDismiss,
    this.shape = TipShape.card,
    this.kind = TipTarget.action,
  });

  final TipVoice voice;
  final String line;

  /// The target, in this overlay's coordinates.
  final Rect target;
  final VoidCallback onTarget;
  final VoidCallback onDismiss;
  final TipShape shape;
  final TipTarget kind;

  static const String label = 'Tip';

  static const double _pad = 10;
  static const double _scrim = 0.62;

  /// The least height the bubble is given (with the text's scale). A tall target with large
  /// text leaves less beside it: then the bubble covers the target's near edge rather than
  /// shrinking past reading.
  static const double _minRoomFixed = 60;
  static const double _minRoomText = 110;

  /// The cut-out, a little larger than the target (before it gives way to the bubble).
  Rect get hole => target.inflate(_pad);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final hole = this.hole;
    final lowest = insets.top + DaylightSpace.s8;
    final highest = size.height - insets.bottom - DaylightSpace.s8;
    // The bubble goes where there's more room: above the target, or below it.
    final above =
        hole.top - insets.top > size.height - insets.bottom - hole.bottom;
    var top = above ? lowest : hole.bottom + DaylightSpace.s12;
    var bottom = above ? hole.top - DaylightSpace.s12 : highest;
    final minRoom =
        _minRoomFixed + MediaQuery.textScalerOf(context).scale(_minRoomText);
    if (bottom - top < minRoom) {
      if (above) {
        bottom = math.min(highest, top + minRoom);
      } else {
        top = math.max(lowest, bottom - minRoom);
      }
    }
    // When the bubble has to take some of the target's space, the cut-out starts where the
    // bubble ends: never a lit window half under it.
    var cut = hole;
    if (above && cut.top < bottom + DaylightSpace.s8) {
      cut = Rect.fromLTRB(
        cut.left,
        math.min(bottom + DaylightSpace.s8, cut.bottom),
        cut.right,
        cut.bottom,
      );
    } else if (!above && cut.bottom > top - DaylightSpace.s8) {
      cut = Rect.fromLTRB(
        cut.left,
        cut.top,
        cut.right,
        math.max(top - DaylightSpace.s8, cut.top),
      );
    }
    final tip = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Anywhere but the target puts the tip away; the cut-out lets taps through.
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: onDismiss,
            child: CustomPaint(
              size: Size.infinite,
              painter: _Spotlight(hole: cut, shape: shape, dim: _scrim),
            ),
          ),
          // The target itself, through the cut-out: the tip goes. An action's tap still reaches
          // what's underneath (translucent); a choice's stops here, so nothing is picked.
          Positioned.fromRect(
            rect: cut,
            child: switch (kind) {
              TipTarget.action => Listener(
                behavior: HitTestBehavior.translucent,
                onPointerUp: (_) => onTarget(),
              ),
              TipTarget.choice => GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: onTarget,
              ),
            },
          ),
          // The bubble in the space above or below, scrolling if it's taller (large text), so
          // "Got it" is always reachable.
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: math.max(0, bottom - top),
            child: Align(
              alignment: above ? Alignment.bottomCenter : Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DaylightSpace.s16,
                ),
                child: TipBubble(voice: voice, line: line, onGotIt: onDismiss),
              ),
            ),
          ),
        ],
      ),
    );
    if (still) return tip;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: DaylightMotion.move,
      curve: DaylightMotion.ease,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: tip,
    );
  }
}

/// Where [key]'s widget is in [overlay]'s coordinates, cut to what its scroll view shows; null
/// when it isn't laid out or isn't on screen (the tip then waits, never blocks).
Rect? tipTarget(GlobalKey key, BuildContext overlay) {
  final context = key.currentContext;
  final box = context?.findRenderObject();
  final screen = overlay.findRenderObject();
  if (context == null ||
      box is! RenderBox ||
      screen is! RenderBox ||
      !box.attached ||
      !box.hasSize ||
      !screen.hasSize) {
    return null;
  }
  Rect inScreen(RenderBox b) =>
      MatrixUtils.transformRect(b.getTransformTo(screen), Offset.zero & b.size);
  var rect = inScreen(box);
  final view = Scrollable.maybeOf(context)?.context.findRenderObject();
  if (view is RenderBox && view.hasSize) {
    rect = rect.intersect(inScreen(view));
  }
  rect = rect.intersect(Offset.zero & screen.size);
  if (rect.width <= 0 || rect.height <= 0) return null;
  return rect;
}

/// The dim, with a hole round the target (an arch, or a rounded card) and a honey ring on its
/// edge. Taps inside the hole aren't the dim's: they go through to the target.
class _Spotlight extends CustomPainter {
  const _Spotlight({
    required this.hole,
    required this.shape,
    required this.dim,
  });

  final Rect hole;
  final TipShape shape;
  final double dim;

  static const double _ring = 2;

  RRect get _cut => switch (shape) {
    TipShape.arch => RRect.fromRectAndCorners(
      hole,
      topLeft: Radius.circular(hole.width / 2),
      topRight: Radius.circular(hole.width / 2),
      bottomLeft: const Radius.circular(DaylightRadius.inner),
      bottomRight: const Radius.circular(DaylightRadius.inner),
    ),
    TipShape.card => RRect.fromRectAndRadius(
      hole,
      const Radius.circular(DaylightRadius.panel),
    ),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final cut = _cut;
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(cut),
    );
    canvas
      ..drawPath(
        shade,
        Paint()..color = DaylightColors.ink.withValues(alpha: dim),
      )
      ..drawRRect(
        cut,
        Paint()
          ..color = DaylightColors.honey
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ring,
      );
  }

  @override
  bool hitTest(Offset position) => !_cut.contains(position);

  @override
  bool shouldRepaint(_Spotlight old) =>
      old.hole != hole || old.shape != shape || old.dim != dim;
}
