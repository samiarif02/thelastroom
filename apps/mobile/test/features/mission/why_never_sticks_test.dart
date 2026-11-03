import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart' show FeedbackSheet;

import 'mission_harness.dart';

/// The owner's P0 on the realme (2026-11-03, room 3, "Why that example?"): after a pick, the
/// why step showed her question and "Your line", then nothing, with no way on. In every room
/// answered by choices, every beat that asks why: read or guessed, the reasons always come.
void main() {
  final choiceRooms = [
    for (final m in missions)
      if (m.answerMode == AnswerMode.choices) m,
  ];

  for (final m in choiceRooms) {
    for (final guess in [false, true]) {
      testWidgets('room ${m.number}: the reasons come after every pick '
          '(${guess ? 'guessed' : 'read'})', (tester) async {
        final rig = MissionRig(tester);
        await rig.unlockThrough(m.number);
        await rig.boot(Routes.mission(m.number));
        await rig.playLines(m.number);
        if (m.offersDraft) await rig.skipDraft();
        final name = rig.state(m.number).playerName;
        for (final beat in m.beats) {
          if (beat.build case final build?) {
            // A built beat asks no why: build it in order and go on.
            await rig.build([for (final p in build.parts) p.id]);
            await rig.run(
              MissionPlayer.reactionHold + const Duration(seconds: 2),
            );
            continue;
          }
          final strongest = beat.options.firstWhere(
            (o) => beat.isStrongest(o.id),
          );
          if (!beat.asksWhy) {
            await rig.say(strongest);
            continue;
          }
          await rig.pick(strongest, guess: guess);
          await rig.until(find.text(beat.why!.line.addressedTo(name).text));
          // Past any sheet's hold, the step waits on the player with its reasons up.
          await rig.run(
            MissionPlayer.reactionHold + const Duration(seconds: 2),
          );
          expect(find.byType(FeedbackSheet), findsNothing);
          expect(
            find.text(reasonLabel),
            findsOneWidget,
            reason: '${beat.kind}',
          );
          for (final r in beat.why!.reasons) {
            expect(find.widgetWithText(ChoiceCard, r.text), findsOneWidget);
          }
          await rig.pick(
            beat.why!.reasons.firstWhere((r) => r.isSoundFor(strongest.id)),
          );
          await rig.run(
            MissionPlayer.reactionHold + const Duration(seconds: 2),
          );
        }
        await rig.until(find.text(rig.state(m.number).followUpLine!.text));
      });
    }
  }
}
