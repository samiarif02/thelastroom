import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A card on the vivid screens (brief 17): a rounded gradient panel with a hairline edge,
/// lifted by a shadow, or by a coloured glow when it's the one that matters.
///
/// The Recall Room uses it; the tower's feature cards and the progress screen still carry their
/// own private copies (`_FeatureCard`, `_Panel`) and can move onto this one.
class VividPanel extends StatelessWidget {
  const VividPanel({super.key, required this.child, this.colors, this.glow});

  final Widget child;

  /// The fill; null is the current theme's slate to night.
  final List<Color>? colors;
  final Color? glow;

  List<Color> get _fill => colors ?? [BrandVivid.locked, BrandVivid.night];

  @override
  Widget build(BuildContext context) {
    final g = glow;
    return Container(
      padding: const EdgeInsets.all(BrandSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _fill,
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: g == null ? BrandVivid.cardShadow : BrandVivid.glowShadow(g),
      ),
      child: child,
    );
  }
}
