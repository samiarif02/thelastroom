import 'dart:convert';
import 'dart:io';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/progress/attempt_score.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';

/// The evaluation set for the AI recruiter (brief 36, `docs/scoring-eval.md`): for every
/// Chapter 1 mission, a strong, a weak and a guessed answer, built from the content's own lines.
/// Each case is exactly the request the app sends (`ScoreRequest.toJson`) plus the engine's
/// score for the same play and the band the content's author intends.
///
/// The committed file must equal what this builds, so the eval can never test answers the app
/// wouldn't send. To rebuild it after a content change:
/// `UPDATE_SCORE_EVAL=1 flutter test test/features/debrief/score_eval_cases_test.dart`.
void main() {
  const path = '../../supabase/eval/score/cases.json';

  test('the eval cases are what the app would send', () {
    final built = const JsonEncoder.withIndent('  ').convert(buildCases());
    final file = File(path);
    if (Platform.environment['UPDATE_SCORE_EVAL'] == '1') {
      file.writeAsStringSync('$built\n');
    }
    expect(file.readAsStringSync(), '$built\n');
  });
}

/// What the content's author intends each kind of answer to score, overall.
const Map<String, List<int>> expectedBands = {
  'strong': [70, 100],
  'weak': [0, 50],
  'guessed': [0, 50],
};

/// Picking a line faster than this is a guess (the engine's threshold), so a guessed case
/// decides in half of it; a considered one takes a few seconds.
const Duration _considered = Duration(seconds: 5);
const Duration _guessed = Duration(milliseconds: 500);

List<Map<String, Object?>> buildCases() => [
  // The published evaluation covers Chapter 1 (docs/scoring-eval.md).
  for (final mission in missions.where(
    (m) => m.chapter == 1 && m.answerMode == AnswerMode.choices,
  ))
    for (final kind in expectedBands.keys) _case(mission, kind),
];

Map<String, Object?> _case(Mission mission, String kind) {
  final strong = kind != 'weak';
  final plays = <BeatPlay>[];
  for (final beat in mission.beats) {
    final option = _line(beat, strong: strong);
    plays.add(
      BeatPlay(
        option: option,
        decidedIn: kind == 'guessed' ? _guessed : _considered,
        reason: kind == 'guessed' ? null : _reason(beat, option, sound: strong),
      ),
    );
  }
  final followUp = mission.followUpById(
    selectFollowUp(
      picks: [
        for (var i = 0; i < plays.length; i++) plays[i].pick(mission.beats[i]),
      ],
      candidates: [for (final f in mission.followUps) f.candidate],
    ),
  );
  final reply = _best(followUp.replies, replyDimensions, best: strong);
  final engine = scoreFromPicks(
    missionId: mission.id,
    beatOptionIds: [for (final p in plays) p.option.id],
    followUpId: followUp.id,
    replyOptionId: reply.id,
    hinted: mission.hinted,
    beatPlays: [
      for (final p in plays)
        BeatPlayRecord(reasonId: p.reason?.id, decidedIn: p.decidedIn),
    ],
  );
  return {
    'id': '${mission.id}_$kind',
    'mission_id': mission.id,
    'kind': kind,
    'expected_overall': expectedBands[kind],
    'engine_total': engine?.total,
    'request': ScoreRequest(
      mission: mission,
      plays: plays,
      followUp: followUp,
      reply: reply,
    ).toJson(),
  };
}

/// The strongest line of [beat], or its weakest; a build beat is built right, or reversed
/// with a decoy in front.
AnswerOption _line(Beat beat, {required bool strong}) {
  final build = beat.build;
  if (build != null) {
    final parts = [for (final p in build.parts) p.id];
    return build.answerFor(
      strong ? parts : [build.decoys.first.id, ...parts.reversed.skip(1)],
    );
  }
  return _best(beat.options, beatDimensions, best: strong);
}

AnswerOption _best(
  List<AnswerOption> options,
  Set<Dimension> counted, {
  required bool best,
}) {
  int shortfall(AnswerOption o) => weightedShortfall(o.scored, counted);
  final sorted = [...options]
    ..sort((a, b) => shortfall(a).compareTo(shortfall(b)));
  return best ? sorted.first : sorted.last;
}

/// The principle that really explains [option], or a tempting wrong one.
Reason? _reason(Beat beat, AnswerOption option, {required bool sound}) {
  final reasons = beat.why?.reasons;
  if (reasons == null || reasons.isEmpty) return null;
  return reasons.firstWhere(
    (r) => r.isSoundFor(option.id) == sound,
    orElse: () => reasons.first,
  );
}
