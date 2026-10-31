import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A card on the vivid screens (brief 17): a rounded gradient panel with a hairline edge,
/// lifted by a shadow, or by a coloured glow when it's the one that matters.
///
/// The Recall Room uses it; the tower's feature cards and the progress screen still carry their
/// own private copies (`_FeatureCard`, `_Panel`) and can move onto this one.
class VividPanel extends StatelessWidget {
  const VividPanel({
    super.key,
    required this.child,
    this.colors = const [BrandVivid.locked, BrandVivid.night],
    this.glow,
  });

  final Widget child;
  final List<Color> colors;
  final Color? glow;

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
          colors: colors,
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: g == null ? BrandVivid.cardShadow : BrandVivid.glowShadow(g),
      ),
      child: child,
    );
  }
}
