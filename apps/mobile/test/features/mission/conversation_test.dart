import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/debrief/reasoning_slip.dart';
import 'package:the_last_room/features/debrief/red_pen_slip.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/lower_third.dart';
import 'package:the_last_room/features/mission/widgets/scene_notes.dart';
import 'package:the_last_room/features/mission/widgets/trust_meter.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'mission_harness.dart';

/// Brief 18: the mission plays like a conversation. Mission 1 carries brief 19's why steps and
/// reactions on every beat.
void main() {
  /// The realme 8 (RMX3085): 1080 × 2400 px at 2.625, in logical pixels.
  const realme8 = Size(411, 914);

  const open = 0;
  const mission = missionTheOpportunity;
  final openBeat = mission.beats[open];
  final strongest = openBeat.options.firstWhere(
    (o) => openBeat.isStrongest(o.id),
  );
  final weakest = openBeat.options.firstWhere(
    (o) => !openBeat.isStrongest(o.id),
  );
  Reason soundFor(AnswerOption o) =>
      openBeat.why!.reasons.firstWhere((r) => r.isSoundFor(o.id));
  Reason unsoundFor(AnswerOption o) =>
      openBeat.why!.reasons.firstWhere((r) => !r.isSoundFor(o.id));

  Future<MissionRig> toTheCards(
    WidgetTester tester, {
    Size size = realme8,
    double textScale = 1,
  }) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1), size: size, textScale: textScale);
    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(AnswerCard));
    return rig;
  }

  InterviewerExpression face(MissionRig rig) => rig.tester
      .widget<FriendlyInterviewer>(find.byType(FriendlyInterviewer))
      .expression;

  group('one tap, no scrolling', () {
    testWidgets('a single tap says the line once the change window passes', (
      tester,
    ) async {
      final rig = await toTheCards(tester);
      await rig.run(readFor);
      await rig.tapOnce(strongest);
      await tester.pump();
      expect(find.text(changeHint), findsOneWidget);
      expect(rig.state(1).plays, isEmpty);
      await rig.run(MissionPlayer.changeWindow);
      expect(rig.state(1).plays.single.option, strongest);
      expect(find.text(changeHint), findsNothing);
      await rig.run(_settle);
    });

    testWidgets('a tap on another card in the window changes the pick', (
      tester,
    ) async {
      final rig = await toTheCards(tester);
      await rig.run(readFor);
      await rig.tapOnce(weakest);
      await rig.run(const Duration(milliseconds: 600));
      await rig.tapOnce(strongest);
      await rig.run(MissionPlayer.changeWindow);
      expect(rig.state(1).plays.single.option, strongest);
      await rig.run(_settle);
    });

    testWidgets('2x text: the cards scroll, nothing overflows', (tester) async {
      final rig = await toTheCards(tester, textScale: 2);
      await rig.say(strongest);
      await rig.until(find.text(mission.beats[1].options.first.text));
    });
  });

  group('the options come after the line, on a stopwatch', () {
    testWidgets('decidedIn is the time from the cards arriving to the pick', (
      tester,
    ) async {
      final rig = await toTheCards(tester);
      await rig.pick(strongest); // after readFor, then said at once
      final decided = rig.state(1).plays.single.decidedIn!;
      expect(decided, greaterThanOrEqualTo(guessThreshold));
      expect(decided, lessThan(readFor + const Duration(seconds: 1)));
      await rig.run(_settle);
    });

    testWidgets('no cards while the interviewer is still asking', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.mission(1), size: realme8);
      await rig.until(find.byType(TypewriterSubtitle));
      expect(find.byType(AnswerCard), findsNothing);
    });
  });

  group('a guess is seen', () {
    testWidgets(
      'a pick in the first instant: "Too fast", her guessed line, trust drops',
      (tester) async {
        final rig = await toTheCards(tester);
        final before = rig.state(1).trust;
        await rig.pick(strongest, guess: true);
        expect(rig.state(1).plays.single.pick(openBeat).guessed, isTrue);
        expect(find.text(GuessCue.text.toUpperCase()), findsOneWidget);
        expect(rig.state(1).trust, lessThan(before));
        final line = openBeat.reaction!.guessed.addressedTo(
          rig.state(1).playerName,
        );
        await rig.until(find.text(line.text));
        expect(face(rig), InterviewerExpression.hmm);
        // She still asks why.
        await rig.until(
          find.text(
            openBeat.why!.line.addressedTo(rig.state(1).playerName).text,
          ),
        );
      },
    );

    testWidgets(
      'guessing through the mission scores low, and the dossier says so',
      (tester) async {
        final rig = await toTheCards(tester);
        for (final beat in mission.beats) {
          await rig.say(
            beat.options.firstWhere((o) => beat.isStrongest(o.id)),
            guess: true,
          );
        }
        final followUp = rig.state(1).followUpLine!;
        await rig.until(find.text(followUp.text));
        await rig.run(const Duration(milliseconds: 300));
        if (rig.typing) await rig.tapScene();
        // A reply with no lesson: every line was strong, so the guesses are all that cost.
        await rig.say(
          rig.state(1).replyOptions.firstWhere((r) => r.lessonId == null),
        );
        await rig.until(find.byType(Dossier));
        await rig.settleDossier();
        final score = rig.state(1).score!;
        expect(score.guessed, isTrue);
        expect(score.guessedBeats, BeatKind.values);
        expect(find.byType(GuessedSlip), findsOneWidget);
        expect(find.byType(CleanRunSlip), findsNothing);
        expect(find.byType(ReasoningSlip), findsOneWidget);
        expect(
          find.textContaining('GUESSED IN', findRichText: true),
          findsNWidgets(mission.beats.length),
        );
      },
    );
  });

  group('"why that line?"', () {
    testWidgets('after the pick she asks why; the reason goes into the pick', (
      tester,
    ) async {
      final rig = await toTheCards(tester);
      await rig.pick(strongest);
      final name = rig.state(1).playerName;
      await rig.until(find.text(openBeat.why!.line.addressedTo(name).text));
      expect(
        find.text(reasonLabel),
        findsNothing,
      ); // the reasons wait for her line
      await rig.until(find.text(reasonLabel));
      final reasons = tester
          .widgetList<AnswerCard>(find.byType(AnswerCard))
          .map((c) => c.text)
          .toSet();
      expect(reasons, {for (final r in openBeat.why!.reasons) r.text});
      await rig.pick(soundFor(strongest));
      final pick = rig.state(1).plays.single.pick(openBeat);
      expect(pick.reason!.reasonId, soundFor(strongest).id);
      expect(pick.reason!.sound, isTrue);
      // A strong line with sound reasoning: she warms.
      await rig.until(
        find.text(openBeat.reaction!.strong.addressedTo(name).text),
      );
      expect(face(rig), InterviewerExpression.smile);
    });

    testWidgets('the right line for the wrong reason lands as weak', (
      tester,
    ) async {
      final rig = await toTheCards(tester);
      await rig.say(strongest, reason: unsoundFor(strongest));
      final name = rig.state(1).playerName;
      await rig.until(
        find.text(openBeat.reaction!.weak.addressedTo(name).text),
      );
      expect(rig.state(1).plays.single.pick(openBeat).reason!.sound, isFalse);
      expect(face(rig), InterviewerExpression.thinking);
      expect(find.byType(TrustMeter), findsOneWidget);
    });
  });

  group('back mid-mission', () {
    testWidgets(
      'back asks first; Leave keeps the attempt; reopening continues it',
      (tester) async {
        final rig = await toTheCards(tester);
        await rig.say(strongest);
        await rig.until(find.text(mission.beats[1].options.first.text));

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text(LeaveSheet.title), findsOneWidget);

        // Resume: nothing lost.
        await tester.tap(find.text(LeaveSheet.resume.toUpperCase()));
        await tester.pump();
        expect(find.text(LeaveSheet.title), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.tap(find.text(LeaveSheet.leave.toUpperCase()));
        await rig.run(const Duration(seconds: 1));
        final saved = await rig.resume.load(mission.id);
        expect(saved!.plays.single.optionId, strongest.id);
        expect(saved.plays.single.reasonId, soundFor(strongest).id);
        expect(saved.seed, testSeed);
        expect(rig.analytics.count(AnalyticsEvent.missionLeft), 1);
        expect(find.byType(MissionPlayer), findsNothing);

        // Back in: continue where you left off, at the evidence beat, same order.
        rig.container.read(routerProvider).go(Routes.mission(1));
        await rig.until(find.text(ResumeSheet.title));
        await tester.tap(find.text(ResumeSheet.resume.toUpperCase()));
        await rig.until(find.byType(AnswerCard));
        expect(rig.state(1).resumed, isTrue);
        expect(rig.state(1).plays.single.option, strongest);
        expect(
          find.text(beatLabel(BeatKind.evidence, 1, mission.beats.length)),
          findsOneWidget,
        );
        expect(rig.analytics.count(AnalyticsEvent.missionResumed), 1);
      },
    );

    testWidgets('"Start again" drops the saved attempt', (tester) async {
      final rig = MissionRig(tester);
      await rig.resume.save(
        SavedAttempt(
          missionId: mission.id,
          seed: testSeed,
          attemptNumber: 1,
          draftDone: true,
          plays: [SavedPlay(optionId: strongest.id)],
        ),
      );
      await rig.boot(Routes.mission(1), size: realme8);
      await rig.until(find.text(ResumeSheet.title));
      await tester.tap(find.text(ResumeSheet.restart.toUpperCase()));
      await rig.until(find.byType(ChapterTitleCard));
      expect(await rig.resume.load(mission.id), isNull);
      expect(rig.state(1).plays, isEmpty);
    });

    testWidgets('finishing the mission clears what was saved', (tester) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.mission(1), size: realme8);
      await rig.play(
        1,
        beats: [for (final b in mission.beats) b.options.first.id],
        reply: mission.followUps.first.replies.first.id,
      );
      expect(await rig.resume.load(mission.id), isNull);
    });
  });

  test('the guessed slip names the beats', () {
    expect(
      GuessedSlip.line([BeatKind.open]),
      'You picked the open before you could have read the options.',
    );
    expect(
      GuessedSlip.line(BeatKind.values),
      'You picked the open, the evidence and the land before you could have '
      'read the options.',
    );
  });

  group('the saved attempt format', () {
    test('round-trips through JSON', () {
      const saved = SavedAttempt(
        missionId: 'm01_the_opportunity',
        seed: 42,
        attemptNumber: 2,
        draft: 'my words',
        draftDone: true,
        plays: [
          SavedPlay(
            optionId: 'a',
            decidedIn: Duration(milliseconds: 3200),
            reasonId: 'r',
          ),
          SavedPlay(optionId: 'b'),
        ],
      );
      final back = SavedAttempt.fromJson(saved.toJson())!;
      expect(back.missionId, saved.missionId);
      expect(back.seed, 42);
      expect(back.attemptNumber, 2);
      expect(back.draft, 'my words');
      expect(back.plays.first.decidedIn, const Duration(milliseconds: 3200));
      expect(back.plays.first.reasonId, 'r');
      expect(back.plays.last.decidedIn, isNull);
    });

    test('anything malformed starts afresh', () {
      expect(SavedAttempt.fromJson(null), isNull);
      expect(SavedAttempt.fromJson('nope'), isNull);
      expect(SavedAttempt.fromJson({'mission_id': 'x'}), isNull);
      expect(
        SavedAttempt.fromJson({
          'mission_id': 'x',
          'seed': 1,
          'attempt_number': 1,
          'draft_done': false,
          'plays': [
            {'option_id': 3},
          ],
        }),
        isNull,
      );
    });
  });
}

/// Lets the scene's pending beats (the why line, her reaction) play out before a test ends.
const Duration _settle = Duration(seconds: 6);
