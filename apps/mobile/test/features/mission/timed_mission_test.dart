import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/mission/widgets/beat_timer.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';

import 'mission_harness.dart';

void main() {
  testWidgets(
    'a timed mission dims the room, counts the last ten seconds, never forces',
    (tester) async {
      expect(missionTellMeAboutYourself.timed, isTrue);
      final rig = MissionRig(tester);
      await rig.unlockThrough(2);
      await rig.boot(Routes.mission(2));
      await rig.playLines(2); // hinted: no draft step
      await rig.until(find.byType(ChoiceCard));
      expect(find.byType(BeatTimer), findsOneWidget);

      const step = Duration(milliseconds: 250);
      // The number, shown only in the last ten seconds.
      final countdown = find.byWidgetPredicate((w) {
        final n = w is Text ? int.tryParse(w.data ?? '') : null;
        return n != null && n <= BeatTimer.countdownFrom;
      });
      // Quiet until the last stretch, 20 s left.
      await rig.run(const Duration(seconds: 39), step: step);
      expect(rig.sounds.count('timerPulse'), 0);
      expect(find.text('15'), findsNothing);
      await rig.run(const Duration(seconds: 16), step: step);
      expect(countdown, findsOneWidget);
      await rig.run(const Duration(seconds: 8), step: step);

      // Expired once, on the open beat; the pulses ran through the last stretch.
      expect(rig.analytics.count(AnalyticsEvent.answerTimerExpired), 1);
      expect(
        rig.analytics.only(AnalyticsEvent.answerTimerExpired).wire['beat'],
        'open',
      );
      final pulses = rig.sounds.argsOf('timerPulse');
      expect(pulses, hasLength(BeatTimer.pulseFrom));
      expect(
        pulses.where((p) => p.first == true),
        hasLength(BeatTimer.countdownFrom),
      );

      // Nothing was picked for the player, and the beat is still open.
      expect(rig.state(2).picks, isEmpty);
      await rig.say(missionTellMeAboutYourself.beats.first.options.first);
      expect(rig.state(2).picks, hasLength(1));
      // The next beat gets a fresh minute.
      await rig.run(const Duration(seconds: 2), step: step);
      expect(countdown, findsNothing);
      expect(rig.analytics.count(AnalyticsEvent.answerTimerExpired), 1);
    },
  );
}
