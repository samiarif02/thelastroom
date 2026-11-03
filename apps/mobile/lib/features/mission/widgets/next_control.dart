import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

/// "Next →" in the dock under a typed interviewer line (owner's first play, 2026-10-30: the old
/// arrow was too small). A labelled Daylight button [height] tall. While the line
/// auto-advances, a bar in the floor's colour drains along its foot and the seconds left show
/// beside the label; once a touch has paused it, it says so.
class NextControl extends StatelessWidget {
  const NextControl({
    super.key,
    required this.onPressed,
    this.remaining,
    this.secondsLeft,
    this.paused = false,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onPressed;

  /// The countdown's share still to run, 1 → 0; null when the line doesn't auto-advance.
  final double? remaining;

  /// Whole seconds left on the countdown, shown beside the label.
  final int? secondsLeft;
  final bool paused;
  final ChapterGrade grade;

  static const String label = 'Next';
  static const String pausedLabel = 'Paused';

  /// Taller than the 44 dp floor: it's the control a player taps most (brief 13: ≥ 48 dp).
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final f = grade.floor;
    final seconds = secondsLeft;
    final caption = [
      label,
      if (paused) '·  $pausedLabel',
      if (!paused && seconds != null) '·  $seconds',
    ].join('  ');
    final semantics = paused
        ? '$label, auto-advance paused'
        : seconds == null
        ? label
        : '$label, moving on in $seconds seconds';
    final still = MediaQuery.disableAnimationsOf(context);
    // The quiet dock button: sand, the line's countdown draining along its foot in the floor's
    // colour. A tap anywhere on it moves on.
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tactile(
        label: semantics,
        onTap: onPressed,
        style: TactileStyle(
          face: DaylightColors.raised,
          edge: DaylightColors.sand2,
          radius: BorderRadius.circular(DaylightRadius.card),
        ),
        child: SizedBox(
          height: height - DaylightSize.edge,
          width: double.infinity,
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DaylightType.tabular(DaylightType.buttonMedium),
                      ),
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    const Icon(
                      PhosphorBold.arrowRight,
                      size: _arrow,
                      color: DaylightColors.ink,
                    ),
                  ],
                ),
              ),
              if (remaining case final left?)
                Positioned(
                  left: DaylightSpace.s16,
                  right: DaylightSpace.s16,
                  bottom: DaylightSpace.s8,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: still ? 1 : left,
                      child: SizedBox(
                        height: _bar,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: paused ? f.soft : f.base,
                            borderRadius: BorderRadius.circular(_bar),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _bar = 3;
  static const double _arrow = 18;
}
