import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/voice/voice_debrief.dart';

/// Brief 44's playthrough note, fixed without touching the dossier's look (brief 46): on a
/// voice mission the red pen's margin note (the lesson) and its underline never point at
/// different dimensions, and a run with nothing missed gets no correction.
void main() {
  final voiced = [
    for (final m in missions)
      if (m.answerMode == AnswerMode.voice) m,
  ];

  List<ListenFor> pointsOf(Mission m) => [
    ...m.voice!.listenFor,
    ...m.voice!.followUpListenFor,
  ];

  test('the note only ever sits beside its own dimension', () {
    for (final m in voiced) {
      final lesson = lessonById(m.voice!.lessonId)!;
      final points = pointsOf(m);
      // Every way of missing exactly one point.
      for (final missed in points) {
        final made = {
          for (final p in points)
            if (p != missed) p.id,
        };
        final pen = voiceRedPen(
          mission: m,
          byCost: [missed.id, ...made],
          made: made,
        );
        expect(pen.marked, Dimension.values.indexOf(missed.dimension));
        if (pen.note != null) {
          expect(pen.note, lesson.title);
          expect(
            pen.marked,
            Dimension.values.indexOf(lesson.flag.lowers),
            reason: '${m.id}: the note and the underline agree',
          );
        }
      }
    }
  });

  test('a missed point on the lesson\'s dimension takes the pen', () {
    for (final m in voiced) {
      final lesson = lessonById(m.voice!.lessonId)!;
      final points = pointsOf(m);
      final onLesson = points
          .where((p) => p.dimension == lesson.flag.lowers)
          .toList();
      final other = points
          .where((p) => p.dimension != lesson.flag.lowers)
          .toList();
      if (onLesson.isEmpty || other.isEmpty) continue;
      // The costliest miss is elsewhere, but a lesson point was missed too.
      final made = {
        for (final p in points)
          if (p != onLesson.first && p != other.first) p.id,
      };
      final pen = voiceRedPen(
        mission: m,
        byCost: [other.first.id, onLesson.first.id, ...made],
        made: made,
      );
      expect(pen.marked, Dimension.values.indexOf(lesson.flag.lowers));
      expect(pen.note, lesson.title);
    }
  });

  test('nothing missed: no underline and no note', () {
    for (final m in voiced) {
      final made = {for (final p in pointsOf(m)) p.id};
      final pen = voiceRedPen(mission: m, byCost: [...made], made: made);
      expect(pen.marked, isNull);
      expect(pen.note, isNull);
    }
  });
}
