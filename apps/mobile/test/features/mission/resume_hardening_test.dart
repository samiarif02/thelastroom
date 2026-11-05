import 'package:content/content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/scene/room_intro.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';

import 'mission_harness.dart';

/// QA 51, BUG-2: room 5's saved attempt (from an older build) resumed, the why step for the
/// open beat never came, and the debrief credited a reason the player hadn't given for it.
void main() {
  final m5 = missions.firstWhere((m) => m.number == 5);
  final open = m5.beats[0];
  final evidence = m5.beats[1];
  final strongOpen = open.options.firstWhere((o) => open.isStrongest(o.id));
  Reason soundFor(Beat beat, AnswerOption o) =>
      beat.why!.reasons.firstWhere((r) => r.isSoundFor(o.id));

  Future<MissionRig> resumeRoom5(
    WidgetTester tester,
    List<SavedPlay> plays,
  ) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(5);
    await rig.resume.save(
      SavedAttempt(
        missionId: m5.id,
        seed: testSeed,
        attemptNumber: 1,
        draftDone: true,
        plays: plays,
      ),
    );
    await rig.boot(Routes.mission(5));
    await rig.until(find.text(RoomIntro.resume));
    await tester.tap(find.text(RoomIntro.resume));
    await tester.pump();
    return rig;
  }

  testWidgets(
    'a save with a line but no reason, then more lines, resumes at that why step',
    (tester) async {
      // Saved before the why steps existed: two lines locked, no reasons.
      final rig = await resumeRoom5(tester, [
        SavedPlay(optionId: strongOpen.id),
        SavedPlay(optionId: evidence.options.first.id),
      ]);
      final resumed = rig.state(5);
      expect(resumed.plays, hasLength(1), reason: 'the later line is dropped');
      expect(resumed.awaitingWhy, isTrue);

      // The open beat's reasons come; the one given is the one credited.
      final reason = soundFor(open, strongOpen);
      await rig.until(find.widgetWithText(ChoiceCard, reason.text));
      expect(find.text(reasonLabel), findsOneWidget);
      await rig.pick(reason);
      expect(rig.state(5).plays.single.reason, reason);
      await rig.until(find.text(beatLabel(evidence.kind, 1, m5.beats.length)));
      await rig.run(const Duration(seconds: 3));
    },
  );

  testWidgets('a reason saved on a built beat is dropped on resume', (
    tester,
  ) async {
    final m4 = missions.firstWhere((m) => m.number == 4);
    final build = m4.beats[1].build!;
    final built = build.answerFor([for (final p in build.parts) p.id]);
    final open4 = m4.beats[0];
    final strong4 = open4.options.firstWhere((o) => open4.isStrongest(o.id));
    final rig = MissionRig(tester);
    await rig.unlockThrough(4);
    await rig.resume.save(
      SavedAttempt(
        missionId: m4.id,
        seed: testSeed,
        attemptNumber: 1,
        draftDone: true,
        plays: [
          SavedPlay(
            optionId: strong4.id,
            reasonId: soundFor(open4, strong4).id,
          ),
          // A built beat asks no why: a reason here is from another build's rules.
          SavedPlay(
            optionId: built.id,
            reasonId: m4.beats[1].why!.reasons.first.id,
          ),
        ],
      ),
    );
    await rig.boot(Routes.mission(4));
    await rig.until(find.text(RoomIntro.resume));
    await tester.tap(find.text(RoomIntro.resume));
    await tester.pump();
    final plays = rig.state(4).plays;
    expect(plays, hasLength(2));
    expect(plays[0].reason, soundFor(open4, strong4));
    expect(plays[1].reason, isNull);
    await rig.run(const Duration(seconds: 2));
  });

  testWidgets(
    'a scene out of step with the attempt never reacts to an old line or skips a why',
    (tester) async {
      // Resumed at the open beat's cards; then the attempt moves on under the scene (the
      // phone's case: an open beat already locked and explained in the attempt).
      final rig = await resumeRoom5(tester, const []);
      await rig.until(find.text(beatLabel(open.kind, 0, m5.beats.length)));
      await rig.run(readFor);
      final controller = rig.container.read(
        missionControllerProvider(5).notifier,
      );
      final stale = open.why!.reasons.firstWhere(
        (r) => !r.isSoundFor(strongOpen.id),
      );
      controller
        ..lock(strongOpen, decidedIn: readFor)
        ..giveReason(stale);
      await tester.pump();

      // The player locks a line on the open beat the scene still shows.
      final shown = rig.state(5).optionsForBeat(0).last;
      await rig.pick(shown, guess: true);
      final reactions = [
        open.reaction!.strong.text,
        open.reaction!.weak.text,
        open.reaction!.guessed.text,
      ];
      var reacted = false;
      await rig.run(
        const Duration(seconds: 3),
        eachFrame: () => reacted |= reactions.any(
          (text) => find.text(text).evaluate().isNotEmpty,
        ),
      );

      // Nothing new is locked, no reaction to the old open line, and the scene is on the
      // evidence beat the attempt is at, ready for its own line and why.
      expect(rig.state(5).plays, hasLength(1));
      expect(reacted, isFalse);
      await rig.until(find.text(beatLabel(evidence.kind, 1, m5.beats.length)));
      final line = evidence.options.firstWhere(
        (o) => evidence.isStrongest(o.id),
      );
      await rig.say(line);
      expect(rig.state(5).plays, hasLength(2));
      expect(rig.state(5).plays[1].reason, soundFor(evidence, line));
      await rig.run(const Duration(seconds: 3));
    },
  );
}
