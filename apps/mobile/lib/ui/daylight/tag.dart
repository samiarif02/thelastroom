import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A tag's colours: its ground and its text. Every pair is AA (`daylight_contrast_test`).
@immutable
class TagTone {
  const TagTone(this.ground, this.ink);

  /// Quiet metadata on paper ("Interview in 9 days").
  static const TagTone sand = TagTone(DaylightColors.sand, DaylightColors.ink2);

  /// XP on paper.
  static const TagTone honey = TagTone(
    DaylightColors.honeyTint,
    DaylightColors.honeyInk,
  );

  /// XP as a reward ("+40 XP" in the debrief).
  static const TagTone honeySolid = TagTone(
    DaylightColors.honey,
    DaylightColors.onHoney,
  );

  /// On white or paper, in the floor's voice ("+14 since room 1").
  static TagTone floor(FloorColours f) => TagTone(f.tint, f.deep);

  /// On a floor's own colour ("5 min" on the up-next card): white on 14% white.
  static TagTone onFloor(FloorColours f) => TagTone(
    Color.alphaBlend(DaylightColors.raised.withValues(alpha: 0.14), f.base),
    DaylightColors.raised,
  );

  static const TagTone recall = TagTone(
    DaylightColors.recallTint,
    DaylightColors.recall,
  );

  static const TagTone trap = TagTone(
    DaylightColors.trapTint,
    DaylightColors.trap,
  );

  /// On a room's photo-like stage ("Recording"): white, ink.
  static const TagTone raised = TagTone(
    DaylightColors.raised,
    DaylightColors.ink,
  );

  final Color ground;
  final Color ink;
}

/// A squared tag (radius 6, never a pill): 24 tall, Caption 3, an optional Phosphor glyph and
/// an optional [dot] (the clay "Recording" dot). Numbers in it are tabular.
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    this.icon,
    this.tone = TagTone.sand,
    this.dot,
  });

  final String label;
  final IconData? icon;
  final TagTone tone;
  final Color? dot;

  static const double _iconSize = 14;
  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: DaylightSize.tag),
    padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s8),
    decoration: BoxDecoration(
      color: tone.ground,
      borderRadius: BorderRadius.circular(DaylightRadius.tag),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot case final dot?) ...[
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: DaylightSpace.s4),
        ],
        if (icon != null) ...[
          Icon(icon, size: _iconSize, color: tone.ink),
          const SizedBox(width: DaylightSpace.s4),
        ],
        Flexible(
          child: Text(
            label,
            style: DaylightType.tabular(DaylightType.caption3)
                .copyWith(color: tone.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
