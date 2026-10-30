import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The ride from the Tower to a room (brief 13): brass doors close from both sides while the
/// floor indicator climbs to the mission's number, about [BrandMotion.elevator] long. A tap
/// skips it. Under reduced motion it's a plain cross-fade to black.
class Elevator extends StatelessWidget {
  const Elevator({
    super.key,
    required this.floor,
    required this.grade,
    required this.onArrived,
  });

  /// The mission number the indicator climbs to.
  final int floor;
  final ChapterGrade grade;
  final VoidCallback onArrived;

  static const String skipLabel = 'Skip the ride';

  // The cue sheet, as shares of the ride: the doors meet, the indicator climbs meanwhile.
  static const double _doorsShut = 0.55;
  static const double _climbFrom = 0.1;
  static const double _climbTo = 0.8;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: skipLabel,
      onTap: onArrived,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onArrived,
        child: Timeline(
          duration: still
              ? BrandMotion.reducedMotionFade
              : BrandMotion.elevator,
          onFinished: onArrived,
          builder: (context, t, _) {
            if (still) {
              return Opacity(
                opacity: t,
                child: const ColoredBox(color: BrandColors.void_),
              );
            }
            final close = cue(t, 0, _doorsShut, BrandMotion.camera);
            final shown =
                1 + ((floor - 1) * cue(t, _climbFrom, _climbTo)).round();
            return LayoutBuilder(
              builder: (context, box) {
                final half = box.maxWidth / 2;
                Widget door(Alignment side) => Align(
                  alignment: side,
                  child: SizedBox(
                    width: half * close,
                    height: box.maxHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [BrandColors.surfaceRaised, grade.shadow],
                        ),
                        border: Border.symmetric(
                          vertical: BorderSide(
                            color: grade.key.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: BrandColors.void_.withValues(alpha: 0.6 * close),
                    ),
                    door(Alignment.centerLeft),
                    door(Alignment.centerRight),
                    Align(
                      alignment: const Alignment(0, -0.6),
                      child: Text(
                        '$shown',
                        style: BrandType.display.copyWith(color: grade.key),
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
