import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'catalog_backdrops.dart';

/// A Daylight shot's ground: flat [ground] (paper by default) with the grain, the content in
/// the phone gutter under the catalog's controls, scrolling only when the text is doubled.
class CatalogPaper extends StatelessWidget {
  const CatalogPaper({
    super.key,
    required this.children,
    this.ground = DaylightColors.paper,
    this.floor = DaylightFloors.one,
    this.gap = DaylightSpace.s16,
    this.bottom,
  });

  final List<Widget> children;
  final Color ground;
  final FloorColours floor;
  final double gap;

  /// Pinned to the bottom edge (a sheet, the tab bar).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final pinned = bottom;
    return ChapterTint(
      floor: floor,
      child: DefaultTextStyle(
        style: DaylightType.body3,
        child: ColoredBox(
          color: ground,
          child: Grain(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      DaylightSpace.gutter,
                      CatalogDesk.controlsClearance,
                      DaylightSpace.gutter,
                      DaylightSpace.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, c) in children.indexed) ...[
                          if (i > 0) SizedBox(height: gap),
                          c,
                        ],
                      ],
                    ),
                  ),
                ),
                if (pinned != null)
                  Positioned(left: 0, right: 0, bottom: 0, child: pinned),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A kicker over a group of states in a shot.
class CatalogLabel extends StatelessWidget {
  const CatalogLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: DaylightType.caption3.copyWith(color: DaylightColors.ink2),
  );
}
