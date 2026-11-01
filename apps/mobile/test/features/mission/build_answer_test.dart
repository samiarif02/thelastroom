import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/progress/attempt_score.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/reasoning_slip.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/widgets/build_panel.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/mission/widgets/scene_notes.dart';
import 'package:the_last_room/features/recall/recall_deck.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'mission_harness.dart';

/// Brief 27: "Build your answer". Mission 4's evidence beat is built from fragments.
void main() {
  final mission = missions.firstWhere((m) => m.number == 4);
  final open = mission.beats[0];
  final evidence = mission.beats[1];
  final build = evidence.build!;
  final parts = [for (final p in build.parts) p.id];
  final decoy = build.decoys.single.id;
  final strongOpen = open.options.firstWhere((o) => open.isStrongest(o.id));

  /// Mission 4 open, its strong opening said, at the built beat.
  Future<MissionRig> atTheBuild(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(4);
    await rig.boot(Routes.mission(4), reduceMotion: reduceMotion);
    await rig.playLines(4);
    await rig.say(strongOpen);
    await rig.until(find.byType(BuildPanel));
    return rig;
  }

  int? positionOf(MissionRig rig, String id) => rig.tester
      .widget<FragmentChip>(
        find.widgetWithText(FragmentChip, rig.fragmentText(id)),
      )
      .position;

  Map<String, Object?> builtEvent(MissionRig rig) =>
      rig.analytics.only(AnalyticsEvent.answerBuilt).wire;

  testWidgets('the beat is fragments to build, not cards to pick', (
    tester,
  ) async {
    final rig = await atTheBuild(tester);
    expect(find.byType(ChoiceCard), findsNothing);
    expect(find.byType(FragmentChip), findsNWidgets(build.fragments.length));
    expect(find.text(buildLabel(1, mission.beats.length)), findsOneWidget);
    expect(find.text(BuildPanel.empty), findsOneWidget);
    // Nothing placed: nothing to lock in.
    await tester.tap(find.text(BuildPanel.lockIn));
    await tester.pump();
    expect(rig.state(4).plays, hasLength(1));
  });

  testWidgets(
    'one tap places a fragment, the line builds live, a second tap takes it out',
    (tester) async {
      final rig = await atTheBuild(tester);
      await rig.tapFragment(parts[0]);
      await rig.tapFragment(parts[1]);
      final both =
          '${rig.fragmentText(parts[0])} ${rig.fragmentText(parts[1])}';
      expect(find.text(both), findsOneWidget);
      expect(find.text(BuildPanel.hint), findsOneWidget);
      expect(positionOf(rig, parts[1]), 2);

      await rig.tapFragment(parts[0]);
      expect(find.text(rig.fragmentText(parts[1])), findsNWidgets(2));
      expect(positionOf(rig, parts[1]), 1);
      expect(positionOf(rig, parts[0]), isNull);
    },
  );

  testWidgets(
    'every part in order: the strong answer, her strong reaction, trust up',
    (tester) async {
      final rig = await atTheBuild(tester);
      final before = rig.state(4).trust;
      await rig.build(parts);
      await rig.until(find.text(evidence.reaction!.strong.text));
      final play = rig.state(4).plays[1];
      expect(play.option.id, build.strongAnswer.id);
      expect(play.option.text, build.strongAnswer.text);
      expect(play.reason, isNull, reason: 'a built beat asks no why');
      expect(rig.state(4).trust, greaterThan(before));
      expect(builtEvent(rig), {
        'mission_id': mission.id,
        'beat': 'evidence',
        'fragments': parts.length,
        'missing': 0,
        'out_of_order': 0,
        'decoy_used': false,
        'guessed': false,
      });
    },
  );

  testWidgets(
    'the decoy, out of order: her weak reaction, and the debrief says why',
    (tester) async {
      final rig = await atTheBuild(tester);
      final placed = [parts[0], decoy, parts[2], parts[1], parts[3]];
      await rig.build(placed);
      await rig.until(find.text(evidence.reaction!.weak.text));
      final built = rig.state(4).plays[1].option;
      expect(built.flags, contains(build.decoys.single.flags.single));
      expect(built.lessonId, build.decoys.single.lessonId);
      expect(builtEvent(rig)['out_of_order'], 1);
      expect(builtEvent(rig)['decoy_used'], true);

      final land = mission.beats[2];
      await rig.say(land.options.firstWhere((o) => land.isStrongest(o.id)));
      final followUp = rig.state(4).followUpLine!;
      await rig.until(find.text(followUp.text));
      await rig.run(const Duration(milliseconds: 300));
      if (rig.typing) await rig.tapScene();
      await rig.say(rig.state(4).replyOptions.first);
      await rig.until(find.byType(Dossier));
      await rig.settleDossier();

      final note = ReasoningSlip.buildNote(scoreBuild(build.spec, placed));
      expect(note, '1 PIECE OUT OF ORDER  ·  THE DECOY WENT IN');
      final noteText = find.text(note);
      await tester.ensureVisible(noteText);
      expect(noteText, findsOneWidget);
      expect(find.text('“${built.text}”'), findsWidgets);
      expect(find.text('“${build.strongAnswer.text}”'), findsOneWidget);
    },
  );

  testWidgets('locked in before the pieces could be read: a guess', (
    tester,
  ) async {
    final rig = await atTheBuild(tester);
    await rig.build(parts, guess: true);
    await rig.until(find.text(evidence.reaction!.guessed.text));
    expect(rig.state(4).beatPicks[1].guessed, isTrue);
    expect(builtEvent(rig)['guessed'], true);
    await rig.run(const Duration(seconds: 5));
  });

  testWidgets(
    'reduced motion: the chips are simply there, and it builds the same',
    (tester) async {
      final rig = await atTheBuild(tester, reduceMotion: true);
      await rig.build(parts);
      await rig.until(find.text(evidence.reaction!.strong.text));
      expect(rig.state(4).plays[1].option.id, build.strongAnswer.id);
      await rig.run(const Duration(seconds: 5));
    },
  );

  testWidgets('a built beat survives leaving and coming back', (tester) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(4);
    final built = build.answerFor([parts[1], parts[0]]);
    await rig.resume.save(
      SavedAttempt(
        missionId: mission.id,
        seed: testSeed,
        attemptNumber: 1,
        draftDone: true,
        plays: [
          SavedPlay(
            optionId: strongOpen.id,
            reasonId: open.why!.reasons
                .firstWhere((r) => r.isSoundFor(strongOpen.id))
                .id,
          ),
          SavedPlay(optionId: built.id),
        ],
      ),
    );
    await rig.boot(Routes.mission(4));
    await rig.until(find.text(ResumeSheet.title));
    await tester.tap(find.text(ResumeSheet.resume));
    await tester.pump();
    expect(rig.state(4).plays, hasLength(2));
    expect(rig.state(4).plays[1].option.text, built.text);
  });

  test('a stored built answer scores again offline exactly as it played', () {
    final built = build.answerFor([parts[0], decoy, parts[1], parts[2]]);
    final land = mission.beats[2];
    final followUp = mission.followUps.firstWhere((f) => f.trigger == null);
    final live = scoreAttempt(
      AttemptInput(
        picks: [
          BeatPick(beat: BeatKind.open, choice: strongOpen.scored),
          BeatPick(beat: BeatKind.evidence, choice: built.scored),
          BeatPick(beat: BeatKind.land, choice: land.options.first.scored),
        ],
        followUpReply: followUp.replies.first.scored,
        hinted: mission.hinted,
      ),
    );
    final again = scoreFromPicks(
      missionId: mission.id,
      beatOptionIds: [strongOpen.id, built.id, land.options.first.id],
      followUpId: followUp.id,
      replyOptionId: followUp.replies.first.id,
      hinted: mission.hinted,
    );
    expect(again, live);
  });

  test('a weak built answer earns its lesson in the Recall Room', () {
    final deck = RecallDeck(gameContent);
    final thin = build.answerFor([parts[0], parts[3]]);
    final strong = build.strongAnswer;
    final land = mission.beats[2];
    final followUp = mission.followUps.firstWhere((f) => f.trigger == null);
    final reply = followUp.replies.firstWhere((r) => r.lessonId == null);
    List<String> cards(String evidenceId) => deck.missedCardIds(
      AttemptRecord(
        missionId: mission.id,
        attemptNumber: 1,
        seed: testSeed,
        beatOptionIds: [strongOpen.id, evidenceId, land.options.first.id],
        followUpId: followUp.id,
        replyOptionId: reply.id,
        hinted: true,
        score: scoreAttempt(
          AttemptInput(
            picks: [
              BeatPick(beat: BeatKind.open, choice: strongOpen.scored),
              BeatPick(beat: BeatKind.evidence, choice: thin.scored),
              BeatPick(beat: BeatKind.land, choice: land.options.first.scored),
            ],
            followUpReply: reply.scored,
            hinted: true,
          ),
        ),
      ),
    );
    expect(cards(thin.id), contains(build.missingLessonId));
    expect(cards(strong.id), isNot(contains(build.missingLessonId)));
  });
}
