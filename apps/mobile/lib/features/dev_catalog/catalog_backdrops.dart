import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// A small component on the walnut desk under the lamp, centred, scrolling only at 2x text.
class CatalogDesk extends StatelessWidget {
  const CatalogDesk({super.key, required this.grade, required this.children});

  final ChapterGrade grade;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandColors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FilmOverlay(
            grain: 0,
            vignetteColor: grade.shadow,
            child: Spotlight(
              grade: grade,
              center: const Alignment(0, -0.5),
              intensity: 0.45,
            ),
          ),
          SafeArea(
            child: AnchoredScroll(
              alignment: MainAxisAlignment.center,
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                CatalogDesk.controlsClearance,
                BrandSpace.lg,
                BrandSpace.lg,
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Room for the catalog's control pill above the component.
  static const double controlsClearance = BrandSpace.xxl;
}

/// The Boardroom set through the camera at [t] (0 wide, 1 close), vignetted, with an optional
/// [overlay] on top (letterbox bars, a subtitle).
class CatalogRoom extends StatelessWidget {
  const CatalogRoom({
    super.key,
    required this.grade,
    this.t = 0,
    this.tight = false,
    this.overlay,
  });

  final ChapterGrade grade;
  final double t;
  final bool tight;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FilmOverlay(
          grain: 0,
          vignetteColor: grade.shadow,
          child: CameraRig(
            t: t,
            layers: BoardroomSet.layers(
              figure: SilhouetteFigure.priya,
              grade: grade,
              tight: tight,
            ),
          ),
        ),
        ?overlay,
      ],
    );
  }
}

/// A caption above a component in the catalog, on the sky: "SELECTED".
class CatalogCaption extends StatelessWidget {
  const CatalogCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BrandSpace.md, bottom: BrandSpace.xs),
    child: Text(text.toUpperCase(), style: BrandVividType.kicker),
  );
}

/// Components on the evening sky (the vivid layer), centred, scrolling only at 2x.
class CatalogSky extends StatelessWidget {
  const CatalogSky({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const VividBackdrop(lights: false),
      SafeArea(
        child: AnchoredScroll(
          alignment: MainAxisAlignment.center,
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.md,
            CatalogDesk.controlsClearance,
            BrandSpace.md,
            BrandSpace.lg,
          ),
          children: children,
        ),
      ),
    ],
  );
}
