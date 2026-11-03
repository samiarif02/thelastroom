import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';
import 'tactile.dart';

/// What a [TactileButton] is for.
enum TactileTone {
  /// The one action accent: "Start room 4", "Lock in line B", "Light room 4".
  honey,

  /// The welcome-back card's button, so it never competes with the honey up-next button.
  recall,

  /// A second action beside or below the honey one ("Send a test reminder", "Not now"): sand
  /// with the sand-2 edge, ink text, on paper or inside a white card. Never the main action.
  quiet,

  /// The honey button on a saturated floor (the reward), the same face with the floor's deep
  /// edge read from [ChapterTint].
  floor,
}

/// The primary action (direction.md, "Shared kit"): honey, 56 tall, a hard edge below, and it
/// sinks onto that edge when pressed. Label is a verb plus an outcome, sentence case, no
/// exclamation mark. [compact] is the in-card size (48, radius 8 by the nested rule). Null
/// [onPressed] is disabled: sand, no edge, ink-2 text ("Lock in line B" before a pick).
class TactileButton extends StatelessWidget {
  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = TactileTone.honey,
    this.compact = false,
    this.expand = true,
    this.pressed,
  });

  final String label;
  final VoidCallback? onPressed;

  /// A Phosphor glyph before the label.
  final IconData? icon;
  final TactileTone tone;
  final bool compact;

  /// Full width (the default), or as wide as its label.
  final bool expand;

  /// Forces the pressed look, for the catalog.
  final bool? pressed;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (face, edge, ink) = !enabled
        ? (DaylightColors.sand, DaylightColors.sand2, DaylightColors.ink2)
        : switch (tone) {
            TactileTone.honey => (
              DaylightColors.honey,
              DaylightColors.honeyEdge,
              DaylightColors.onHoney,
            ),
            TactileTone.recall => (
              DaylightColors.recall,
              DaylightColors.recallDeep,
              DaylightColors.raised,
            ),
            TactileTone.quiet => (
              DaylightColors.sand,
              DaylightColors.sand2,
              DaylightColors.ink,
            ),
            TactileTone.floor => (
              DaylightColors.honey,
              ChapterTint.floorOf(context).deep,
              DaylightColors.onHoney,
            ),
          };
    final text = compact ? DaylightType.buttonMedium : DaylightType.buttonLarge;
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _iconSize, color: ink),
          const SizedBox(width: DaylightSpace.s8),
        ],
        Flexible(
          child: Text(
            label,
            style: text.copyWith(color: ink),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return Tactile(
      label: label,
      onTap: onPressed,
      pressed: pressed,
      style: TactileStyle(
        face: face,
        edge: edge,
        radius: BorderRadius.circular(
          compact ? DaylightRadius.inner : DaylightRadius.card,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: compact ? DaylightSize.buttonCompact : DaylightSize.button,
          minWidth: expand ? double.infinity : 0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DaylightSpace.s24,
            vertical: DaylightSpace.s8,
          ),
          child: Center(widthFactor: expand ? null : 1, child: row),
        ),
      ),
    );
  }
}
