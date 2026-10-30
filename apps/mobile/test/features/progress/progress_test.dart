import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/debrief/debrief_facts.dart';
import 'package:the_last_room/features/progress/progress_facts.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';

import '../mission/mission_harness.dart';
import '../tower/played_attempt.dart';

void main() {
  final m1 = missions[0];
  final m2 = missions[1];
  final first = playedAttempt(m1, pick: 2);
  final second = playedAttempt(m1, attempt: 2);
  final other = playedAttempt(m2, pick: 1);
  final attempts = [first, second, other];

  group('report (pure)', () {
    final report = ProgressReport.of(missions, attempts, first);

    test(
      'per mission: best, latest, dimensions and attempts are the engine\'s',
      () {
        final one = report.missions[0];
        expect(one.attemptCount, 2);
        expect(
          one.best,
          [
            first.score.total,
            second.score.total,
          ].reduce((a, b) => a > b ? a : b),
        );
        expect(one.latest, same(second.score));
        expect(one.lessonToWorkOn, DebriefFacts.of(m1, second.score).lesson);
        expect(report.missions[2].played, isFalse);
      },
    );

    test('the Chapter 1 summary', () {
      expect(report.done, 2);
      expect(report.total, missions.length);
      final bests = [report.missions[0].best!, other.score.total];
      expect(report.average, ((bests[0] + bests[1]) / 2).round());
      expect(
        report.sinceBaseline!.totalDelta,
        compareToBaseline(
          baseline: first.score,
          latest: other.score,
        ).totalDelta,
      );
    });

    test('nothing played: no average, no change', () {
      final empty = ProgressReport.of(missions, const [], null);
      expect(empty.done, 0);
      expect(empty.average, isNull);
      expect(empty.sinceBaseline, isNull);
    });
  });

  testWidgets('the screen shows the stored attempts\' numbers', (tester) async {
    final rig = MissionRig(tester);
    for (final a in attempts) {
      await rig.progress.recordAttempt(a);
    }
    await rig.boot(Routes.progress);
    await rig.until(find.byType(ProgressScreen));
    await rig.run(const Duration(milliseconds: 300));
    final report = ProgressReport.of(missions, attempts, first);
    expect(find.bySemanticsLabel('MISSIONS DONE: 2 of 7'), findsOneWidget);
    expect(find.bySemanticsLabel('AVERAGE: ${report.average}'), findsOneWidget);
    final delta = report.sinceBaseline!.totalDelta;
    expect(
      find.bySemanticsLabel(
        'SINCE MISSION 1: ${delta > 0 ? '+$delta' : delta}',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('BEST ${report.missions[0].best}'),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel('LATEST ${second.score.total}'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('ATTEMPTS 2'), findsOneWidget);
    for (final d in Dimension.values) {
      expect(
        find.bySemanticsLabel(
          '${dimensionLabel(d).toUpperCase()} ${second.score.dimensions[d]}',
        ),
        findsWidgets,
      );
    }
    expect(find.text(ProgressScreen.notPlayed), findsNWidgets(5));
  });

  testWidgets('auto-advance and calm mode switch from the file', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.progress);
    await rig.until(find.byType(ProgressScreen));
    final auto = find.bySemanticsLabel(ProgressScreen.autoAdvance);
    await tester.ensureVisible(auto);
    await tester.tap(auto);
    await tester.pump();
    final calm = find.bySemanticsLabel(ProgressScreen.calmMode);
    await tester.tap(calm);
    await tester.pump();
    final saved = await rig.profile.load();
    expect(saved.autoAdvance, isFalse);
    expect(saved.calmMode, isTrue);
  });

  for (final (scale, still) in [(2.0, false), (2.0, true)]) {
    testWidgets('the file survives ${scale}x text, reduced motion: $still', (
      tester,
    ) async {
      final rig = MissionRig(tester);
      for (final a in attempts) {
        await rig.progress.recordAttempt(a);
      }
      await rig.boot(Routes.progress, textScale: scale, reduceMotion: still);
      await rig.until(find.byType(ProgressScreen));
      await rig.run(const Duration(seconds: 1));
    });
  }
}
