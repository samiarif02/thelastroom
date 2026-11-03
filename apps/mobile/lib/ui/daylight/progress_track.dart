import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';

/// The progress bar: an 8 tall track in [track] with a fill in [fill] (the floor's colour by
/// default) at [value] (0…1). The fill grows from the left over [DaylightMotion.move] after
/// [delay] (a scale, so only a transform animates); under reduced motion it's just there.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.fill,
    this.track = DaylightColors.sand,
    this.height = DaylightSpace.s8,
    this.animate = true,
    this.delay = Duration.zero,
  });

  final double value;
  final Color? fill;
  final Color track;
  final double height;
  final bool animate;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colour = fill ?? ChapterTint.floorOf(context).base;
    final still = !animate || MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(height / 2);
    final bar = DecoratedBox(
      decoration: BoxDecoration(color: colour, borderRadius: radius),
    );
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ColoredBox(
          color: track,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: still ? bar : _Grow(delay: delay, child: bar),
          ),
        ),
      ),
    );
  }
}

class _Grow extends StatefulWidget {
  const _Grow({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_Grow> createState() => _GrowState();
}

class _GrowState extends State<_Grow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: DaylightMotion.move,
  );

  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _wait = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: CurvedAnimation(parent: _c, curve: DaylightMotion.ease),
    alignment: Alignment.centerLeft,
    child: widget.child,
  );
}
