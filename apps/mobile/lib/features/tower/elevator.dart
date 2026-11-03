import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../../ui/film/cue.dart';
import '../../ui/film/timeline.dart';

/// The ride from the Tower to a room (brief 13; Daylight in brief 46): two doors in the
/// floor's colours slide shut from both sides, each with its deep edge, while the floor
/// indicator in a honey arch above climbs to the room's number. About [BrandMotion.elevator]
/// long; a tap skips it. Under reduced motion it's a plain fade to the floor's tint.
class Elevator extends StatelessWidget {
  const Elevator({
    super.key,
    required this.floor,
    required this.grade,
    required this.onArrived,
  });

  /// The room number the indicator climbs to.
  final int floor;
  final ChapterGrade grade;
  final VoidCallback onArrived;

  static const String skipLabel = 'Skip the ride';

  // The cue sheet, as shares of the ride: the doors meet, the indicator climbs meanwhile.
  static const double _doorsShut = 0.55;
  static const double _climbFrom = 0.1;
  static const double _climbTo = 0.8;
  static const double _arch = 96;
  static const double _archHeight = 112;
  static const double _seam = 4;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final f = grade.floor;
    return Semantics(
      button: true,
      label: skipLabel,
      onTap: onArrived,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onArrived,
        child: Timeline(
          duration: still ? DaylightMotion.colour : BrandMotion.elevator,
          onFinished: onArrived,
          builder: (context, t, _) {
            if (still) {
              return Opacity(
                opacity: t,
                child: ColoredBox(color: f.tint),
              );
            }
            final close = cue(t, 0, _doorsShut, DaylightMotion.ease);
            final shown =
                1 + ((floor - 1) * cue(t, _climbFrom, _climbTo)).round();
            return LayoutBuilder(
              builder: (context, box) {
                final half = box.maxWidth / 2;
                Widget door(Alignment side, Color face) => Align(
                  alignment: side,
                  child: SizedBox(
                    width: half * close,
                    height: box.maxHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: face,
                        border: Border(
                          left: side == Alignment.centerRight
                              ? BorderSide(color: f.deep, width: _seam)
                              : BorderSide.none,
                          right: side == Alignment.centerLeft
                              ? BorderSide(color: f.deep, width: _seam)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: f.tint.withValues(alpha: close)),
                    door(Alignment.centerLeft, f.base),
                    door(Alignment.centerRight, f.base),
                    Align(
                      alignment: const Alignment(0, -0.55),
                      child: Opacity(
                        opacity: close,
                        child: SizedBox(
                          width: _arch,
                          height: _archHeight,
                          child: ArchFrame(
                            ground: DaylightColors.honey,
                            border: DaylightSpace.s4,
                            borderColor: DaylightColors.honeyTint,
                            child: Center(
                              child: Text(
                                '$shown',
                                style: DaylightType.tabular(
                                  DaylightType.heading2,
                                ).copyWith(color: DaylightColors.onHoney),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
