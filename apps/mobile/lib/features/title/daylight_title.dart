import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../../ui/film/cue.dart';
import '../../ui/film/timeline.dart';

/// The app's title in Daylight (brief 20; brief 48): Northstar tower against the day sky, its
/// windows lighting honey floor by floor from the street up, the top floor at dusk until Sam's
/// one window lights last. Then the name (Bricolage, sentence case), the line, and the four
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
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: TitleTowerPainter(lit: lights),
                          ),
                        ),
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

/// Northstar tower on the title: the day sky with two clouds, the neighbours, the building
/// (an ink roof with its honey beacon, three floors of seven arched windows, a sand street),
/// and [lit] (0 → 1) lighting the windows honey from the street up, Sam's window on the top
/// floor last. The top floor's other windows stay dusk: it's still to come.
class TitleTowerPainter extends CustomPainter {
  const TitleTowerPainter({required this.lit});

  final double lit;

  static const int _across = 7;
  static const double _bodyShare = 0.72;
  static const double _roofShare = 0.1;
  static const double _streetShare = 0.07;
  static const double _gapShare = 0.32;
  static const double _windowHeight = 0.62;
  static const double _beacon = 5;
  static const double _antenna = 0.08;
  static const int _samWindow = 6;

  /// Floor 1 and floor 2 light (14 windows), then Sam's.
  static const int _lighting = _across * 2 + 1;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = DaylightColors.sky);
    _cloud(canvas, Offset(w * 0.14, h * 0.18), w * 0.12);
    _cloud(canvas, Offset(w * 0.84, h * 0.1), w * 0.1);
    final street = h * _streetShare;
    // The neighbours, either side.
    paint.color = DaylightColors.cityFar;
    canvas
      ..drawRect(Rect.fromLTWH(0, h * 0.5, w * 0.12, h * 0.5), paint)
      ..drawRect(Rect.fromLTWH(w * 0.9, h * 0.38, w * 0.1, h * 0.62), paint);
    final bodyW = math.min(w * _bodyShare, h * 1.1);
    final left = (w - bodyW) / 2;
    final roofH = h * _roofShare;
    final floorsTop = h * 0.28;
    final floorH = (h - street - floorsTop) / 3;
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
    // Three floors, top first: dusk, floor 2's soft, floor 1.
    final floors = [
      (DaylightColors.dusk, DaylightColors.ink, 2),
      (DaylightFloors.two.soft, DaylightFloors.two.tint, 1),
      (DaylightFloors.one.base, DaylightFloors.one.deep, 0),
    ];
    final cell = bodyW / _across;
    final winW = cell * (1 - _gapShare);
    final count = (lit.clamp(0.0, 1.0) * _lighting).floor();
    for (final (row, (wall, window, floor)) in floors.indexed) {
      final top = floorsTop + floorH * row;
      canvas.drawRect(
        Rect.fromLTWH(left, top, bodyW, floorH),
        Paint()..color = wall,
      );
      final winH = floorH * _windowHeight;
      for (var i = 0; i < _across; i++) {
        final x = left + cell * i + (cell - winW) / 2;
        final y = top + (floorH - winH) / 2;
        // The order windows light in: floor 1 left to right, floor 2, then Sam's.
        final order = switch (floor) {
          0 => i,
          1 => _across + i,
          _ => i == _samWindow ? _across * 2 : null,
        };
        final on = order != null && order < count;
        final r = Radius.circular(winW / 2);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, y, winW, winH),
            topLeft: r,
            topRight: r,
            bottomLeft: const Radius.circular(DaylightSpace.s2),
            bottomRight: const Radius.circular(DaylightSpace.s2),
          ),
          Paint()..color = on ? DaylightColors.honey : window,
        );
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, h - street, w, street),
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
  bool shouldRepaint(TitleTowerPainter old) => old.lit != lit;
}
