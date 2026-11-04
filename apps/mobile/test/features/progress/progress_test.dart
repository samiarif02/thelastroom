import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/debrief/debrief_facts.dart';
import 'package:the_last_room/features/progress/past_result_screen.dart';
import 'package:the_last_room/features/progress/progress_facts.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart' show Tactile;

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
    final report = ProgressReport.of(missions, attempts);

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
    });

    test('nothing played: no average', () {
      final empty = ProgressReport.of(missions, const []);
      expect(empty.done, 0);
      expect(empty.average, isNull);
    });
  });

  group('best gain (pure)', () {
    RoomTotals room(int n, List<int> totals) => (room: n, totals: totals);

    test('no replays: none, and the tile says how to get one', () {
      expect(bestGain(const []), isNull);
      final g = bestGain([
        room(1, [40]),
        room(2, [70]),
        room(3, []),
      ]);
      expect(g, isNull);
      expect(GainWords.value(g), isEmpty);
      expect(GainWords.after(g), 'Replay a room to see your gain');
      expect(
        GainWords.spoken(g),
        'Best gain: none yet. Replay a room to see your gain.',
      );
    });

    test('one replay: its best try against its own first try', () {
      // Room 1 went 40 → 55 → 70 (best 70): +30. Room 8 (another room) never compares.
      final g = bestGain([
        room(1, [40, 55, 70]),
        room(8, [12]),
      ])!;
      expect((g.room, g.points), (1, 30));
      expect(GainWords.value(g), '+30');
      expect(GainWords.after(g), 'on room 1');
      expect(
        GainWords.spoken(g),
        'Best gain: up 30 on room 1, against its first try',
      );
    });

    test('a later dip keeps the best replay', () {
      final g = bestGain([
        room(2, [50, 80, 60]),
      ])!;
      expect(g.points, 30);
    });

    test('the biggest wins; a tie goes to the lower room', () {
      expect(
        bestGain([
          room(3, [60, 70]),
          room(1, [40, 50]),
          room(2, [30, 55]),
        ])!.room,
        2,
      );
      expect(
        bestGain([
          room(4, [40, 60]),
          room(2, [50, 70]),
        ])!.room,
        2,
      );
    });

    test('every replay lower: negative, and never without words', () {
      final g = bestGain([
        room(3, [80, 75]),
        room(5, [70, 50]),
      ])!;
      expect((g.room, g.points), (3, -5));
      expect(GainWords.value(g), '\u22125');
      expect(GainWords.after(g), 'on room 3 vs first try');
      expect(
        GainWords.spoken(g),
        'Best gain: down 5 on room 3, against its first try',
      );
    });

    test('level: zero, said as the same', () {
      final g = bestGain([
        room(6, [64, 64]),
      ])!;
      expect(GainWords.value(g), '0');
      expect(GainWords.after(g), 'on room 6, same as first try');
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
    final report = ProgressReport.of(missions, attempts);
    expect(
      find.bySemanticsLabel(ProgressScreen.roomsLit(2, missions.length)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Average: ${report.average}'), findsOneWidget);
    // Room 1 was replayed: its best replay against its own first try.
    final gain = second.score.total - first.score.total;
    expect(
      find.bySemanticsLabel(
        GainWords.spoken(RoomGain(room: m1.number, points: gain)),
      ),
      findsOneWidget,
    );
    // The radar: each skill averaged over the latest attempts.
    final skills = report.skills!;
    expect(
      find.bySemanticsLabel(
        [for (final d in Dimension.values) '${dimensionLabel(d)} ${skills[d]}']
            .join(', '),
      ),
      findsOneWidget,
    );
    // Each played room: its latest score, its best and its tries, and it opens its result.
    final one = report.missions[0];
    final room = find.byWidgetPredicate(
      (w) =>
          w is Tactile &&
          w.label.startsWith('Room ${m1.number}, ') &&
          w.label.contains(
            'Latest ${second.score.total}, Best ${one.best} · 2 tries',
          ),
    );
    expect(room, findsOneWidget);
    expect(find.text('${second.score.total}'), findsWidgets);
    // The room up next, then the rest of floor 1 locked; floors 2 and 3 fold away.
    expect(find.text(ProgressScreen.upNext), findsOneWidget);
    expect(
      find.text(ProgressScreen.opensAfter(missions[6].number)),
      findsOneWidget,
    );
    await tester.ensureVisible(room);
    await tester.pump();
    await tester.tap(room);
    await rig.until(find.byType(PastResultScreen));
  });

  testWidgets('auto-advance and calm mode switch from the file', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.progress);
    await rig.until(find.byType(ProgressScreen));
    await rig.run(const Duration(seconds: 1));
    final auto = find.bySemanticsLabel(ProgressScreen.autoAdvance);
    await tester.ensureVisible(auto);
    await tester.tap(auto);
    await tester.pump();
    final calm = find.bySemanticsLabel(ProgressScreen.calmMode);
    await tester.ensureVisible(calm);
    await tester.pump();
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
