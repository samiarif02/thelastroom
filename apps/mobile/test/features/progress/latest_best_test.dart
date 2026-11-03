import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/progress/past_result_screen.dart';
import 'package:the_last_room/features/progress/progress_facts.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';

import '../mission/mission_harness.dart';

/// QA 51, BUG-4: Your file showed "Latest" from the AI and "Best" from the game, so one try read
/// "Best 85 · 1 try" beside a latest of 90. Both now read the score each try was shown with.
void main() {
  final room = missions.first;
  final played = DateTime.utc(2026, 11, 1, 9);

  AttemptRecord attempt(int pick, {int number = 1, DateTime? at}) {
    final followUp = room.followUps.firstWhere((f) => f.trigger == null);
    return AttemptRecord(
      missionId: room.id,
      attemptNumber: number,
      seed: testSeed,
      beatOptionIds: [for (final b in room.beats) b.options[pick].id],
      followUpId: followUp.id,
      replyOptionId: followUp.replies[pick].id,
      hinted: room.hinted,
      completedAt: at ?? played,
      score: scoreAttempt(
        AttemptInput(
          picks: [
            for (final b in room.beats)
              BeatPick(beat: b.kind, choice: b.options[pick].scored),
          ],
          followUpReply: followUp.replies[pick].scored,
          hinted: room.hinted,
        ),
      ),
    );
  }

  SavedAiScore verdict(int overall, int each) => SavedAiScore(
    missionId: room.id,
    at: played.add(const Duration(seconds: 5)),
    score: AiScore.fromJson({
      'model': 'gemini-test',
      'overall': {'score': overall, 'basis': 'o.'},
      'dimensions': {
        for (final d in Dimension.values)
          d.name: {'score': each, 'basis': 'd.'},
      },
    })!,
  );

  // Weaker lines (every beat and reply has at least three), so the AI can score above the game.
  const weakPick = 2;

  group('shownTotals', () {
    test('one try scored by the AI: latest and best are the AI\'s', () {
      final line = MissionProgress(
        mission: room,
        attempts: [attempt(weakPick)],
      );
      final engine = line.latest!.total;
      final ai = verdict(engine + 10, 50);
      expect(shownTotals(line, ai), (latest: engine + 10, best: engine + 10));
    });

    test('one try, the AI lower than the game: still one number', () {
      final line = MissionProgress(mission: room, attempts: [attempt(0)]);
      final ai = verdict(line.latest!.total - 10, 50);
      final shown = shownTotals(line, ai);
      expect(shown.best, shown.latest);
    });

    test('an earlier, better offline try is still the best', () {
      final line = MissionProgress(
        mission: room,
        attempts: [attempt(0), attempt(weakPick, number: 2)],
      );
      final earlier = line.attempts.first.score.total;
      final ai = verdict(earlier - 5, 50);
      expect(shownTotals(line, ai), (latest: earlier - 5, best: earlier));
    });

    test('no AI: the game\'s own numbers, as before', () {
      final line = MissionProgress(
        mission: room,
        attempts: [attempt(0), attempt(weakPick, number: 2)],
      );
      expect(shownTotals(line, null), (
        latest: line.latest!.total,
        best: line.best,
      ));
    });
  });

  test('a past result\'s best is never below what the latest shows', () {
    final result = PastResult(
      mission: room,
      attempts: [attempt(weakPick)],
      ai: verdict(95, 95),
    );
    for (final d in Dimension.values) {
      expect(result.best[d], greaterThanOrEqualTo(result.shown[d]!));
      expect(result.best[d], 95);
    }
  });

  testWidgets('Your file: one AI-scored try reads its own score as the best', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    final only = attempt(weakPick);
    await rig.progress.recordAttempt(only);
    final ai = only.score.total + 10;
    await rig.aiScores.save(verdict(ai, 50));
    await rig.boot(Routes.progress, size: const Size(411, 914));
    await rig.run(const Duration(seconds: 2));
    final meta = find.text('Best $ai · ${ProgressScreen.tries(1)}');
    await tester.ensureVisible(meta);
    expect(meta, findsOneWidget);
    expect(find.text('$ai'), findsOneWidget);
    expect(
      find.textContaining('Best ${only.score.total} '),
      findsNothing,
      reason: "the game's score never stands as the best beside the AI's",
    );
  });
}
