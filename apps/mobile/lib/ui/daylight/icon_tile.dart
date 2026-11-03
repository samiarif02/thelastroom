import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'tactile.dart';

/// An icon button (direction.md: "icon buttons are 40 inside a 48 hit area"). [raised] is the
/// top bar's white tile with a 2 px edge (close, back); [quiet] is a 32 sand tile inside a card
/// (the welcome-back card's dismiss). Always labelled for screen readers.
///
/// A back or close tile has a [nudge] (brief 50): pressed, its icon nudges
/// [nudgeDistance] toward where it goes over [DaylightMotion.nudge], then it acts, so the
/// press reads before the screen leaves. Under reduced motion it acts at once. The press itself
/// is [Tactile]'s: the face sinks and a light haptic.
class IconTile extends StatefulWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.quiet = false,
    this.pressed,
    this.nudge,
  });

  /// The quiet, in-card tile.
  const IconTile.quiet({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.pressed,
    this.nudge,
  }) : quiet = true;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool quiet;
  final bool? pressed;

  /// Which way the icon nudges before [onPressed] runs (a back tile: left; a sheet's close:
  /// down); null acts at once.
  final AxisDirection? nudge;

  /// How far the icon nudges.
  static const double nudgeDistance = DaylightSpace.s4;

  static const double _quietSize = 32;
  static const double _iconSize = 20;
  static const double _quietIconSize = 16;

  @override
  State<IconTile> createState() => _IconTileState();
}

class _IconTileState extends State<IconTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _nudge;
  CurvedAnimation? _eased;
  bool _going = false;

  AnimationController get _controller => _nudge ??= AnimationController(
    vsync: this,
    duration: DaylightMotion.nudge,
  );

  Animation<double> get _t => _eased ??= CurvedAnimation(
    parent: _controller,
    curve: DaylightMotion.ease,
  );

  Future<void> _press() async {
    final act = widget.onPressed;
    if (act == null) return;
    if (widget.nudge == null || MediaQuery.disableAnimationsOf(context)) {
      act();
      return;
    }
    // One press at a time: a second tap during the nudge doesn't act twice.
    if (_going) return;
    _going = true;
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    } finally {
      _going = false;
    }
    if (!mounted) return;
    act();
    if (mounted) unawaited(_controller.reverse());
  }

  @override
  void dispose() {
    _eased?.dispose();
    _nudge?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final enabled = w.onPressed != null;
    final size = w.quiet ? IconTile._quietSize : DaylightSize.iconTile;
    final ink = enabled
        ? (w.quiet ? DaylightColors.ink2 : DaylightColors.ink)
        : DaylightColors.ink3;
    Widget icon = Icon(
      w.icon,
      size: w.quiet ? IconTile._quietIconSize : IconTile._iconSize,
      color: ink,
    );
    if (w.nudge case final dir?) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final toward = switch (dir) {
        AxisDirection.left => Offset(rtl ? 1 : -1, 0),
        AxisDirection.right => Offset(rtl ? -1 : 1, 0),
        AxisDirection.up => const Offset(0, -1),
        AxisDirection.down => const Offset(0, 1),
      };
      icon = AnimatedBuilder(
        animation: _t,
        child: icon,
        builder: (context, child) => Transform.translate(
          offset: toward * (IconTile.nudgeDistance * _t.value),
          child: child,
        ),
      );
    }
    return Tactile(
      label: w.semanticLabel,
      onTap: enabled ? () => unawaited(_press()) : null,
      pressed: w.pressed,
      style: TactileStyle(
        face: w.quiet ? DaylightColors.sand : DaylightColors.raised,
        edge: w.quiet ? DaylightColors.sand : DaylightColors.sand2,
        radius: BorderRadius.circular(
          w.quiet ? DaylightRadius.inner : DaylightRadius.tile,
        ),
        depth: w.quiet ? 0 : DaylightSize.edgeSmall,
      ),
      child: SizedBox.square(dimension: size, child: icon),
    );
  }
}
