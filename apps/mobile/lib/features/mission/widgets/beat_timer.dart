import 'package:flutter/widgets.dart';

/// The soft answer timer on timed missions (FR-13): the room's light dims over [duration], and
/// a number appears only for the last [countdownFrom] seconds. When it runs out, [onExpired]
/// fires once and the beat stays open: the timer never picks for the player or costs a point.
///
/// [builder] gets the dimming (0 → [maxDim]) and the whole seconds left, or null while no
/// number should show. Never built on an untimed mission. Key it by beat to restart it.
class BeatTimer extends StatefulWidget {
  const BeatTimer({
    super.key,
    required this.builder,
    required this.onExpired,
    required this.onPulse,
    this.running = true,
    this.duration = defaultDuration,
  });

  static const Duration defaultDuration = Duration(seconds: 60);

  /// Numbers show for the last 10 seconds.
  static const int countdownFrom = 10;

  /// The last stretch: [onPulse] fires once a second from here.
  static const int pulseFrom = 20;

  /// How dark the room gets at zero.
  static const double maxDim = 0.55;

  final Widget Function(BuildContext context, double dim, int? secondsLeft)
  builder;
  final VoidCallback onExpired;

  /// Once a second in the last stretch; [finalSeconds] once the number shows.
  final void Function({required bool finalSeconds}) onPulse;

  /// False pauses it (between beats).
  final bool running;
  final Duration duration;

  @override
  State<BeatTimer> createState() => _BeatTimerState();
}

class _BeatTimerState extends State<BeatTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: widget.duration)
        ..addListener(_onTick)
        ..addStatusListener(_onStatus);

  int? _lastPulse;

  @override
  void initState() {
    super.initState();
    if (widget.running) _clock.forward();
  }

  @override
  void didUpdateWidget(BeatTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running == widget.running) return;
    widget.running ? _clock.forward() : _clock.stop();
  }

  int get _secondsLeft =>
      (widget.duration.inSeconds * (1 - _clock.value)).ceil();

  void _onTick() {
    final left = _secondsLeft;
    if (left > BeatTimer.pulseFrom || left == _lastPulse || left == 0) return;
    _lastPulse = left;
    widget.onPulse(finalSeconds: left <= BeatTimer.countdownFrom);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onExpired();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) {
      final left = _secondsLeft;
      return widget.builder(
        context,
        BeatTimer.maxDim * _clock.value,
        left <= BeatTimer.countdownFrom ? left : null,
      );
    },
  );
}
