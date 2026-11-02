import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A staggered entrance (direction.md: "60 ms apart, 400 ms cap"): [child] fades in and rises
/// [rise] over [DaylightMotion.move] on the base curve, [index] steps after the first. Under
/// reduced motion it only fades, over [DaylightMotion.colour].
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.rise = DaylightSpace.s8,
  });

  final Widget child;
  final int index;
  final double rise;

  /// When the [index]th item starts.
  static Duration delayOf(int index) {
    final d = DaylightMotion.stagger * index;
    return d > DaylightMotion.staggerCap ? DaylightMotion.staggerCap : d;
  }

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: DaylightMotion.move,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: DaylightMotion.ease,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.duration = DaylightMotion.colour;
      _c.forward();
      return;
    }
    Future<void>.delayed(Entrance.delayOf(widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, still ? 0 : widget.rise * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
