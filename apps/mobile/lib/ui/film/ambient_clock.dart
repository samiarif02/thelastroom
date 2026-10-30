import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A free-running clock in seconds for the things that never stop: grain, dust, the flicker
/// of a lamp. Painters take [AmbientClock.of] as their `repaint` listenable, so only they
/// repaint each frame, never the widget tree. It stands still under reduced motion.
class AmbientClock extends StatefulWidget {
  const AmbientClock({super.key, required this.child});

  final Widget child;

  static ValueListenable<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AmbientScope>()?.seconds ??
      _still;

  static final ValueNotifier<double> _still = ValueNotifier(0);

  @override
  State<AmbientClock> createState() => _AmbientClockState();
}

class _AmbientClockState extends State<AmbientClock>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _seconds = ValueNotifier(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _seconds.value =
        elapsed.inMicroseconds / Duration.microsecondsPerSecond,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AmbientScope(seconds: _seconds, child: widget.child);
}

class _AmbientScope extends InheritedWidget {
  const _AmbientScope({required this.seconds, required super.child});

  final ValueNotifier<double> seconds;

  @override
  bool updateShouldNotify(_AmbientScope oldWidget) =>
      seconds != oldWidget.seconds;
}
