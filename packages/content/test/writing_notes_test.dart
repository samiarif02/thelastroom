import 'package:content/content.dart';
import 'package:test/test.dart';

import 'paths.dart';

/// The owner's writing notes (2026-10-30) as checks over every shipped mission, so a new line
/// that breaks one fails CI instead of a review.
void main() {
  /// Within a set, the shortest line is at least this share of the longest (note 2: "within
  /// about ±20 % of each other's length"), so length gives nothing away.
  const minLengthRatio = 0.8;

  /// At most this share of a mission's sets may have the best line as the longest (note 2).
  const maxBestIsLongestShare = 1 / 3;

  final textOf = {
    for (final o in gameContent.missions.expand(allOptions)) o.id: o.text,
  };

  bool closeInLength(List<String> texts) {
    final lengths = texts.map((t) => t.length);
    return lengths.reduce((a, b) => a < b ? a : b) >=
        minLengthRatio * lengths.reduce((a, b) => a > b ? a : b);
  }

  bool isLongest(String text, List<String> texts) =>
      texts.every((t) => t.length <= text.length);

  for (final mission in gameContent.missions) {
    group(mission.id, () {
      final sets = optionSets(mission);

      test('every line is at most $maxOptionWords words (note 4)', () {
        for (final option in allOptions(mission)) {
          expect(
            wordCount(option.text),
            lessThanOrEqualTo(maxOptionWords),
            reason: option.id,
          );
        }
      });

      test('lines in a set are within 20 % of each other in length (note 2)', () {
        for (final options in sets) {
          final texts = [for (final o in options) o.text];
          expect(
            closeInLength(texts),
            isTrue,
            reason:
                '${options.first.id}…: ${[for (final t in texts) t.length]} characters',
          );
        }
      });

      test(
        'the best line is the longest in at most a third of the sets (note 2)',
        () {
          final bestIsLongest = sets.where((options) {
            final best = options.singleWhere((o) => o.flags.isEmpty);
            return isLongest(best.text, [for (final o in options) o.text]);
          }).length;
          expect(
            bestIsLongest,
            lessThanOrEqualTo(sets.length * maxBestIsLongestShare),
          );
        },
      );

      test('every set has one unflagged best line that outscores the rest', () {
        for (final options in sets) {
          final unflagged = options.where((o) => o.flags.isEmpty).toList();
          expect(unflagged, hasLength(1), reason: options.first.id);
          for (final distractor in options.where((o) => o.flags.isNotEmpty)) {
            expect(
              pointsOf(distractor),
              lessThan(pointsOf(unflagged.single)),
              reason: distractor.id,
            );
          }
        }
      });

      test(
        'ids carry the mission prefix and no screen-order hint (note 7)',
        () {
          final prefix = '${mission.id.substring(0, 3)}_';
          expect(mission.id, matches(RegExp(r'^m\d\d_')));
          final orderHint = RegExp(
            r'_(a|b|c|d|best|worst|good|bad|strong|weak|right|wrong|correct)(_|$)',
          );
          for (final id in [
            for (final o in allOptions(mission)) o.id,
            for (final f in mission.followUps) f.id,
          ]) {
            expect(id, startsWith(prefix));
            expect(id, isNot(contains(orderHint)), reason: id);
          }
        },
      );

      test('the lines draw on the character sheet (note 3)', () {
        final text = [for (final o in allOptions(mission)) o.text]
            .join(' ')
            .toLowerCase();
        final used = player.facts.where(
          (f) => f.markers.any((m) => text.contains(m.toLowerCase())),
        );
        expect(used, isNotEmpty);
      });
    });
  }

  test('every figure a line quotes is on the character sheet (note 3)', () {
    final figure = RegExp(r'\d[\d,.]*%?');
    for (final MapEntry(key: id, value: text) in textOf.entries) {
      for (final match in figure.allMatches(text)) {
        expect(
          player.figures,
          contains(match[0]),
          reason: '$id quotes ${match[0]}',
        );
      }
    }
  });

  test('every lesson is taught by some line', () {
    final taught = {
      for (final o in gameContent.missions.expand(allOptions)) o.lessonId,
    };
    for (final lesson in gameContent.lessons) {
      expect(taught, contains(lesson.id), reason: lesson.id);
    }
  });

  test('every lesson names its hidden flaw in one sentence (note 6)', () {
    for (final lesson in gameContent.lessons) {
      expect(
        RegExp(r'[.!?]').allMatches(lesson.flaw),
        hasLength(1),
        reason: lesson.id,
      );
      expect(lesson.flaw, endsWith('.'), reason: lesson.id);
    }
  });

  test(
    'recall options are close in length, and the answer is rarely the longest',
    () {
      var answerIsLongest = 0;
      for (final lesson in gameContent.lessons) {
        final texts = [for (final o in lesson.recall.options) o.text];
        expect(closeInLength(texts), isTrue, reason: lesson.id);
        final answer = lesson.recall.options.singleWhere(
          (o) => o.id == lesson.recall.correctOptionId,
        );
        if (isLongest(answer.text, texts)) answerIsLongest++;
      }
      expect(
        answerIsLongest,
        lessThanOrEqualTo(gameContent.lessons.length * maxBestIsLongestShare),
      );
    },
  );

  test('the draft prompt asks for the player\'s own words about themselves (note 3)', () {
    expect(draftPrompt, contains('your own words'));
    expect(draftPrompt, contains('yourself'));
    expect(player.premise, contains('You play ${player.name}'));
  });
}
