import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A cue that fires once when the timeline passes [at] (0–1): a haptic thud, say.
typedef TimelineCue = ({double at, VoidCallback fire});

/// Plays a frame's choreography once, as a 0–1 clock handed to [builder].
///
/// Under reduced motion there is no choreography: the frame appears in its final state with a
/// short cross-fade (docs/rules/components.md).
class Timeline extends StatefulWidget {
  const Timeline({
    super.key,
    required this.duration,
    required this.builder,
    this.cues = const [],
    this.child,
  });

  final Duration duration;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final List<TimelineCue> cues;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.value = 1;
    } else {
      _clock
        ..addListener(_fireCues)
        ..forward();
    }
  }

  void _fireCues() {
    for (var i = 0; i < widget.cues.length; i++) {
      if (!_fired.contains(i) && _clock.value >= widget.cues[i].at) {
        _fired.add(i);
        widget.cues[i].fire();
      }
    }
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
    if (!MediaQuery.disableAnimationsOf(context)) return animated;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: BrandMotion.reducedMotionFade,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: animated,
    );
  }
}
