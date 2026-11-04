import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../../ui/film/cue.dart';
import '../../ui/film/timeline.dart';
import '../tower/tower_door.dart';

/// The app's title in Daylight (brief 20; brief 48): Northstar tower against the day sky, its
/// rooms' doors (the tower's own) lighting honey floor by floor from the street up, the top floor
/// at dusk until Sam's door lights last. Then the name (Bricolage, sentence case), the line, and the four
/// interviewers arriving in their arches, smiling, 120 ms apart. About [length] long; under
/// reduced motion it shows its last frame at once. [onLanded] fires when it has settled. Not
/// interactive: the screen around it decides what a tap does.
class DaylightTitle extends StatelessWidget {
  const DaylightTitle({super.key, this.onLanded, this.footer});

  final VoidCallback? onLanded;

  /// Below the cast once it has landed: "Step inside" on the first launch.
  final Widget? footer;

  static const String title = 'The Last Room';
  static const String tagline = 'One room left between you and the offer.';

  /// The whole title, from the first window to the cast settled.
  static const Duration length = Duration(milliseconds: 1600);

  // The cue sheet, as shares of [length].
  static const double _lightsTo = 0.62;
  static const double _nameFrom = 0.4;
  static const double _nameTo = 0.75;
  static const double _castFrom = 0.55;
  static const double _castStep = 0.075;
  static const double _castSpan = 0.25;
  static const double _footFrom = 0.85;
  static const double _skyShare = 0.44;
  static const double _arch = 64;
  static const double _archHeight = 80;
  static const double _castRise = 12;

  /// Each interviewer's arch, in the floor they host (Sam at dusk, on top).
  static const List<CastPerson> _cast = [
    CastPeople.priya,
    CastPeople.marcus,
    CastPeople.lena,
    CastPeople.sam,
  ];

  static Color _archGround(int i) => switch (i) {
    0 => DaylightFloors.one.soft,
    1 => DaylightFloors.two.soft,
    2 => DaylightFloors.three.soft,
    _ => DaylightColors.honeyTint,
  };

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return DaylightGround(
      child: Timeline(
        duration: still ? Duration.zero : length,
        onFinished: onLanded,
        builder: (context, t, _) {
          final at = still ? 1.0 : t;
          final lights = cue(at, 0, _lightsTo, DaylightMotion.ease);
          final name = cue(at, _nameFrom, _nameTo, DaylightMotion.ease);
          final foot = cue(at, _footFrom, 1, DaylightMotion.ease);
          return LayoutBuilder(
            // Fills the frame, and scrolls only when large text makes it taller.
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: box.maxHeight * _skyShare,
                        child: ExcludeSemantics(child: TitleTower(lit: lights)),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      Opacity(
                        opacity: name,
                        child: Transform.translate(
                          offset: Offset(0, DaylightSpace.s16 * (1 - name)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DaylightSpace.s24,
                            ),
                            child: Column(
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: DaylightType.heading3,
                                  ),
                                ),
                                const SizedBox(height: DaylightSpace.s8),
                                Text(
                                  tagline,
                                  textAlign: TextAlign.center,
                                  style: DaylightType.body3.copyWith(
                                    color: DaylightColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DaylightSpace.s24),
                      ExcludeSemantics(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: DaylightSpace.s12,
                          runSpacing: DaylightSpace.s12,
                          children: [
                            for (final (i, person) in _cast.indexed)
                              Builder(
                                builder: (context) {
                                  final from = _castFrom + _castStep * i;
                                  final c = cue(
                                    at,
                                    from,
                                    math.min(1, from + _castSpan),
                                    DaylightMotion.ease,
                                  );
                                  return Opacity(
                                    opacity: c,
                                    child: Transform.translate(
                                      offset: Offset(0, _castRise * (1 - c)),
                                      child: ArchPortrait(
                                        person: person,
                                        expression: CastExpression.smile,
                                        width: _arch,
                                        height: _archHeight,
                                        ground: _archGround(i),
                                        idle: false,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: DaylightSpace.s24),
                      if (footer case final f?)
                        Opacity(
                          opacity: foot,
                          child: IgnorePointer(ignoring: foot < 1, child: f),
                        ),
                      SizedBox(
                        height:
                            DaylightSpace.s32 +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Northstar tower on the title: the day sky, the building ([TitleTowerPainter]) and its 21
/// doors, drawn by [TowerDoor] in the tower's own [DoorInk], so the title shows the rooms the
/// player will tap. [lit] (0 → 1) lights them honey one after another from the street up, floor
/// 1 left to right, then floor 2, then Sam's door at the top right with Sam in it. The top floor's
/// other doors stay dusk: they're still to come.
class TitleTower extends StatelessWidget {
  const TitleTower({super.key, required this.lit});

  final double lit;

  /// Floor 1 and floor 2 light (14 doors), then Sam's.
  static const int lighting = TitleTowerPainter.across * 2 + 1;

  /// How far along door [order] is in lighting up, at [lit].
  static double doorLighting(int order, double lit) =>
      (lit.clamp(0.0, 1.0) * lighting - order).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final layout = TitleTowerLayout.of(box.biggest);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: TitleTowerPainter()),
          ),
          for (final door in layout.doors)
            Positioned(
              left: door.at.dx,
              top: door.at.dy,
              child: _door(door, layout.doorWidth),
            ),
        ],
      );
    },
  );

  Widget _door(TitleDoor door, double width) {
    final order = door.order;
    final t = order == null ? 0.0 : doorLighting(order, lit);
    final (leaf, panel, frame) = switch (door.floor) {
      0 => switch (DoorInk.open(DaylightFloors.one)) {
        (:final leaf, :final panel, :final frame) => (leaf, panel, frame),
      },
      1 => switch (DoorInk.open(DaylightFloors.two)) {
        (:final leaf, :final panel, :final frame) => (leaf, panel, frame),
      },
      _ => (DoorInk.dusk.leaf, DoorInk.dusk.panel, DoorInk.dusk.frame),
    };
    return TowerDoor(
      state: order == null
          ? DoorState.closed
          : door.sam
          ? DoorState.waiting
          : DoorState.lit,
      width: width,
      leaf: leaf,
      panel: panel,
      frame: frame,
      lighting: t,
    );
  }
}

/// One door on the title's tower: its top-left corner, its floor (0 is the street floor), and
/// its place in the lighting order (null for the top floor's doors that stay dusk).
typedef TitleDoor = ({Offset at, int floor, int? order, bool sam});

/// Where the title's tower and its doors go in a frame of a given size. The painter and the
/// doors read the same numbers, so the doors always stand on their floors.
class TitleTowerLayout {
  TitleTowerLayout._({
    required this.left,
    required this.bodyWidth,
    required this.floorsTop,
    required this.floorHeight,
    required this.roofHeight,
    required this.street,
    required this.doorWidth,
    required this.doors,
  });

  factory TitleTowerLayout.of(Size size) {
    final w = size.width;
    final h = size.height;
    final street = h * _streetShare;
    final bodyW = math.min(w * _bodyShare, h * 1.1);
    final left = (w - bodyW) / 2;
    final floorsTop = h * _floorsShare;
    final floorH = (h - street - floorsTop) / _floors;
    final cell = bodyW / TitleTowerPainter.across;
    // As wide as a seventh of the facade allows, and short enough to stand on its floor; whole
    // logical pixels, so the doors' edges stay crisp.
    final doorW = math
        .min(cell * (1 - _gapShare), floorH * _doorShare / TowerDoor.aspect)
        .floorToDouble();
    final doorH = doorW * TowerDoor.aspect;
    const across = TitleTowerPainter.across;
    final doors = <TitleDoor>[
      for (var row = 0; row < _floors; row++)
        for (var i = 0; i < across; i++)
          (
            at: Offset(
              (left + cell * i + (cell - doorW) / 2).roundToDouble(),
              (floorsTop + floorH * (row + 1) - floorH * _sillShare - doorH)
                  .roundToDouble(),
            ),
            floor: _floors - 1 - row,
            // Floor 1 left to right, floor 2, then Sam's: the top floor's last door.
            order: switch (_floors - 1 - row) {
              0 => i,
              1 => across + i,
              _ => i == across - 1 ? across * 2 : null,
            },
            sam: row == 0 && i == across - 1,
          ),
    ];
    return TitleTowerLayout._(
      left: left,
      bodyWidth: bodyW,
      floorsTop: floorsTop,
      floorHeight: floorH,
      roofHeight: h * _roofShare,
      street: street,
      doorWidth: doorW,
      doors: doors,
    );
  }

  final double left;
  final double bodyWidth;
  final double floorsTop;
  final double floorHeight;
  final double roofHeight;
  final double street;
  final double doorWidth;
  final List<TitleDoor> doors;

  static const int _floors = 3;
  static const double _bodyShare = 0.72;
  static const double _roofShare = 0.1;
  static const double _streetShare = 0.07;
  static const double _floorsShare = 0.28;
  static const double _gapShare = 0.32;

  /// A door is at most this share of its floor's height…
  static const double _doorShare = 0.74;

  /// …and stands this share above the floor's bottom edge (its sill on the floor below).
  static const double _sillShare = 0.1;
}

/// The title tower's building: the day sky with two clouds, the neighbours, an ink antenna with
/// its honey beacon, a dusk roof, three floors (dusk on top, floor 2's soft, floor 1) and a sand
/// street. The doors stand on it ([TitleTower]).
class TitleTowerPainter extends CustomPainter {
  const TitleTowerPainter();

  /// Doors on each floor.
  static const int across = 7;

  static const double _beacon = 5;
  static const double _antenna = 0.08;

  /// The line under each floor's doors, where the wall meets the floor.
  static const double _ledge = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final l = TitleTowerLayout.of(size);
    final paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = DaylightColors.sky);
    _cloud(canvas, Offset(w * 0.14, h * 0.18), w * 0.12);
    _cloud(canvas, Offset(w * 0.84, h * 0.1), w * 0.1);
    // The neighbours, either side.
    paint.color = DaylightColors.cityFar;
    canvas
      ..drawRect(Rect.fromLTWH(0, h * 0.5, w * 0.12, h * 0.5), paint)
      ..drawRect(Rect.fromLTWH(w * 0.9, h * 0.38, w * 0.1, h * 0.62), paint);
    final left = l.left;
    final bodyW = l.bodyWidth;
    final floorsTop = l.floorsTop;
    final roofH = l.roofHeight;
    // The antenna and its beacon.
    final antennaTop = floorsTop - roofH - h * _antenna;
    paint
      ..color = DaylightColors.ink
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(w / 2, antennaTop),
      Offset(w / 2, floorsTop - roofH),
      paint,
    );
    canvas.drawCircle(
      Offset(w / 2, antennaTop),
      _beacon,
      Paint()..color = DaylightColors.honey,
    );
    // The roof, a trapezoid in dusk.
    final roof = Path()
      ..moveTo(left + bodyW * 0.08, floorsTop - roofH)
      ..lineTo(left + bodyW * 0.92, floorsTop - roofH)
      ..lineTo(left + bodyW, floorsTop)
      ..lineTo(left, floorsTop)
      ..close();
    canvas.drawPath(roof, Paint()..color = DaylightColors.dusk);
    // Three floors, top first: dusk, floor 2's soft, floor 1; each with the ledge its doors
    // stand on, in the colour of its doors' frames.
    final floors = [
      (DaylightColors.dusk, DoorInk.dusk.frame),
      (DaylightFloors.two.soft, DoorInk.open(DaylightFloors.two).frame),
      (DaylightFloors.one.base, DoorInk.open(DaylightFloors.one).frame),
    ];
    final doorH = l.doorWidth * TowerDoor.aspect;
    for (final (row, (wall, ledge)) in floors.indexed) {
      final top = floorsTop + l.floorHeight * row;
      canvas.drawRect(
        Rect.fromLTWH(left, top, bodyW, l.floorHeight),
        Paint()..color = wall,
      );
      final sill = l.doors[row * across].at.dy + doorH;
      canvas.drawRect(
        Rect.fromLTWH(left, sill, bodyW, _ledge),
        Paint()..color = ledge,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, h - l.street, w, l.street),
      Paint()..color = DaylightColors.desk,
    );
  }

  void _cloud(Canvas canvas, Offset c, double r) {
    final p = Paint()..color = DaylightColors.skyCloud;
    canvas
      ..drawCircle(c, r * 0.45, p)
      ..drawCircle(c + Offset(r * 0.45, r * 0.1), r * 0.35, p)
      ..drawCircle(c - Offset(r * 0.45, -r * 0.1), r * 0.32, p)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - r * 0.75, c.dy, r * 1.5, r * 0.4),
          Radius.circular(r * 0.2),
        ),
        p,
      );
  }

  @override
  bool shouldRepaint(TitleTowerPainter old) => false;
}
