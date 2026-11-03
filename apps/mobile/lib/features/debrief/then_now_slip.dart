import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';

/// "Then and now" (FR-41): the player's own words from Mission 1's draft beside the answer they
/// gave at the chapter's review. The promise the draft step makes ("later we'll put it beside a
/// newer answer"), kept on Mission 7's debrief and in the Chapter 1 report. Daylight (brief
/// 48), one look in both places: a white card, the draft in quotation marks (roman, never
/// italic), then the review's lines on the floor's tint. The draft is shown as typed and never
/// leaves the device.
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

  static const String heading = 'Then and now';
  static const String thenHeading = 'Room 1, in your own words';
  static String nowHeading(int room) => 'Room $room, the lines you chose';

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DaylightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(heading, style: DaylightType.heading6),
          ),
          const SizedBox(height: DaylightSpace.s12),
          Text(
            thenHeading,
            style: DaylightType.caption3.copyWith(color: DaylightColors.ink2),
          ),
          const SizedBox(height: DaylightSpace.s4),
          Text('“$then”', style: DaylightType.body3),
          const SizedBox(height: DaylightSpace.s16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: f.tint,
              borderRadius: BorderRadius.circular(DaylightRadius.inner),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DaylightSpace.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    nowHeading(nowMission),
                    style: DaylightType.caption3.copyWith(color: f.deep),
                  ),
                  const SizedBox(height: DaylightSpace.s4),
                  Text('“$now”', style: DaylightType.body3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
