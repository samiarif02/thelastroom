import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

/// Brief 37's checks over Chapter 2, "Under Pressure": seven voice missions, titled as the
/// tower teases them, each listening for points a player can tick and teaching a lesson.
void main() {
  final chapterTwo = gameContent.chapters.singleWhere((c) => c.number == 2);
  final lessonsById = {for (final l in gameContent.lessons) l.id: l};

  test(
    'Chapter 2 is Missions 8–14, in order, titled as the tower teases them',
    () {
      expect(
        [for (final m in chapterTwoMissions) m.number],
        [8, 9, 10, 11, 12, 13, 14],
      );
      expect(chapterTwoMissions.every((m) => m.chapter == 2), isTrue);
      expect([
        for (final m in chapterTwoMissions) m.title,
      ], chapterTwo.missionTitles);
    },
  );

  test('Chapter 2 validates as a playable chapter, after Chapter 1', () {
    final flipped = ContentBundle(
      chapters: [
        for (final c in gameContent.chapters)
          c.number == 2
              ? Chapter(
                  number: c.number,
                  title: c.title,
                  missionTitles: c.missionTitles,
                  playable: true,
                )
              : c,
      ],
      interviewers: gameContent.interviewers,
      lessons: gameContent.lessons,
      missions: [
        ...gameContent.missions.where((m) => m.chapter == 1),
        ...chapterTwoMissions,
        ...gameContent.missions.where((m) => m.chapter > 2),
      ],
    );
    expect(validateContent(flipped), isEmpty);
  });

  // The voice player (brief 35) is in, so Chapter 2 is open and played (brief 39).
  test('Chapter 2 is open, and its missions are in the game', () {
    expect(chapterTwo.playable, isTrue);
    expect(
      [for (final m in gameContent.missions.where((m) => m.chapter == 2)) m.id],
      [for (final m in chapterTwoMissions) m.id],
    );
  });

  test('every Chapter 2 mission is answered by voice: no beats, no option follow-ups', () {
    for (final mission in chapterTwoMissions) {
      expect(mission.answerMode, AnswerMode.voice, reason: mission.id);
      expect(mission.voice, isNotNull, reason: mission.id);
      expect(mission.beats, isEmpty, reason: mission.id);
      expect(mission.followUps, isEmpty, reason: mission.id);
      // A voice mission has no hint cards to offer.
      expect(mission.hinted, isFalse, reason: mission.id);
    }
  });

  test('each interviewer runs the missions brief 37 gives them', () {
    const expected = {
      8: {lenaId},
      9: {marcusId},
      10: {lenaId},
      11: {marcusId},
      12: {priyaId},
      13: {lenaId},
      14: {marcusId, lenaId},
    };
    for (final mission in chapterTwoMissions) {
      final speakers = {
        for (final line in mission.scene) line.speakerId,
        mission.question.speakerId,
        mission.voice!.followUp.speakerId,
      };
      expect(speakers, expected[mission.number], reason: mission.id);
    }
  });

  test(
    'Panel Review is the chapter review: two interviewers, Conflict Navigator',
    () {
      const review = missionPanelReview;
      expect(review.number, 14);
      expect(review.hinted, isFalse);
      expect({
        for (final line in review.scene) line.speakerId,
        review.question.speakerId,
        review.voice!.followUp.speakerId,
      }, hasLength(2));
      expect(
        [for (final r in review.skillRequirements) r.skill],
        [Skill.conflictNavigator],
      );
    },
  );

  for (final mission in chapterTwoMissions) {
    group(mission.id, () {
      final voice = mission.voice!;
      final points = [...voice.listenFor, ...voice.followUpListenFor];

      test('says what it practises', () {
        expect(mission.practises, isNotNull);
        expect(mission.practises, endsWith('.'));
      });

      test('listens for 3–4 points on at least three dimensions', () {
        expect(voice.listenFor.length, inInclusiveRange(3, 4));
        expect(
          {for (final p in voice.listenFor) p.dimension}.length,
          greaterThanOrEqualTo(3),
        );
      });

      test('the follow-up listens for 1–3 points, adaptability among them', () {
        expect(voice.followUpListenFor.length, inInclusiveRange(1, 3));
        expect(
          voice.followUpListenFor.map((p) => p.dimension),
          contains(Dimension.adaptability),
        );
        // Question and reply together earn on all four dimensions.
        expect({for (final p in points) p.dimension}, Dimension.values.toSet());
      });

      test('every point reads as a checklist item: what the answer does', () {
        for (final point in points) {
          expect(
            point.text,
            matches(RegExp(r'^[A-Z][a-z]+s ')),
            reason: point.id,
          );
          expect(point.text, endsWith('.'), reason: point.id);
          expect(
            wordCount(point.text),
            lessThanOrEqualTo(maxOptionWords),
            reason: point.id,
          );
        }
      });

      test('invites the player\'s own story, or the practice CV', () {
        final setup = [
          for (final line in mission.scene) line.text,
          mission.question.text,
        ].join(' ');
        expect(setup, contains('own'));
        expect(setup, contains('practice CV'));
        expect(setup, isNot(contains(player.name.split(' ').first)));
      });

      test('ids carry the mission prefix', () {
        final prefix = '${mission.id.substring(0, 3)}_';
        for (final point in points) {
          expect(point.id, startsWith(prefix));
        }
      });

      test('teaches a lesson with a recall check', () {
        final lesson = lessonsById[voice.lessonId];
        expect(lesson, isNotNull, reason: voice.lessonId);
        expect(lesson!.recall.options.length, greaterThanOrEqualTo(3));
      });

      test('quotes no figure outside the character sheet', () {
        final figure = RegExp(r'\d[\d,.]*%?');
        final text = [
          mission.practises ?? '',
          for (final line in mission.scene) line.text,
          mission.question.text,
          voice.followUp.text,
          for (final p in points) p.text,
        ].join(' ');
        for (final match in figure.allMatches(text)) {
          expect(player.figures, contains(match[0]), reason: mission.id);
        }
      });
    });
  }
}
