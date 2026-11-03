import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'icon_tile.dart';

/// A Daylight screen's top bar (mockups `02`, `04`, `07`: `.bar`): the close or back tile, then
/// either a [middle] (the mission's beat progress) or a small [kicker] over a [title], then an
/// optional [trailing] (trust pips, the "Out loud" tag, the Leitner boxes). 48 tall, the
/// phone gutter at the sides, 12 between.
class DaylightTopBar extends StatelessWidget {
  const DaylightTopBar({
    super.key,
    required this.onLeading,
    required this.leadingLabel,
    this.leadingIcon = PhosphorBold.x,
    this.kicker,
    this.title,
    this.middle,
    this.trailing,
  });

  final VoidCallback? onLeading;
  final String leadingLabel;
  final IconData leadingIcon;

  /// "Floor 2 · room 11" (Caption 4, ink-2).
  final String? kicker;

  /// "Tight deadline" (Body 1).
  final String? title;

  /// Instead of the kicker and title.
  final Widget? middle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final kick = kicker;
    final head = title;
    final centre =
        middle ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kick != null)
              Text(
                kick,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DaylightType.caption4.copyWith(
                  color: DaylightColors.ink2,
                ),
              ),
            if (head != null)
              Semantics(
                header: true,
                child: Text(
                  head,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DaylightType.body1,
                ),
              ),
          ],
        );
    final end = trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DaylightSpace.s16,
        DaylightSpace.s4,
        DaylightSpace.s16,
        0,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: DaylightSize.hit),
        child: Row(
          children: [
            IconTile(
              icon: leadingIcon,
              semanticLabel: leadingLabel,
              onPressed: onLeading,
            ),
            SizedBox(
              width: middle == null ? DaylightSpace.s12 : DaylightSpace.s8,
            ),
            Expanded(child: centre),
            if (end != null) ...[const SizedBox(width: DaylightSpace.s8), end],
          ],
        ),
      ),
    );
  }
}
