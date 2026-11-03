import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'red_pen_slip.dart';

/// "Then / Now" (FR-41): the player's own words from Mission 1's draft beside the answer they
/// gave at the chapter's review. The promise the draft step makes ("later we'll put it beside a
/// newer answer"), kept on Mission 7's debrief and in the Chapter 1 report. The draft is shown
/// as typed and never leaves the device.
class ThenNowSlip extends StatelessWidget {
  const ThenNowSlip({
    super.key,
    required this.then,
    required this.now,
    required this.nowMission,
  });

  /// The player's Mission 1 draft.
  final String then;

  /// Their answer at the review, its lines joined.
  final String now;

  /// The review's number, for the heading.
  final int nowMission;

  static const String heading = 'Then / now';
  static const String thenHeading = 'Then · room 1, in your own words';
  static String nowHeading(int mission) => 'NOW · MISSION $mission';

  @override
  Widget build(BuildContext context) {
    final soft = SlipType.label.copyWith(color: SlipInk.soft);
    final quote = SlipType.quote.copyWith(color: SlipInk.text);
    return PaperSlip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(heading, style: soft)),
          const SizedBox(height: DaylightSpace.s16),
          Text(thenHeading, style: soft),
          const SizedBox(height: DaylightSpace.s4),
          Text('“$then”', style: quote),
          const SizedBox(height: DaylightSpace.s16),
          const DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: SlipInk.soft)),
            ),
            child: SizedBox(width: double.infinity),
          ),
          const SizedBox(height: DaylightSpace.s16),
          Text(nowHeading(nowMission), style: soft),
          const SizedBox(height: DaylightSpace.s4),
          Text('“$now”', style: quote),
        ],
      ),
    );
  }
}
