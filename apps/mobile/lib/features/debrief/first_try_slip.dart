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

  static const String yours = 'YOUR FIRST TRY';
  static const String strongerHeading = 'A STRONGER VERSION';

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: SlipInk.soft);
    final quote = BrandType.choice.copyWith(
      color: SlipInk.text,
      fontStyle: FontStyle.italic,
    );
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(yours, style: soft)),
          const SizedBox(height: BrandSpace.xs),
          Text('“$firstTry”', style: quote),
          const SizedBox(height: BrandSpace.md),
          const DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: SlipInk.soft)),
            ),
            child: SizedBox(width: double.infinity),
          ),
          const SizedBox(height: BrandSpace.md),
          Semantics(header: true, child: Text(strongerHeading, style: soft)),
          const SizedBox(height: BrandSpace.xs),
          Text('“$stronger”', style: quote),
        ],
      ),
    );
  }
}
