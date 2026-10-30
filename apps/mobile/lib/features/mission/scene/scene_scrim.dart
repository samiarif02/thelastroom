import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// Darkens the top of the frame (under the status bar and the trust meter) and the lower third
/// (under the subtitles and cards), so text over the room keeps AA contrast. The lower scrim
/// starts at [from], the top of the lower third, which is already below the face: it never
/// darkens the interviewer.
class SceneScrim extends StatelessWidget {
  const SceneScrim({super.key, required this.from});

  /// Where the lower third starts, as a share of the frame's height.
  final double from;

  static const double _topReach = 0.1;
  static const double _topAlpha = 0.6;

  /// How far above the lower third the fade begins, as a share of the height.
  static const double _lead = 0.04;
  static const double _fullBy = 0.12;
  static const double _lowerAlpha = 0.9;
  static const double _bottomAlpha = 0.96;

  @override
  Widget build(BuildContext context) {
    final begin = (from - _lead).clamp(_topReach, 1.0);
    final full = (from + _fullBy).clamp(begin, 1.0);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BrandColors.void_.withValues(alpha: _topAlpha),
              BrandColors.void_.withValues(alpha: 0),
              BrandColors.void_.withValues(alpha: 0),
              BrandColors.void_.withValues(alpha: _lowerAlpha),
              BrandColors.void_.withValues(alpha: _bottomAlpha),
            ],
            stops: [0, _topReach, begin, full, 1],
          ),
        ),
      ),
    );
  }
}
