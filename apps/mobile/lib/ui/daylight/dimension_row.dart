import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';
import 'progress_track.dart';

/// One of the debrief's four dimensions (direction.md, "Debrief"): the name (Title 4), the
/// score (Body 4, tabular), a bar, and the basis line that explains the number (Caption 4,
/// ink-2). The [weakest] is drawn in trap clay, never alarm red.
class DimensionRow extends StatelessWidget {
  const DimensionRow({
    super.key,
    required this.name,
    required this.score,
    required this.basis,
    this.max = 100,
    this.weakest = false,
    this.floor,
    this.delay = Duration.zero,
  });

  final String name;
  final int score;
  final String basis;
  final int max;
  final bool weakest;
  final FloorColours? floor;

  /// When the bar starts filling (the four fill 80 ms apart).
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final colour = weakest ? DaylightColors.trap : f.base;
    return Semantics(
      label: '$name, $score of $max. $basis',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(name, style: DaylightType.title4)),
              Text(
                '$score',
                style: DaylightType.tabular(DaylightType.body4).copyWith(
                  color: weakest ? DaylightColors.trap : DaylightColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s4),
          ProgressTrack(value: score / max, fill: colour, delay: delay),
          const SizedBox(height: DaylightSpace.s4),
          Text(
            basis,
            style: DaylightType.caption4.copyWith(color: DaylightColors.ink2),
          ),
        ],
      ),
    );
  }
}
