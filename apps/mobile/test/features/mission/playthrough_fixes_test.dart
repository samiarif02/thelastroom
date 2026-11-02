import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/debrief_view.dart';
import 'package:the_last_room/features/debrief/reasoning_slip.dart';
import 'package:the_last_room/features/debrief/red_pen_slip.dart';
import 'package:the_last_room/features/debrief/then_now_slip.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/epilogue_scene.dart';
import 'package:the_last_room/features/mission/widgets/leave_control.dart';
import 'package:the_last_room/features/mission/widgets/next_control.dart';
import 'package:the_last_room/features/mission/widgets/scene_notes.dart';
import 'package:the_last_room/features/progress/chapter_report_screen.dart';
import 'package:the_last_room/features/tower/tower_extras.dart';
import 'package:the_last_room/features/tower/tower_hero.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'mission_harness.dart';

/// Brief 30: what the Chapter 1 playthrough found, fixed.
void main() {
  const draft = 'I applied because I like talking to users.';

  /// The weakest line of every beat at [m], with the default follow-up's first reply: an
  /// attempt that leaves a trap card in the Recall Room.
  AttemptRecord weak(Mission m) {
    final followUp = m.followUps.firstWhere((f) => f.trigger == null);
    final picks = [
      for (final b in m.beats) b.options.lastWhere((o) => !b.isStrongest(o.id)),
    ];
    return AttemptRecord(
      missionId: m.id,
      attemptNumber: 2,
      seed: testSeed,
      beatOptionIds: [for (final o in picks) o.id],
      followUpId: followUp.id,
      replyOptionId: followUp.replies.first.id,
      hinted: m.hinted,
      score: scoreAttempt(
        AttemptInput(
          picks: [
            for (var i = 0; i < picks.length; i++)
              BeatPick(beat: m.beats[i].kind, choice: picks[i].scored),
          ],
          followUpReply: followUp.replies.first.scored,
          hinted: m.hinted,
        ),
      ),
    );
  }

  group('the tower is never stale', () {
    testWidgets(
      'back from anywhere, the rooms and the Recall Room are read again',
      (tester) async {
        final rig = MissionRig(tester);
        await rig.unlockThrough(7);
        await rig.boot(Routes.tower());
        await rig.run(const Duration(seconds: 3));
        expect(
          find.bySemanticsLabel(RegExp('^Mission 7, .*Play')),
          findsOneWidget,
        );
        expect(
          find.text(RecallRoomCardView.caughtUp.toUpperCase()),
          findsOneWidget,
        );

        // Mission 7 is played and a weak attempt leaves a card, while the player is elsewhere
        // (the report, the file): coming back must show both.
        await rig.progress.recordAttempt(weak(missions[0]));
        await rig.progress.recordAttempt(
          weak(missions.lastWhere((m) => m.chapter == 1)),
        );
        rig.container.read(routerProvider).go(Routes.report);
        await rig.until(find.byType(ChapterReportScreen));
        rig.container.read(routerProvider).go(Routes.tower());
        await rig.until(find.textContaining(RegExp(r'^\d+ CARDS? DUE$')));
        expect(
          find.bySemanticsLabel(RegExp('^Mission 7, .*Done')),
          findsOneWidget,
        );
        expect(find.textContaining(TowerHero.beatYourBest), findsOneWidget);
        // Cards due: the Recall Room sits under the hero, above the chapters.
        final recall = tester.getTopLeft(find.byType(RecallRoomCard)).dy;
        final chapter = tester.getTopLeft(find.text('Get Through the Door')).dy;
        expect(recall, lessThan(chapter));
      },
    );

    testWidgets('a mission left part-way says Continue, not Play', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.resume.save(
        SavedAttempt(
          missionId: missions.first.id,
          seed: testSeed,
          attemptNumber: 1,
          draftDone: true,
          plays: [
            SavedPlay(optionId: missions.first.beats.first.options.first.id),
          ],
        ),
      );
      await rig.boot(Routes.tower());
      await rig.run(const Duration(seconds: 3));
      expect(find.text(TowerHero.continueLabel), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Left part-way: continue')),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'a build out of order: its own reaction, and never "nothing to mark"',
    (tester) async {
      final m4 = missions.firstWhere((m) => m.number == 4);
      final build = m4.beats[1].build!;
      final parts = [for (final p in build.parts) p.id];
      final rig = MissionRig(tester);
      await rig.unlockThrough(4);
      await rig.boot(Routes.mission(4));
      await rig.playLines(4);
      final open = m4.beats[0];
      await rig.say(open.options.firstWhere((o) => open.isStrongest(o.id)));
      await rig.build([parts[0], parts[2], parts[1], parts[3]]);
      await rig.until(find.text(build.weakReaction.text));
      expect(find.text(m4.beats[1].reaction!.weak.text), findsNothing);

      final land = m4.beats[2];
      await rig.say(land.options.firstWhere((o) => land.isStrongest(o.id)));
      await rig.until(find.text(rig.state(4).followUpLine!.text));
      await rig.run(const Duration(milliseconds: 300));
      if (rig.typing) await rig.tapScene();
      final followUp = rig.state(4).followUp!;
      await rig.say(
        followUp.replies.reduce(
          (a, b) => a.scores.adaptability >= b.scores.adaptability ? a : b,
        ),
      );
      await rig.until(find.byType(Dossier));
      await rig.settleDossier();
      expect(
        rig.state(4).score!.dimensions[Dimension.structure],
        lessThan(100),
      );
      expect(find.text(CleanRunSlip.text), findsNothing);
      final cost = find.text('The evidence: 1 piece out of order.');
      await tester.ensureVisible(cost);
      expect(cost, findsOneWidget);
      expect(find.text(CostSlip.heading), findsOneWidget);
    },
  );

  testWidgets(
    'Mission 7: Then / Now, the cliffhanger, then the report with Then / Now',
    (tester) async {
      final review = missions.lastWhere((m) => m.chapter == 1);
      final rig = MissionRig(tester);
      await rig.unlockThrough(review.number, baselineDraft: draft);
      await rig.boot(Routes.mission(review.number));
      final followUp = review.followUps.firstWhere((f) => f.trigger == null);
      await rig.play(
        review.number,
        beats: [
          for (final b in review.beats)
            b.build?.strongAnswer.id ??
                b.options.firstWhere((o) => b.isStrongest(o.id)).id,
        ],
        reply: followUp.replies.first.id,
      );
      await rig.settleDossier();
      final then = find.text('“$draft”');
      await tester.ensureVisible(then);
      expect(then, findsOneWidget);
      expect(find.text(ThenNowSlip.heading), findsOneWidget);

      final toReport = find.text(DebriefView.reportLabel);
      await tester.ensureVisible(toReport);
      await tester.tap(toReport);
      await rig.until(find.byType(EpilogueScene));
      expect(rig.sounds.count('cliffhanger'), 1);
      expect(find.byType(ChapterReportScreen), findsNothing);
      for (var i = 0; i < review.epilogue.length - 1; i++) {
        await rig.until(find.byType(NextControl));
        await tester.tap(find.byType(NextControl));
        await tester.pump();
      }
      final done = find.descendant(
        of: find.byType(EpilogueScene),
        matching: find.text(DebriefView.reportLabel),
      );
      await rig.until(done);
      await tester.tap(done);
      await rig.until(find.text(ChapterReportScreen.honest));
      final inReport = find.text('“$draft”');
      await tester.ensureVisible(inReport);
      expect(inReport, findsOneWidget);
    },
  );

  testWidgets('the leave sheet hides the scene from screen readers', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await tester.tap(find.bySemanticsLabel(LeaveControl.label));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(LeaveSheet),
        matching: find.byType(BlockSemantics),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(LeaveSheet.resume));
    await rig.run(const Duration(seconds: 6));
  });
}
