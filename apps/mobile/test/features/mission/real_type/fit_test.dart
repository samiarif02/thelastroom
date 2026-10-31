import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';

import '../mission_harness.dart';

/// Brief 18: "one tap per choice and no scrolling". With real type (this folder loads the
/// bundled fonts), the question and every card of every beat fit the realme 8's screen.
void main() {
  /// The realme 8 (RMX3085): 1080 × 2400 px at 2.625, in logical pixels.
  const realme8 = Size(411, 914);

  testWidgets('the question and every card fit the realme 8, no scrolling', (
    tester,
  ) async {
    const mission = missionTheOpportunity;
    final rig = MissionRig(tester);
    // Edge to edge: the status bar and Android's gesture bar take their share.
    await rig.boot(
      Routes.mission(1),
      size: realme8,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
    );
    await rig.playLines(1);
    await rig.skipDraft();
    double overflow() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(LowerThird),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .maxScrollExtent;
    for (final (i, beat) in mission.beats.indexed) {
      await rig.until(find.text(beatLabel(beat.kind, i, mission.beats.length)));
      await rig.run(const Duration(seconds: 1));
      expect(overflow(), 0, reason: '${beat.kind}');
      expect(find.byType(QuestionReminder), findsOneWidget);
      await rig.say(beat.options.firstWhere((o) => beat.isStrongest(o.id)));
    }
    await rig.run(const Duration(seconds: 6));
  });
}
