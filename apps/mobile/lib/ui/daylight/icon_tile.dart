import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'tactile.dart';

/// An icon button (direction.md: "icon buttons are 40 inside a 48 hit area"). [raised] is the
/// top bar's white tile with a 2 px edge (close, back); [quiet] is a 32 sand tile inside a card
/// (the welcome-back card's dismiss). Always labelled for screen readers.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.quiet = false,
    this.pressed,
  });

  /// The quiet, in-card tile.
  const IconTile.quiet({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.pressed,
  }) : quiet = true;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool quiet;
  final bool? pressed;

  static const double _quietSize = 32;
  static const double _iconSize = 20;
  static const double _quietIconSize = 16;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final size = quiet ? _quietSize : DaylightSize.iconTile;
    final ink = enabled
        ? (quiet ? DaylightColors.ink2 : DaylightColors.ink)
        : DaylightColors.ink3;
    return Tactile(
      label: semanticLabel,
      onTap: onPressed,
      pressed: pressed,
      style: TactileStyle(
        face: quiet ? DaylightColors.sand : DaylightColors.raised,
        edge: quiet ? DaylightColors.sand : DaylightColors.sand2,
        radius: BorderRadius.circular(
          quiet ? DaylightRadius.inner : DaylightRadius.tile,
        ),
        depth: quiet ? 0 : DaylightSize.edgeSmall,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, size: quiet ? _quietIconSize : _iconSize, color: ink),
      ),
    );
  }
}
