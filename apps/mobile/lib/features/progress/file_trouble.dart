import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';

/// Your file, a past result or the Chapter 1 report couldn't be read from the device (brief 24:
/// every error state designed; Daylight in brief 48). A white card on the paper: a clay
/// warning tile, what failed, the promise that nothing is lost, and one way to try again.
class FileTrouble extends StatelessWidget {
  const FileTrouble({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const String title = "Your file didn't open";
  static const String line =
      'Nothing is lost: your rooms are kept on this phone. Try again in a moment.';
  static const String retry = 'Try again';

  static const double _tile = 48;

  @override
  Widget build(BuildContext context) => DaylightPanel(
    padding: const EdgeInsets.all(DaylightSpace.s24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _tile,
          height: _tile,
          decoration: BoxDecoration(
            color: DaylightColors.trapTint,
            borderRadius: BorderRadius.circular(DaylightRadius.tile),
          ),
          child: const Icon(
            PhosphorBold.warningCircle,
            size: DaylightSpace.s24,
            color: DaylightColors.trap,
          ),
        ),
        const SizedBox(height: DaylightSpace.s16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(title, style: DaylightType.heading5),
        ),
        const SizedBox(height: DaylightSpace.s8),
        Text(
          line,
          style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
        ),
        const SizedBox(height: DaylightSpace.s24),
        TactileButton(
          label: retry,
          icon: PhosphorBold.arrowCounterClockwise,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
