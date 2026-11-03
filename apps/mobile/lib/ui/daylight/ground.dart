import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';

/// A Daylight screen's ground (direction.md, "Screen by screen"): one flat colour edge to edge
/// (paper, a floor's tint, the Recall tint, or a floor's base for the reward), the floor's
/// colours for everything below, the reading style as the default, and the status and
/// navigation bar icons dark on a light ground (light on [dark] ones).
class DaylightGround extends StatelessWidget {
  const DaylightGround({
    super.key,
    required this.child,
    this.color = DaylightColors.paper,
    this.floor,
    this.dark = false,
  });

  final Widget child;
  final Color color;

  /// The floor every kit widget below reads; floor 1 by default.
  final FloorColours? floor;

  /// A dark or saturated ground (the reward's floor colour): light bar icons.
  final bool dark;

  /// Transparent bars, dark icons over a light ground.
  static const SystemUiOverlayStyle lightGround = SystemUiOverlayStyle(
    statusBarColor: BrandColors.clear,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: BrandColors.clear,
    systemNavigationBarDividerColor: BrandColors.clear,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  /// Transparent bars, light icons over a saturated ground.
  static const SystemUiOverlayStyle darkGround = SystemUiOverlayStyle(
    statusBarColor: BrandColors.clear,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: BrandColors.clear,
    systemNavigationBarDividerColor: BrandColors.clear,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) {
    final f = floor;
    Widget body = DefaultTextStyle(
      style: DaylightType.body3,
      child: ColoredBox(color: color, child: child),
    );
    if (f != null) body = ChapterTint(floor: f, child: body);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? darkGround : lightGround,
      child: body,
    );
  }
}
