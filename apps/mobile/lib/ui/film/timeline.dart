import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A beat that fires once when the timeline passes [at] (0–1): a stamp landing, a seal, a pen
/// touching paper. Brief 10 hangs sound and haptics on these.
typedef TimelineCue = ({double at, VoidCallback fire});

/// Plays a choreography once, as a 0–1 clock handed to [builder]. [cues] fire as the clock
/// passes them, then [onFinished].
///
/// Under reduced motion there is no choreography: the frame appears in its final state with a
/// short cross-fade, the cues don't fire (nothing moved), and [onFinished] still does.
class Timeline extends StatefulWidget {
  const Timeline({
    super.key,
    required this.duration,
    required this.builder,
    this.cues = const [],
    this.onFinished,
    this.play = true,
    this.child,
  });

  final Duration duration;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final List<TimelineCue> cues;
  final VoidCallback? onFinished;

  /// False holds the frame at its final state without playing (the catalog's "settled" state).
  final bool play;
  final Widget? child;

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final Set<int> _fired = {};
  bool _started = false;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still || !widget.play) {
      _clock.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished?.call();
      });
      return;
    }
    _clock
      ..addListener(_fireCues)
      ..addStatusListener(_onStatus)
      ..forward();
  }

  void _fireCues() {
    for (var i = 0; i < widget.cues.length; i++) {
      if (!_fired.contains(i) && _clock.value >= widget.cues[i].at) {
        _fired.add(i);
        widget.cues[i].fire();
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onFinished?.call();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = AnimatedBuilder(
      animation: _clock,
      child: widget.child,
      builder: (context, child) => widget.builder(context, _clock.value, child),
    );
    if (!_still) return animated;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: BrandMotion.reducedMotionFade,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: animated,
    );
  }
}
