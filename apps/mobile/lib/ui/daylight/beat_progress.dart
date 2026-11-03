import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';
import 'progress_track.dart';

/// Where the player is in a room (direction.md, "Answer cards"): one labelled segment per beat
/// ("Open", "Evidence", "Land"). Done beats are full in the floor's colour, the current one
/// fills to [progress], the rest are white. The current label is the only one in ink.
class BeatProgress extends StatelessWidget {
  const BeatProgress({
    super.key,
    required this.beats,
    required this.current,
    this.progress = 0,
    this.floor,
  });

  final List<String> beats;

  /// The current beat's index; `beats.length` when every beat is done.
  final int current;

  /// How far through the current beat (0…1).
  final double progress;
  final FloorColours? floor;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    return Semantics(
      label: current < beats.length
          ? 'Beat ${current + 1} of ${beats.length}: ${beats[current]}'
          : 'All ${beats.length} beats done',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, beat) in beats.indexed) ...[
            if (i > 0) const SizedBox(width: DaylightSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressTrack(
                    value: i < current ? 1 : (i == current ? progress : 0),
                    fill: f.base,
                    track: DaylightColors.raised,
                    animate: false,
                  ),
                  const SizedBox(height: DaylightSpace.s4),
                  Text(
                    beat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: i == current
                        ? DaylightType.caption3.copyWith(
                            color: DaylightColors.ink,
                          )
                        : DaylightType.caption4.copyWith(
                            color: DaylightColors.ink2,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
