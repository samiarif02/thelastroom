import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../light/bokeh.dart';

/// The vivid screens' ground (brief 17): the evening sky, full bleed, deep navy at the top to
/// teal over the city, with a warm horizon glow at the bottom and the city's lights out of
/// focus. [grade] tints the glow toward a chapter (onboarding's steps, progress). Never white.
class VividBackdrop extends StatelessWidget {
  const VividBackdrop({super.key, this.grade, this.lights = true});

  /// Null: the plain evening sky (the tower).
  final ChapterGrade? grade;

  /// The city's lights, drifting out of focus. Off for small screens and goldens.
  final bool lights;

  static const double _horizonReach = 0.55;
  static const double _gradeAlpha = 0.55;
  static const double _horizonAlpha = 0.45;
  static const double _lightsOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final g = grade;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: BrandVivid.sky,
            ),
          ),
        ),
        // The chapter's colour washing in from the top corner.
        if (g != null)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -1.1),
                radius: 1.3,
                colors: [
                  g.deep.withValues(alpha: _gradeAlpha),
                  g.deep.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        // The sun just below the horizon.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.3, 1.5),
              radius: _horizonReach * 2,
              colors: [
                BrandVivid.horizon.withValues(alpha: _horizonAlpha),
                BrandVivid.horizon.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        if (lights)
          Opacity(
            opacity: _lightsOpacity,
            child: Bokeh(
              colors: [
                BrandVivid.accent,
                g?.glow ?? ChapterGrade.lobby.glow,
                BrandVivid.onDeep,
              ],
              count: 18,
              seed: 17,
            ),
          ),
      ],
    );
  }
}
