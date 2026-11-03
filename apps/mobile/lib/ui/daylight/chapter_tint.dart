import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// Sets the floor's colours (base, deep, tint, soft, on) for a subtree: every Daylight widget
/// below that takes a floor reads it from here unless it's given one. Floor 1 when there's
/// none above.
class ChapterTint extends InheritedWidget {
  const ChapterTint({super.key, required this.floor, required super.child});

  /// The tint for a chapter.
  ChapterTint.of(ChapterGrade grade, {super.key, required super.child})
    : floor = grade.floor;

  final FloorColours floor;

  /// The nearest floor above [context], or floor 1.
  static FloorColours floorOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChapterTint>()?.floor ??
      DaylightFloors.one;

  @override
  bool updateShouldNotify(ChapterTint oldWidget) => floor != oldWidget.floor;
}
