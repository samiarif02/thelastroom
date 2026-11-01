import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/debrief/debrief_view.dart';
import 'package:the_last_room/features/mission/mission_player.dart';
import 'package:the_last_room/features/mission/widgets/leave_control.dart';
import 'package:the_last_room/features/mission/widgets/scene_notes.dart';
import 'package:the_last_room/features/progress/chapter_report.dart';
import 'package:the_last_room/features/progress/chapter_report_screen.dart';
import 'package:the_last_room/features/progress/file_trouble.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../mission/mission_harness.dart';

/// Brief 24: Your file shows who scored each mission, the Chapter 1 report, and no dead ends.

/// An attempt at [m] picking option [pick] of every beat (0 is the file's first, usually the
/// strongest line), scored by the engine.
AttemptRecord _attempt(Mission m, int pick, {int number = 1, DateTime? at}) {
  final followUp = m.followUps.firstWhere((f) => f.trigger == null);
  return AttemptRecord(
    missionId: m.id,
    attemptNumber: number,
    seed: testSeed,
    beatOptionIds: [for (final b in m.beats) b.options[pick].id],
    followUpId: followUp.id,
    replyOptionId: followUp.replies[pick].id,
    hinted: m.hinted,
    completedAt: at,
    score: scoreAttempt(
      AttemptInput(
        picks: [
          for (final b in m.beats)
            BeatPick(beat: b.kind, choice: b.options[pick].scored),
        ],
        followUpReply: followUp.replies[pick].scored,
        hinted: m.hinted,
      ),
    ),
  );
}

const Map<String, Object?> _verdict = {
  'model': 'gemini-3.8-flash',
  'overall': {
    'score': 77,
    'basis': 'A clear answer with one concrete project.',
  },
  'dimensions': {
    'relevance': {'score': 80, 'basis': 'r.'},
    'specificity': {'score': 75, 'basis': 's.'},
    'structure': {'score': 70, 'basis': 't.'},
    'adaptability': {'score': 85, 'basis': 'a.'},
  },
};

Future<void> _tapText(MissionRig rig, String text) async {
  final f = find.text(text);
  await rig.until(f);
  await rig.tester.ensureVisible(f);
  await rig.tester.pump();
  await rig.tester.tap(f);
  await rig.tester.pump();
}

void main() {
  final first = missions.first;
  final review = missions.lastWhere((m) => m.chapter == 1);

  group('Your file', () {
    testWidgets(
      'a mission scored by AI says so and shows the AI\'s numbers; others are "Offline score"',
      (tester) async {
        final rig = MissionRig(tester);
        final played = DateTime.utc(2026, 11, 1, 9);
        await rig.progress.recordAttempt(_attempt(first, 0, at: played));
        await rig.progress.recordAttempt(_attempt(missions[1], 0, at: played));
        await rig.aiScores.save(
          SavedAiScore(
            missionId: first.id,
            at: played.add(const Duration(seconds: 5)),
            score: AiScore.fromJson(_verdict)!,
          ),
        );
        await rig.boot(Routes.progress, size: const Size(411, 914));
        await rig.run(const Duration(seconds: 2));
        final aiLabel = find.text(ScoreSourceLabel.aiLabel.toUpperCase());
        final offline = find.text(ScoreSourceLabel.offlineLabel.toUpperCase());
        await tester.ensureVisible(aiLabel);
        expect(aiLabel, findsOneWidget);
        expect(
          find.text('A clear answer with one concrete project.'),
          findsOneWidget,
        );
        await tester.ensureVisible(offline);
        expect(offline, findsOneWidget);
      },
    );

    testWidgets('a verdict older than the latest attempt is not shown for it', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      final scored = DateTime.utc(2026, 11, 1, 9);
      await rig.aiScores.save(
        SavedAiScore(
          missionId: first.id,
          at: scored,
          score: AiScore.fromJson(_verdict)!,
        ),
      );
      await rig.progress.recordAttempt(
        _attempt(first, 1, at: scored.add(const Duration(hours: 1))),
      );
      await rig.boot(Routes.progress, size: const Size(411, 914));
      await rig.run(const Duration(seconds: 2));
      expect(find.text(ScoreSourceLabel.aiLabel.toUpperCase()), findsNothing);
      final offline = find.text(ScoreSourceLabel.offlineLabel.toUpperCase());
      await tester.ensureVisible(offline);
      expect(offline, findsOneWidget);
    });

    testWidgets('the report card says what opens it, then opens it', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.progress, size: const Size(411, 914));
      await rig.run(const Duration(seconds: 1));
      final locked = find.text(ChapterReportScreen.notYetLine(review));
      await tester.ensureVisible(locked);
      expect(locked, findsOneWidget);
    });
  });

  group('the Chapter 1 report', () {
    testWidgets('before the review: what opens it, and the way back', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.report, size: const Size(411, 914));
      await rig.until(find.text(ChapterReportScreen.notYetTitle));
      expect(find.text(ChapterReportScreen.notYetLine(review)), findsOneWidget);
      await _tapText(rig, ChapterReportScreen.backToTower);
      await rig.until(find.byType(TowerScreen));
    });

    testWidgets(
      'first try against the review, skill by skill, honestly; then the waitlist',
      (tester) async {
        final rig = MissionRig(tester);
        // A weak first try, a strong review.
        await rig.progress.recordAttempt(_attempt(first, 2));
        await rig.progress.recordAttempt(_attempt(review, 0));
        await rig.boot(Routes.report, size: const Size(411, 914));
        await rig.until(find.text(ChapterReportScreen.honest));
        final then = _attempt(first, 2).score;
        final now = _attempt(review, 0).score;
        expect(find.text('${then.total}'), findsOneWidget);
        expect(find.text('${now.total}'), findsOneWidget);
        final words = changeWords(
          ScoreDeltaBucket.of(
            compareToBaseline(baseline: then, latest: now).totalDelta,
          ),
        );
        expect(find.text(words), findsWidgets);
        expect(find.byType(SkillRadar), findsNWidgets(2));
        for (final d in Dimension.values) {
          expect(
            find.text('${then.dimensions[d]} → ${now.dimensions[d]}'),
            findsOneWidget,
          );
        }
        expect(
          rig.analytics.events
              .where((e) => e.event == AnalyticsEvent.progressReportViewed)
              .map((e) => e.wire['source']),
          contains('chapterReport'),
        );

        await _tapText(rig, ChapterReportScreen.join);
        await rig.until(find.text(ChapterReportScreen.joined));
        expect(rig.analytics.count(AnalyticsEvent.waitlistJoined), 1);
      },
    );

    testWidgets('a store that won\'t read says so, and tries again', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      rig.progress.failReads = true;
      await rig.boot(Routes.report, size: const Size(411, 914));
      await rig.until(find.text(FileTrouble.title));
      rig.progress.failReads = false;
      await _tapText(rig, FileTrouble.retry);
      await rig.until(find.text(ChapterReportScreen.notYetTitle));
    });

    testWidgets('Your file, too, says so when the store won\'t read', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      rig.progress.failReads = true;
      await rig.boot(Routes.progress, size: const Size(411, 914));
      await rig.until(find.text(FileTrouble.title));
      rig.progress.failReads = false;
      await _tapText(rig, FileTrouble.retry);
      await rig.until(find.text(ChapterReportScreen.notYetLine(review)));
      expect(find.text(FileTrouble.title), findsNothing);
    });

    test('the words never overstate the change', () {
      expect(
        changeWords(ScoreDeltaBucket.of(3)),
        'About the same as your first try',
      );
      expect(
        changeWords(ScoreDeltaBucket.of(-3)),
        'About the same as your first try',
      );
      expect(
        changeWords(ScoreDeltaBucket.of(-12)),
        'Lower than your first try',
      );
      expect(changeWords(ScoreDeltaBucket.of(25)), 'Well up on your first try');
    });
  });

  group('no dead ends', () {
    testWidgets(
      'a room the tower hasn\'t opened says how it opens, and never plays',
      (tester) async {
        final rig = MissionRig(tester);
        await rig.boot(Routes.mission(3));
        await rig.until(find.text('THIS ROOM IS STILL LOCKED'));
        expect(
          find.text('Finish “${missions[1].title}” to open this room.'),
          findsOneWidget,
        );
        expect(find.byType(MissionPlayer), findsNothing);
        await _tapText(rig, 'Back to the tower');
        await rig.until(find.byType(TowerScreen));
      },
    );

    testWidgets('a finished mission plays again as a new attempt', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.progress.recordAttempt(_attempt(first, 0));
      await rig.boot(Routes.mission(1));
      await rig.until(find.byType(MissionPlayer));
      expect(rig.state(1).attemptNumber, 2);
    });

    testWidgets(
      'Mission 7\'s debrief leads to the Chapter 1 report, and the chapter is completed',
      (tester) async {
        final rig = MissionRig(tester);
        await rig.unlockThrough(review.number);
        await rig.boot(Routes.mission(review.number));
        final followUp = review.followUps.firstWhere((f) => f.trigger == null);
        await rig.play(
          review.number,
          beats: [
            for (final b in review.beats)
              b.build?.strongAnswer.id ?? b.options.first.id,
          ],
          reply: followUp.replies.first.id,
        );
        await rig.settleDossier();
        expect(
          rig.analytics.only(AnalyticsEvent.chapterCompleted).wire['chapter'],
          1,
        );
        await _tapText(rig, DebriefView.reportLabel);
        await rig.until(find.text(ChapterReportScreen.honest));
      },
    );

    testWidgets(
      'the leave sheet is in the vivid look, and Android\'s back opens it',
      (tester) async {
        final rig = MissionRig(tester);
        await rig.boot(Routes.mission(1));
        await rig.playLines(1);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(LeaveSheet), findsOneWidget);
        expect(find.byType(VividButton), findsNWidgets(2));
        await tester.tap(find.text(LeaveSheet.resume));
        await tester.pump();
        expect(find.byType(LeaveSheet), findsNothing);
      },
    );

    testWidgets('without a back button, the × leaves the scene for the tower', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.mission(1));
      await rig.playLines(1);
      await tester.tap(find.bySemanticsLabel(LeaveControl.label));
      await tester.pump();
      await tester.tap(find.text(LeaveSheet.leave));
      await rig.until(find.byType(TowerScreen));
    });
  });
}
