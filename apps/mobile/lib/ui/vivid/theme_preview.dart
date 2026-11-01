import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A small picture of a theme (brief 28), drawn from [palette] itself rather than the current
/// theme, so several can sit side by side: its sky, a hero card in Chapter 1's colour with the
/// accent Play pill, and the three chapters' colours.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.palette, this.height = 120});

  final VividPalette palette;
  final double height;

  static const double _radius = 14;
  static const double _dot = 14;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return ExcludeSemantics(
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.skyTop, p.skyMid, p.skyLow],
          ),
        ),
        padding: const EdgeInsets.all(BrandSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(BrandSpace.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius - 4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [p.lobby.deep, p.lobby.deeper],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                child: Container(
                  height: _dot,
                  width: _dot * 3,
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(BrandRadius.pill),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BrandSpace.xs + 2),
            Row(
              children: [
                for (final c in [p.lobby, p.pressure, p.finalRound]) ...[
                  Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.deep,
                      border: Border.all(color: c.glow, width: 2),
                    ),
                  ),
                  const SizedBox(width: BrandSpace.xs),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
