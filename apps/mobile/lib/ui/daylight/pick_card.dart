import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';
import 'tactile.dart';

/// Where a [PickCard] is in the pick.
enum PickState {
  /// Waiting to be picked.
  idle,

  /// Picked, not locked in yet: the floor's ring, lifted 2.
  selected,

  /// Another card is picked.
  dimmed,

  /// Locked in: selected, with a check, no longer tappable.
  locked,
}

/// An answer or a reason to pick (direction.md's `AnswerCard`; named so it can't clash with the
/// film kit's): a white card on a hard edge, a letter tile (A, B, C) or a Phosphor [icon] tile,
/// and the line in Body 3 (never under 16). Idle, pressed (it sinks), selected, dimmed and
/// locked.
class PickCard extends StatelessWidget {
  const PickCard({
    super.key,
    required this.text,
    this.letter,
    this.icon,
    this.lockedIcon,
    this.state = PickState.idle,
    this.onTap,
    this.floor,
    this.pressed,
  }) : assert(letter != null || icon != null, 'A letter or an icon');

  final String text;

  /// "A", "B", "C".
  final String? letter;

  /// A principle's glyph, for the reason cards.
  final IconData? icon;

  /// The check shown in the tile once locked in; the letter stays if null.
  final IconData? lockedIcon;
  final PickState state;
  final VoidCallback? onTap;
  final FloorColours? floor;
  final bool? pressed;

  static const double _dimmed = 0.55;
  static const double _lift = 2;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final on = state == PickState.selected || state == PickState.locked;
    final tileGround = on ? f.base : DaylightColors.sand;
    final tileInk = on ? DaylightColors.raised : DaylightColors.ink2;
    final tileGlyph = state == PickState.locked ? lockedIcon ?? icon : icon;
    final tile = Container(
      width: DaylightSize.letter,
      height: DaylightSize.letter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tileGround,
        borderRadius: BorderRadius.circular(DaylightRadius.inner),
      ),
      child: tileGlyph != null && (letter == null || state == PickState.locked)
          ? Icon(tileGlyph, size: _iconSize, color: tileInk)
          : Text(
              letter ?? '',
              style: DaylightType.body4.copyWith(color: tileInk),
            ),
    );
    final card = Tactile(
      label: letter == null ? text : 'Line $letter: $text',
      selected: on,
      onTap: state == PickState.locked ? null : onTap,
      pressed: pressed,
      lift: on ? _lift : 0,
      style: TactileStyle(
        face: on
            ? Color.alphaBlend(
                f.tint.withValues(alpha: 0.4),
                DaylightColors.raised,
              )
            : DaylightColors.raised,
        edge: on ? f.deep : DaylightColors.sand2,
        ring: on ? f.base : null,
        radius: BorderRadius.circular(DaylightRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tile,
            const SizedBox(width: DaylightSpace.s12),
            Expanded(child: Text(text, style: DaylightType.body3)),
          ],
        ),
      ),
    );
    return AnimatedOpacity(
      opacity: state == PickState.dimmed ? _dimmed : 1,
      duration: DaylightMotion.colour,
      curve: DaylightMotion.ease,
      child: SizedBox(width: double.infinity, child: card),
    );
  }
}
