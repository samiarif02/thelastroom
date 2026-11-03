import 'dart:ui' show ImageFilter;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';

/// One tab: a Phosphor glyph, its label, and an optional count badge.
@immutable
class TabItem {
  const TabItem({
    required this.icon,
    required this.label,
    this.badge,
    this.anchor,
  });

  final IconData icon;
  final String label;

  /// On the tab, so a first-time tip can find it on screen.
  final Key? anchor;

  /// A count in a recall-coloured badge (Recall notes due); null or 0 shows none.
  final int? badge;
}

/// The bottom navigation (direction.md, "Home"): floating 16 off the edges, white at 86% over a
/// blur, lifted. The current tab is an ink tile with white text; the rest are ink-2. Each tab is
/// a 48+ target, a selected tab to screen readers.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.items,
    required this.current,
    required this.onSelect,
  });

  final List<TabItem> items;
  final int current;
  final ValueChanged<int> onSelect;

  static const double height = 64;
  static const double _blur = 16;
  static const double _glass = 0.86;
  static const double _iconSize = 22;
  static const double _badge = 16;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DaylightRadius.panel),
      boxShadow: DaylightElevation.lift,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(DaylightRadius.panel),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: Container(
          constraints: const BoxConstraints(minHeight: height),
          padding: const EdgeInsets.all(DaylightSpace.s8),
          color: DaylightColors.raised.withValues(alpha: _glass),
          child: Row(
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const SizedBox(width: DaylightSpace.s4),
                Expanded(
                  child: KeyedSubtree(key: item.anchor, child: _tab(i, item)),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _tab(int i, TabItem item) {
    final on = i == current;
    final ink = on ? DaylightColors.raised : DaylightColors.ink2;
    final badge = item.badge ?? 0;
    return Semantics(
      button: true,
      selected: on,
      label: badge > 0 ? '${item.label}, $badge waiting' : item.label,
      excludeSemantics: true,
      onTap: () => onSelect(i),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!on) pressTap();
          onSelect(i);
        },
        child: AnimatedContainer(
          duration: DaylightMotion.colour,
          curve: DaylightMotion.ease,
          constraints: const BoxConstraints(minHeight: DaylightSize.hit),
          decoration: BoxDecoration(
            color: on
                ? DaylightColors.ink
                : DaylightColors.raised.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(DaylightRadius.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: _iconSize, color: ink),
                  if (badge > 0)
                    Positioned(
                      right: -_badge + DaylightSpace.s4,
                      top: -DaylightSpace.s4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: _badge,
                          minHeight: _badge,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DaylightSpace.s4,
                        ),
                        decoration: BoxDecoration(
                          color: DaylightColors.recall,
                          borderRadius: BorderRadius.circular(DaylightSpace.s4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badge',
                          style: DaylightType.tabular(DaylightType.caption3)
                              .copyWith(color: DaylightColors.raised),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DaylightType.caption4.copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
