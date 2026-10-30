import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';

AttemptRecord _attempt(String missionId, int n, int total) => AttemptRecord(
  missionId: missionId,
  attemptNumber: n,
  seed: n,
  beatOptionIds: const ['a', 'b', 'c'],
  followUpId: 'f',
  replyOptionId: 'r',
  hinted: false,
  score: MissionScore(
    dimensions: {for (final d in Dimension.values) d: total},
    total: total,
    optionIdsByCost: const ['a', 'b', 'c', 'r'],
    flags: const {},
  ),
);

void main() {
  test('attempts come back oldest first, filtered by mission', () async {
    final repo = InMemoryProgressRepository(baselineMissionId: 'm1');
    await repo.recordAttempt(_attempt('m1', 1, 40));
    await repo.recordAttempt(_attempt('m2', 1, 50));
    await repo.recordAttempt(_attempt('m1', 2, 60));
    expect((await repo.attempts()).map((a) => a.score.total), [40, 50, 60]);
    expect((await repo.attempts(missionId: 'm1')).map((a) => a.attemptNumber), [
      1,
      2,
    ]);
  });

  test(
    'the baseline is the first attempt at the baseline mission, for good',
    () async {
      final repo = InMemoryProgressRepository(baselineMissionId: 'm1');
      expect(await repo.baseline(), isNull);
      await repo.recordAttempt(_attempt('m2', 1, 90));
      expect(await repo.baseline(), isNull);
      await repo.recordAttempt(_attempt('m1', 1, 40));
      await repo.recordAttempt(_attempt('m1', 2, 80));
      expect((await repo.baseline())!.score.total, 40);
    },
  );

  test('the default baseline mission is the content\'s', () async {
    final repo = InMemoryProgressRepository();
    await repo.recordAttempt(_attempt('m01_the_opportunity', 1, 55));
    expect((await repo.baseline())!.score.total, 55);
  });

  test('the list handed out can\'t change the store', () async {
    final repo = InMemoryProgressRepository(baselineMissionId: 'm1');
    await repo.recordAttempt(_attempt('m1', 1, 40));
    final list = await repo.attempts();
    expect(() => list.add(_attempt('m1', 2, 1)), throwsUnsupportedError);
  });
}
