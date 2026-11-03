import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A free-running clock in seconds for the things that never stop: grain, dust, the flicker
/// of a lamp, an idle face's breath. Painters take [AmbientClock.of] as their `repaint`
/// listenable, so only they repaint each frame, never the widget tree. It stands still under
/// reduced motion.
///
/// It only runs while something on screen listens (NFR-3): with no painter attached it asks for
/// no frames at all, so a screen at rest costs nothing. Time picks up where it stopped.
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
  late final _Seconds _seconds = _Seconds(onListened: _wake);
  late final Ticker _ticker = createTicker(_tick);

  bool _reduced = false;

  /// The seconds run before the ticker last stopped: the clock never jumps back.
  double _before = 0;

  void _wake() {
    if (!_reduced && !_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    // Checked on the tick, not on each removal: a painter swapped for a new one (a rebuild)
    // leaves and rejoins within one frame, and the clock runs straight through it.
    if (!_seconds.listened) {
      _rest();
      return;
    }
    _seconds.value =
        _before + elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  void _rest() {
    _before = _seconds.value;
    _ticker.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced && _ticker.isActive) _rest();
    if (!_reduced && _seconds.listened) _wake();
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

/// The clock's seconds, saying when the first listener arrives.
class _Seconds extends ValueNotifier<double> {
  _Seconds({required this.onListened}) : super(0);

  final VoidCallback onListened;

  bool get listened => hasListeners;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    onListened();
  }
}

class _AmbientScope extends InheritedWidget {
  const _AmbientScope({required this.seconds, required super.child});

  final ValueNotifier<double> seconds;

  @override
  bool updateShouldNotify(_AmbientScope oldWidget) =>
      seconds != oldWidget.seconds;
}
