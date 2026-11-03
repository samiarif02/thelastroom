import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/daylight/daylight_kit.dart';

/// An address with no room behind it (an old deep link, a typo on the web): the error state,
/// with the way back to the lobby. Replaces go_router's stock "Page Not Found". Daylight
/// (brief 48): Priya in her arch, puzzled, on the paper, and one honey way back.
class WrongFloorScreen extends StatelessWidget {
  const WrongFloorScreen({super.key});

  static const String eyebrow = 'Wrong floor';
  static const String title = 'There is no room here.';
  static const String message =
      'This door doesn’t lead anywhere. Your progress is safe on this device.';
  static const String action = 'Back to the lobby';

  static const double _maxWidth = 440;

  @override
  Widget build(BuildContext context) => DaylightGround(
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DaylightSpace.s24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArchPortrait(
                  person: CastPeople.priya,
                  expression: CastExpression.thinking,
                  ground: DaylightFloors.one.soft,
                ),
                const SizedBox(height: DaylightSpace.s24),
                Text(
                  eyebrow,
                  style: DaylightType.caption3.copyWith(
                    color: DaylightColors.trap,
                  ),
                ),
                const SizedBox(height: DaylightSpace.s4),
                Semantics(
                  header: true,
                  child: Text(title, style: DaylightType.heading4),
                ),
                const SizedBox(height: DaylightSpace.s8),
                Text(
                  message,
                  style: DaylightType.body3.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
                const SizedBox(height: DaylightSpace.s32),
                TactileButton(
                  label: action,
                  icon: PhosphorBold.arrowLeft,
                  onPressed: () => context.go(Routes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
