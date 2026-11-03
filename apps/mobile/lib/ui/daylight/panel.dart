import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A Daylight card (direction.md: "white on paper with an edge, never border plus shadow plus
/// white"): a flat face, r24 by default, the hard sand edge below, 16 inside. [color] and
/// [edge] re-colour it (the up-next card is the floor's base with its deep edge; the Recall
/// card is the recall tint with no edge). [semanticLabel] makes it one read.
class DaylightPanel extends StatelessWidget {
  const DaylightPanel({
    super.key,
    required this.child,
    this.color = DaylightColors.raised,
    this.edge = DaylightColors.sand2,
    this.radius = DaylightRadius.panel,
    this.padding = const EdgeInsets.all(DaylightSpace.s16),
  });

  final Widget child;
  final Color color;

  /// The edge's colour; null for a flat card (no edge: it isn't pressable-looking).
  final Color? edge;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final e = edge;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: e == null ? null : DaylightElevation.edgeOf(e),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A section's head on a Daylight screen ("Northstar tower" · "3 of 21 rooms lit"): Heading 6
/// on the left, an optional Body 6 aside on the right, baseline-aligned, the aside wrapping
/// under the title when there isn't room (2x text).
class SectionHead extends StatelessWidget {
  const SectionHead({super.key, required this.title, this.aside});

  final String title;
  final String? aside;

  @override
  Widget build(BuildContext context) {
    final a = aside;
    final head = Semantics(
      header: true,
      child: Text(title, style: DaylightType.heading6),
    );
    if (a == null) return head;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: DaylightSpace.s12,
      runSpacing: DaylightSpace.s2,
      children: [
        head,
        Text(a, style: DaylightType.body6.copyWith(color: DaylightColors.ink2)),
      ],
    );
  }
}
