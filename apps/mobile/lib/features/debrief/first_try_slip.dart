import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'red_pen_slip.dart';

/// The player's own first try beside the strongest opening line (owner, 2026-10-30: "the
/// answer I save doesn't show up"). The draft is shown as typed and never leaves the device.
class FirstTrySlip extends StatelessWidget {
  const FirstTrySlip({
    super.key,
    required this.firstTry,
    required this.stronger,
  });

  /// The player's words from the draft-first step.
  final String firstTry;

  /// The opening line that scores best in this mission.
  final String stronger;

  static const String yours = 'Your first try';
  static const String strongerHeading = 'A stronger version';

  @override
  Widget build(BuildContext context) {
    final soft = SlipType.label.copyWith(color: SlipInk.soft);
    final quote = SlipType.quote.copyWith(color: SlipInk.text);
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(yours, style: soft)),
          const SizedBox(height: DaylightSpace.s4),
          Text('“$firstTry”', style: quote),
          const SizedBox(height: DaylightSpace.s16),
          const DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: SlipInk.soft)),
            ),
            child: SizedBox(width: double.infinity),
          ),
          const SizedBox(height: DaylightSpace.s16),
          Semantics(header: true, child: Text(strongerHeading, style: soft)),
          const SizedBox(height: DaylightSpace.s4),
          Text('“$stronger”', style: quote),
        ],
      ),
    );
  }
}
