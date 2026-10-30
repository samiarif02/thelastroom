import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// "NEXT ›" under a typed interviewer line (owner's first play, 2026-10-30: the old arrow was too
/// small). A labelled control at least [height] tall. While the line auto-advances, a brass
/// hairline drains under the label and the seconds left show beside it; once a touch has
/// paused it, it says so.
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
  // In the UI font (Manrope has no ▸).
  static const String glyph = '›';

  /// Taller than the 44 dp floor: it's the control a player taps most (brief 13: ≥ 48 dp).
  static const double height = 56;
  static const double _hairline = 1.2;

  @override
  Widget build(BuildContext context) {
    final brass = grade.key;
    final seconds = secondsLeft;
    final caption = [
      label.toUpperCase(),
      glyph,
      if (paused) '·  ${pausedLabel.toUpperCase()}',
      if (!paused && seconds != null) '·  $seconds',
    ].join('  ');
    final semantics = paused
        ? '$label, auto-advance paused'
        : seconds == null
        ? label
        : '$label, moving on in $seconds seconds';
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                caption,
                textAlign: TextAlign.center,
                style: BrandType.eyebrow.copyWith(color: brass),
              ),
              const SizedBox(height: BrandSpace.xs),
              FractionallySizedBox(
                widthFactor: _barWidth,
                child: Align(
                  child: FractionallySizedBox(
                    widthFactor: remaining ?? 1,
                    child: SizedBox(
                      height: _hairline,
                      child: ColoredBox(
                        color: brass.withValues(
                          alpha: remaining == null || paused ? 0.35 : 0.9,
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

  static const double _barWidth = 0.4;
}
