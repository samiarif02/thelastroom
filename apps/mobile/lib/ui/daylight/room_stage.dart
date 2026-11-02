import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../figure/cast_figure.dart';
import 'chapter_tint.dart';

/// The room (direction.md, "Answer cards"): a flat office in the floor's soft colour, with an
/// arched window on the city, a plant, the desk, and the interviewer in the middle, looking at
/// you. [height] is 168 on a phone; at large text the screen collapses it to a 96 strip, and the
/// figure scales with it. [overlays] sit on top ("Recording", "Listening" tags).
class RoomStage extends StatelessWidget {
  const RoomStage({
    super.key,
    required this.person,
    this.expression = CastExpression.listening,
    this.floor,
    this.height = defaultHeight,
    this.overlays = const [],
    this.semanticLabel,
  });

  final CastPerson person;
  final CastExpression expression;
  final FloorColours? floor;
  final double height;
  final List<Widget> overlays;

  /// What a screen reader hears ("Marcus listens").
  final String? semanticLabel;

  static const double defaultHeight = 168;

  /// The collapsed strip at large text sizes.
  static const double compactHeight = 96;

  static const double _desk = 24;
  static const double _deskTop = 8;
  static const double _glassBorder = 6;

  /// The far city's blocks in the window: left, width, height (the mockup's skyline).
  static const List<(double, double, double)> _city = [
    (4, 22, 36),
    (30, 28, 58),
    (62, 18, 30),
    (84, 30, 48),
    (118, 26, 34),
    (148, 24, 62),
    (176, 30, 40),
  ];

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    // Everything is drawn for a 168 room and scaled with it.
    final k = height / defaultHeight;
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DaylightRadius.panel),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: f.soft,
            child: Stack(
              children: [
                Positioned(
                  left: DaylightSpace.s24 * k,
                  right: 120 * k,
                  top: DaylightSpace.s16 * k,
                  height: 104 * k,
                  child: _Glass(scale: k),
                ),
                Positioned(
                  right: DaylightSpace.s24 * k,
                  bottom: DaylightSpace.s24 * k,
                  width: 56 * k,
                  height: 96 * k,
                  child: _Plant(floor: f, scale: k),
                ),
                Positioned(
                  bottom: DaylightSpace.s16 * k,
                  left: 0,
                  right: 0,
                  height: height,
                  child: Align(
                    alignment: const Alignment(0.08, 1),
                    child: SizedBox.square(
                      dimension: height,
                      child: ExcludeSemantics(
                        child: CastFigure(
                          person: person,
                          expression: expression,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _desk * k,
                  child: Column(
                    children: [
                      Container(
                        height: _deskTop * k,
                        color: DaylightColors.deskTop,
                      ),
                      const Expanded(
                        child: ColoredBox(color: DaylightColors.desk),
                      ),
                    ],
                  ),
                ),
                for (final o in overlays) o,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(
      top: Radius.circular(DaylightRadius.archTop),
      bottom: Radius.circular(DaylightRadius.inner),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.sky,
        borderRadius: radius,
        border: Border.all(
          color: DaylightColors.raised,
          width: RoomStage._glassBorder * scale,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            for (final (i, (left, width, h)) in RoomStage._city.indexed)
              Positioned(
                left: left * scale,
                bottom: 0,
                width: width * scale,
                height: h * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i.isEven
                        ? DaylightColors.cityFar
                        : DaylightColors.skyCloud,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(DaylightSpace.s2 * scale),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A potted plant: three leaves in the floor's colours over a honey pot.
class _Plant extends StatelessWidget {
  const _Plant({required this.floor, required this.scale});

  final FloorColours floor;
  final double scale;

  /// Each leaf: its left, height, turn (degrees) and whether it's the lighter one.
  static const List<(double, double, double, bool)> _leaves = [
    (10, 56, -24, false),
    (18, 68, 4, true),
    (26, 56, 30, false),
  ];

  @override
  Widget build(BuildContext context) {
    final k = scale;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (left, h, turn, light) in _leaves)
          Positioned(
            left: left * k,
            bottom: 28 * k,
            width: 20 * k,
            height: h * k,
            child: Transform.rotate(
              angle: turn * math.pi / 180,
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: light ? floor.base : floor.deep,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DaylightRadius.archTop),
                    bottomRight: Radius.circular(DaylightRadius.archTop),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: DaylightSpace.s12 * k,
          bottom: 0,
          width: DaylightSpace.s32 * k,
          height: DaylightSpace.s32 * k,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DaylightColors.honey,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(DaylightSpace.s4 * k),
                bottom: Radius.circular(DaylightRadius.tile * k),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
