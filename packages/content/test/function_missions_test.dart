import 'dart:io';

import 'package:content/content.dart';
import 'package:test/test.dart';

/// Issue 74: the `score` functions refuse a mission id that isn't in the content, so the
/// leaderboard can't be farmed with invented rooms. Their list
/// (supabase/functions/score/missions.ts) must match the missions here exactly.
void main() {
  final source = File('../../supabase/functions/score/missions.ts')
      .readAsStringSync();

  Set<String> listed(String name) {
    final block = RegExp('export const $name[^\\[]*\\[([^\\]]*)\\]')
        .firstMatch(source);
    expect(block, isNotNull, reason: '$name is in missions.ts');
    return {
      for (final m in RegExp("'([a-z0-9_]+)'").allMatches(block!.group(1)!))
        m.group(1)!,
    };
  }

  Set<String> ids(AnswerMode mode) => {
    for (final m in gameContent.missions)
      if (m.answerMode == mode) m.id,
  };

  test('the score function knows every choice mission, and only those', () {
    expect(listed('CHOICE_MISSION_IDS'), ids(AnswerMode.choices));
  });

  test(
    'the score-voice function knows every voice mission, and only those',
    () {
      expect(listed('VOICE_MISSION_IDS'), ids(AnswerMode.voice));
    },
  );
}
