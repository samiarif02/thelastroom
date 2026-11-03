import 'dart:async';
import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// How a Daylight screen arrives, and leaves again on back (the owner, brief 50: "when we enter
/// a screen and come back with the back button… give the app a premium look"). Back is always
/// the exact reverse of the arrival, so leaving feels like stepping back out. Under reduced
/// motion every kind is a [DaylightMotion.reducedPage] cross-fade.
enum DaylightTransition {
  /// One screen opened from another (shared axis): the new one slides in from the trailing
  /// edge as it fades in; the one below drifts the other way and dims.
  push,

  /// Between the tab bar's destinations and the roots (fade-through): the old screen fades to
  /// the paper ground, then the new one fades in from a touch smaller.
  through,

  /// Into a room (the signature): the room grows out of its door on the tower inside an arch,
  /// and shrinks back into it on the way out. The tower leans in toward the door and dims.
  door,

  /// A screen whose own entrance is the show (the Candidate assessment): only a short fade,
  /// nothing slides, so the sheet's timeline plays exactly as it always has.
  ground;

  /// How long the arrival (and the return) takes with motion on.
  Duration get duration => switch (this) {
    push || through => DaylightMotion.page,
    door => DaylightMotion.door,
    ground => DaylightMotion.ground,
  };
}

/// Where a room's door is on screen, in global coordinates: the arch a room grows out of
/// ([DaylightTransition.door]). It travels as the route's `extra`, so it encodes as JSON
/// (go_router keeps `extra` in the browser's history).
@immutable
class DoorOrigin {
  const DoorOrigin(this.rect);

  final Rect rect;

  /// The rect [context]'s box covers on screen; null before it is laid out.
  static DoorOrigin? of(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return DoorOrigin(box.localToGlobal(Offset.zero) & box.size);
  }

  /// Reads an origin back from a route's `extra`: the object, or its JSON after a restore.
  static DoorOrigin? from(Object? extra) => switch (extra) {
    final DoorOrigin origin => origin,
    {
      _left: final num l,
      _top: final num t,
      _width: final num w,
      _height: final num h,
    } =>
      DoorOrigin(
        Rect.fromLTWH(l.toDouble(), t.toDouble(), w.toDouble(), h.toDouble()),
      ),
    _ => null,
  };

  Map<String, double> toJson() => {
    _left: rect.left,
    _top: rect.top,
    _width: rect.width,
    _height: rect.height,
  };

  static const String _left = 'doorLeft';
  static const String _top = 'doorTop';
  static const String _width = 'doorWidth';
  static const String _height = 'doorHeight';

  @override
  bool operator ==(Object other) => other is DoorOrigin && other.rect == rect;

  @override
  int get hashCode => rect.hashCode;
}

/// Sent up the tree by a tapped door with where it is, so the screen that opens the room can
/// hand the rect to the route ([DoorOrigin]).
class DoorTapped extends Notification {
  DoorTapped(this.origin);

  final DoorOrigin origin;
}

/// A go_router page with a Daylight [transition]. Every route in the app is built with one
/// (`router.dart`), so pushes, backs, tab switches and rooms all move the same way.
class DaylightPage<T> extends Page<T> {
  const DaylightPage({
    required this.child,
    this.transition = DaylightTransition.push,
    this.door,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final DaylightTransition transition;

  /// For [DaylightTransition.door]: the door the room grows from; null for the default door,
  /// mid-screen.
  final DoorOrigin? door;

  @override
  Route<T> createRoute(BuildContext context) => DaylightPageRoute<T>(this);
}

/// The route a [DaylightPage] makes. It builds its own arrival, moves out of the way the way
/// the Daylight route opened above it asks (one widget shape whatever the kind, so a screen is
/// never rebuilt mid-transition), and it follows Android's predictive back
/// gesture (14+): the swipe scrubs the same reverse transition, so the screen behind is
/// previewed and a cancelled swipe springs back.
class DaylightPageRoute<T> extends PageRoute<T> {
  DaylightPageRoute(DaylightPage<T> page) : super(settings: page);

  DaylightPage<T> get _page => settings as DaylightPage<T>;

  /// Whether this route's motion is the reduced cross-fade: read once, as it is pushed.
  bool _still = false;

  @override
  AnimationController createAnimationController() {
    final nav = navigator;
    _still =
        nav != null &&
        (MediaQuery.maybeDisableAnimationsOf(nav.context) ?? false);
    return super.createAnimationController();
  }

  /// The transition this route actually plays.
  @visibleForTesting
  DaylightTransition get transition => _page.transition;

  /// Whether it plays the reduced cross-fade instead.
  @visibleForTesting
  bool get reduced => _still;

  @override
  Duration get transitionDuration =>
      _still ? DaylightMotion.reducedPage : _page.transition.duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  /// The door last tapped on this screen ([DoorTapped]), until a room takes it.
  DoorOrigin? _tappedDoor;

  /// The door last tapped on [context]'s screen, once: the room opening now grows from it.
  static DoorOrigin? takeDoor(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is! DaylightPageRoute) return null;
    final door = route._tappedDoor;
    route._tappedDoor = null;
    return door;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => NotificationListener<DoorTapped>(
    onNotification: (n) {
      _tappedDoor = n.origin;
      return true;
    },
    child: Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _page.child,
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _PredictiveBack(
    route: this,
    child: DaylightRouteMotion(
      transition: _page.transition,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      reduced: _still,
      gesture: popGestureInProgress,
      door: _localDoor(),
      below: _aboveKind,
      belowDoor: _aboveDoor,
      child: child,
    ),
  );

  /// How this route moves while the Daylight route last opened above it arrives (and, as it
  /// stays set through that route's return, while it leaves): its kind, and its door.
  DaylightTransition? _aboveKind;
  Rect? _aboveDoor;

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    if (nextRoute is DaylightPageRoute<Object?>) {
      // Above a reduced-motion route nothing moves: the arrival is only a fade.
      _aboveKind = nextRoute._still
          ? DaylightTransition.ground
          : nextRoute._page.transition;
      _aboveDoor = nextRoute._localDoor();
    }
    super.didChangeNext(nextRoute);
  }

  /// The door's rect in the navigator's coordinates (the navigator fills the screen, so
  /// almost always the global rect itself).
  Rect? _localDoor() {
    final door = _page.door?.rect;
    if (door == null) return null;
    final box = navigator?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return door;
    return door.shift(-box.localToGlobal(Offset.zero));
  }
}

/// The arrival itself, for a route's [animation], plus how the route moves while another
/// arrives above it ([secondaryAnimation], [below]). Public so the catalog and tests can draw
/// any frame of it without a navigator.
class DaylightRouteMotion extends StatefulWidget {
  const DaylightRouteMotion({
    super.key,
    required this.transition,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.reduced = false,
    this.gesture = false,
    this.door,
    this.below,
    this.belowDoor,
  });

  final DaylightTransition transition;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  /// The kind of route arriving above this one ([secondaryAnimation]); null: this route's own.
  final DaylightTransition? below;

  /// That route's door, for [DaylightTransition.door].
  final Rect? belowDoor;

  /// Reduced motion: a cross-fade only.
  final bool reduced;

  /// A back gesture is scrubbing the animation: follow the finger linearly.
  final bool gesture;

  /// The door's rect for [DaylightTransition.door]; null for the default door.
  final Rect? door;

  /// How far the arriving screen travels in from the trailing edge, and how far the one
  /// below drifts the other way (half: a parallax).
  static const double shift = DaylightSpace.s32;
  static const double drift = DaylightSpace.s16;

  /// The ink laid over the screen below at the end of a push, and of a door.
  static const double pushDim = 0.12;
  static const double doorDim = 0.2;

  /// Fade-through: the share of the time the old screen takes to fade out; the new one fades
  /// in over the rest, growing from [throughScale].
  static const double throughOut = 0.35;
  static const double throughScale = 0.98;

  /// A push fades the new screen in over the first share of its travel.
  static const double pushFade = 0.6;

  /// Door: the room fades in over the first share while its arch grows; it starts at
  /// [doorScale] round the door and the honey rim fades out by [doorRimOut].
  static const double doorFade = 0.35;
  static const double doorScale = 0.9;
  static const double doorRimOut = 0.6;

  /// How far the tower leans in toward the door as the room opens.
  static const double doorLean = 1.05;

  /// The default door when the room wasn't opened from one (a button, a deep link):
  /// mid-screen, the tower's door proportions.
  static const Size defaultDoor = Size(DaylightSpace.s64, DaylightSpace.s96);

  @override
  State<DaylightRouteMotion> createState() => _DaylightRouteMotionState();
}

class _DaylightRouteMotionState extends State<DaylightRouteMotion> {
  late CurvedAnimation _t;

  @override
  void initState() {
    super.initState();
    _t = _curve(widget.animation, widget.transition);
  }

  @override
  void didUpdateWidget(DaylightRouteMotion old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation ||
        old.transition != widget.transition) {
      _t.dispose();
      _t = _curve(widget.animation, widget.transition);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.gesture ? widget.animation : _t;
    final below = widget.reduced
        ? widget.child
        : _Below(
            transition: widget.below ?? widget.transition,
            animation: widget.secondaryAnimation,
            door: widget.below == null ? widget.door : widget.belowDoor,
            child: widget.child,
          );
    if (widget.reduced) return FadeTransition(opacity: t, child: below);
    return switch (widget.transition) {
      DaylightTransition.push => _push(context, t, below),
      DaylightTransition.through => _through(t, below),
      DaylightTransition.door => _ArchReveal(
        animation: t,
        door: widget.door,
        child: below,
      ),
      DaylightTransition.ground => FadeTransition(opacity: t, child: below),
    };
  }

  Widget _push(BuildContext context, Animation<double> t, Widget child) {
    final sign = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Opacity(
        opacity: _share(t.value, 0, DaylightRouteMotion.pushFade),
        child: Transform.translate(
          offset: Offset(sign * DaylightRouteMotion.shift * (1 - t.value), 0),
          child: child,
        ),
      ),
    );
  }

  Widget _through(Animation<double> t, Widget child) => AnimatedBuilder(
    animation: t,
    child: child,
    builder: (context, child) {
      const out = DaylightRouteMotion.throughOut;
      final inT = _share(t.value, out, 1);
      return Stack(
        fit: StackFit.passthrough,
        children: [
          // The old screen fading to the ground: the ground fading in over it.
          Positioned.fill(
            child: Opacity(
              opacity: _share(t.value, 0, out),
              child: const ColoredBox(color: DaylightColors.paper),
            ),
          ),
          Opacity(
            opacity: inT,
            child: Transform.scale(
              scale:
                  DaylightRouteMotion.throughScale +
                  (1 - DaylightRouteMotion.throughScale) * inT,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// The base curve forward, and its mirror back, so a return decelerates into place too. A
/// door swings on [DaylightMotion.swing] both ways: it starts visibly at the door's frame.
CurvedAnimation _curve(Animation<double> parent, DaylightTransition kind) =>
    kind == DaylightTransition.door
    ? CurvedAnimation(parent: parent, curve: DaylightMotion.swing)
    : CurvedAnimation(
        parent: parent,
        curve: DaylightMotion.ease,
        reverseCurve: DaylightMotion.ease.flipped,
      );

/// [t]'s progress through the window [from]–[to], clamped to 0–1.
double _share(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

/// A route's motion while a route of [transition] arrives above it.
class _Below extends StatefulWidget {
  const _Below({
    required this.transition,
    required this.animation,
    required this.child,
    this.door,
  });

  final DaylightTransition transition;
  final Animation<double> animation;
  final Widget child;
  final Rect? door;

  @override
  State<_Below> createState() => _BelowState();
}

class _BelowState extends State<_Below> {
  late CurvedAnimation _t;

  @override
  void initState() {
    super.initState();
    _t = _curve(widget.animation, widget.transition);
  }

  @override
  void didUpdateWidget(_Below old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation ||
        old.transition != widget.transition) {
      _t.dispose();
      _t = _curve(widget.animation, widget.transition);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final sign = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    // One shape whatever arrives above (only the numbers change), so the screen's subtree is
    // never rebuilt when a different kind of route opens over it.
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _t,
        child: child,
        builder: (context, child) {
          final t = _t.value;
          final size = box.biggest;
          final (Matrix4 move, double dim) = switch (widget.transition) {
            DaylightTransition.through ||
            DaylightTransition.ground => (Matrix4.identity(), 0),
            DaylightTransition.push => (
              Matrix4.translationValues(
                -sign * DaylightRouteMotion.drift * t,
                0,
                0,
              ),
              DaylightRouteMotion.pushDim * t,
            ),
            DaylightTransition.door => (
              _scaleAbout(
                _doorRect(widget.door, size).center,
                1 + (DaylightRouteMotion.doorLean - 1) * t,
              ),
              DaylightRouteMotion.doorDim * t,
            ),
          };
          // The ground under it, so the strip it drifts off never shows the void.
          return ColoredBox(
            color: DaylightColors.paper,
            child: Transform(
              transform: move,
              child: _Dim(amount: dim, child: child!),
            ),
          );
        },
      ),
    );
  }
}

/// Scales by [scale] about [point].
Matrix4 _scaleAbout(Offset point, double scale) =>
    Matrix4.translationValues(point.dx, point.dy, 0)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-point.dx, -point.dy, 0, 1);

/// [child] with ink laid over it at [amount].
class _Dim extends StatelessWidget {
  const _Dim({required this.amount, required this.child});

  final double amount;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      color: DaylightColors.ink.withValues(alpha: amount),
    ),
    child: child,
  );
}

/// The door's rect in a screen of [size]: the given one, or the default door mid-screen.
Rect _doorRect(Rect? door, Size size) =>
    door ??
    Rect.fromCenter(
      center: size.center(Offset.zero),
      width: DaylightRouteMotion.defaultDoor.width,
      height: DaylightRouteMotion.defaultDoor.height,
    );

/// The arch that covers a whole [size] screen: twice as wide, its round top clear of both top
/// corners, so the last frame of the reveal shows the full room.
@visibleForTesting
Rect coverArch(Size size) {
  final w = size.width;
  // A circle of radius w centred on the screen's middle line passes x = 0 at w·(1 − √3/2)
  // below its top: a quarter of w above the screen is clear of that.
  const above = 0.25;
  return Rect.fromLTRB(-w / 2, -w * above, w * 1.5, size.height);
}

/// An arch (round top, square foot) filling [rect].
@visibleForTesting
Path archPath(Rect rect) {
  final r = Radius.circular(math.min(rect.width / 2, rect.height));
  return Path()
    ..addRRect(RRect.fromRectAndCorners(rect, topLeft: r, topRight: r));
}

/// The arch a door transition shows at [t] (0: the door itself; 1: the whole screen).
@visibleForTesting
Rect archAt(double t, Rect? door, Size size) =>
    Rect.lerp(_doorRect(door, size), coverArch(size), t)!;

/// The room growing out of its door: clipped to an arch that grows from the door's rect to
/// the whole screen, the room scaling up from round the door and fading in over a honey
/// doorway, with the door's honey rim fading as it opens.
class _ArchReveal extends StatelessWidget {
  const _ArchReveal({required this.animation, required this.child, this.door});

  final Animation<double> animation;
  final Widget child;
  final Rect? door;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      final from = _doorRect(door, size);
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final t = animation.value;
          final open = t >= 1;
          final arch = archAt(t, door, size);
          final scale =
              DaylightRouteMotion.doorScale +
              (1 - DaylightRouteMotion.doorScale) * t;
          return CustomPaint(
            foregroundPainter: _RimPainter(
              arch: arch,
              opacity: 1 - _share(t, 0, DaylightRouteMotion.doorRimOut),
            ),
            child: ClipPath(
              clipper: _ArchClipper(arch),
              // Fully open: no clip at all (same shape, so the room is never rebuilt).
              clipBehavior: open ? Clip.none : Clip.antiAlias,
              child: ColoredBox(
                color: DaylightColors.honeyTint,
                child: Opacity(
                  opacity: _share(t, 0, DaylightRouteMotion.doorFade),
                  child: Transform.scale(
                    scale: scale,
                    origin: from.center - size.center(Offset.zero),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _ArchClipper extends CustomClipper<Path> {
  const _ArchClipper(this.arch);

  final Rect arch;

  @override
  Path getClip(Size size) => archPath(arch);

  @override
  bool shouldReclip(_ArchClipper old) => old.arch != arch;
}

/// The door's honey frame, travelling with the arch.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.arch, required this.opacity});

  final Rect arch;
  final double opacity;

  static const double width = DaylightSpace.s4;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.drawPath(
      archPath(arch),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = DaylightColors.honey.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.arch != arch || old.opacity != opacity;
}

/// Android's predictive back (14+): while this route is on top and may pop, a back swipe
/// drives its animation, so the swipe previews the screen behind with the same reverse
/// transition; releasing commits the pop, cancelling springs it back. A button press, an
/// older Android or a route that can't pop (a room asks before you leave) gets the normal back.
class _PredictiveBack extends StatefulWidget {
  const _PredictiveBack({required this.route, required this.child});

  final PageRoute<Object?> route;
  final Widget child;

  @override
  State<_PredictiveBack> createState() => _PredictiveBackState();
}

class _PredictiveBackState extends State<_PredictiveBack>
    with WidgetsBindingObserver {
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    if (backEvent.isButtonEvent ||
        !route.isCurrent ||
        !route.popGestureEnabled) {
      return false;
    }
    _tracking = true;
    route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_tracking) return;
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
  }

  @override
  void handleCancelBackGesture() {
    if (!_tracking) return;
    _tracking = false;
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    if (!_tracking) return;
    _tracking = false;
    widget.route.handleCommitBackGesture();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Completes once [context]'s route has finished arriving and nothing is moving over it (a
/// screen opening or closing above it), so whatever measures a target on it (a first-time
/// tip's spotlight) measures where the target rests, not where it is mid-transition. Already
/// settled: completes at once.
Future<void> routeSettled(BuildContext context) {
  final route = ModalRoute.of(context);
  final arriving = route?.animation;
  final covering = route?.secondaryAnimation;
  bool settled() =>
      (arriving == null || arriving.isCompleted) &&
      (covering == null || covering.isDismissed);
  if (settled()) return Future.value();
  final done = Completer<void>();
  void check(AnimationStatus _) {
    if (!settled() || done.isCompleted) return;
    arriving?.removeStatusListener(check);
    covering?.removeStatusListener(check);
    done.complete();
  }

  arriving?.addStatusListener(check);
  covering?.addStatusListener(check);
  return done.future;
}
