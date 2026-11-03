import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';

/// How much the interviewer trusts the answer so far (replaces the heartbeat line): a handshake
/// and [max] pips on a white tile, [trust] of them in the floor's colour. A pip fills over
/// [DaylightMotion.colour].
class TrustPips extends StatelessWidget {
  const TrustPips({
    super.key,
    required this.trust,
    required this.icon,
    this.max = 5,
    this.floor,
  });

  final int trust;

  /// The handshake glyph (Phosphor fill).
  final IconData icon;
  final int max;
  final FloorColours? floor;

  static const double _pipWidth = 6;
  static const double _pipHeight = 12;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    return Semantics(
      label: 'Trust, $trust of $max',
      excludeSemantics: true,
      child: Container(
        height: DaylightSize.iconTile,
        padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s12),
        decoration: BoxDecoration(
          color: DaylightColors.raised,
          borderRadius: BorderRadius.circular(DaylightRadius.tile),
          boxShadow: DaylightElevation.edgeOf(
            DaylightColors.sand2,
            depth: DaylightSize.edgeSmall,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _iconSize, color: f.deep),
            const SizedBox(width: DaylightSpace.s8),
            for (var i = 0; i < max; i++) ...[
              if (i > 0) const SizedBox(width: DaylightSpace.s4),
              AnimatedContainer(
                duration: DaylightMotion.colour,
                curve: DaylightMotion.ease,
                width: _pipWidth,
                height: _pipHeight,
                decoration: BoxDecoration(
                  color: i < trust ? f.base : DaylightColors.sand2,
                  borderRadius: BorderRadius.circular(DaylightSpace.s2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
