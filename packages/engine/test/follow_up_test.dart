import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const candidates = [
    FollowUpCandidate(id: 'f_default'),
    FollowUpCandidate(id: 'f_we', trigger: Flag.weNotI),
    FollowUpCandidate(id: 'f_vague', trigger: Flag.vague),
    FollowUpCandidate(id: 'f_blame', trigger: Flag.blame),
  ];
  String select(List<ScoredChoice> beats, {List<FollowUpCandidate>? from}) =>
      selectFollowUp(picks: beatsOf(beats), candidates: from ?? candidates);

  test('answers a flag on the weakest pick', () {
    expect(
      select([
        line('o', 3, 3, 3),
        line('e', 2, 1, 2, 0, {Flag.weNotI}),
        line('l', 3, 3, 2),
      ]),
      'f_we',
    );
  });

  test(
    'moves to the next weakest pick when the weakest has no matching flag',
    () {
      // The land beat is weakest but its flag (rambling) has no follow-up here.
      expect(
        select([
          line('o', 3, 3, 3),
          line('e', 3, 1, 3, 0, {Flag.vague}),
          line('l', 1, 1, 1, 0, {Flag.rambling}),
        ]),
        'f_vague',
      );
    },
  );

  test('asks the default when no pick has a flag', () {
    expect(
      select([line('o', 2, 2, 2), line('e', 1, 1, 1), line('l', 3, 3, 3)]),
      'f_default',
    );
  });

  test('two picks equally weak: the earlier beat wins', () {
    expect(
      select([
        line('o', 3, 3, 3),
        line('e', 2, 1, 2, 0, {Flag.blame}),
        line('l', 2, 1, 2, 0, {Flag.vague}),
      ]),
      'f_blame',
    );
  });

  test('weakness is weighted: a specificity point costs more than a relevance point', () {
    // Open loses 1 relevance (25); evidence loses 1 specificity (30), so evidence is weaker.
    expect(
      select(
        [
          line('o', 2, 3, 3, 0, {Flag.offQuestion}),
          line('e', 3, 2, 3, 0, {Flag.vague}),
          line('l', 3, 3, 3),
        ],
        from: [
          ...candidates,
          const FollowUpCandidate(id: 'f_off', trigger: Flag.offQuestion),
        ],
      ),
      'f_vague',
    );
  });

  test('a pick with two answered flags: the candidate listed first wins', () {
    expect(
      select([
        line('o', 3, 3, 3),
        line('e', 2, 0, 2, 0, {Flag.vague, Flag.weNotI}),
        line('l', 3, 3, 3),
      ]),
      'f_we',
    );
  });

  test('throws when nothing matches and there is no default', () {
    expect(
      () => select([
        line('o', 2, 2, 2),
        line('e', 2, 2, 2),
        line('l', 2, 2, 2),
      ], from: candidates.where((c) => c.trigger != null).toList()),
      throwsStateError,
    );
  });
}
