import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  final base = fixture.missions.single;

  /// The fixture with its one mission rebuilt, so each test breaks exactly one rule.
  ContentBundle withMission({
    List<Beat>? beats,
    List<FollowUp>? followUps,
    bool? hinted,
    bool? timed,
    List<SceneLine>? scene,
  }) => ContentBundle(
    interviewers: fixture.interviewers,
    lessons: fixture.lessons,
    missions: [
      Mission(
        id: base.id,
        chapter: base.chapter,
        number: base.number,
        title: base.title,
        scene: scene ?? base.scene,
        question: base.question,
        beats: beats ?? base.beats,
        followUps: followUps ?? base.followUps,
        hinted: hinted ?? base.hinted,
        timed: timed ?? base.timed,
        isBaseline: base.isBaseline,
        skillRequirements: base.skillRequirements,
      ),
    ],
  );

  AnswerOption option(
    String id, {
    int score = 2,
    Set<Flag> flags = const {},
    String? lessonId,
    String text = 'A line.',
  }) => AnswerOption(
    id: id,
    text: text,
    scores: DimensionScores(
      relevance: score,
      specificity: score,
      structure: score,
      adaptability: score,
    ),
    flags: flags,
    lessonId: lessonId,
  );

  List<String> problems(ContentBundle bundle) =>
      validateContent(bundle).map((i) => i.toString()).toList();

  test('the content schema version is positive', () {
    expect(contentSchemaVersion, greaterThan(0));
  });

  test('the fixture is valid', () {
    expect(problems(fixture), isEmpty);
  });

  test('ids must be unique', () {
    final beats = [...base.beats];
    beats[2] = Beat(
      kind: BeatKind.land,
      options: [option('o1'), option('l2'), option('l3')],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('o1: id is used more than once'),
    );
  });

  test('ids must be snake_case, so they are safe to send as analytics ids', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [option('Open One'), option('o2'), option('o3')],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('Open One: id is not snake_case'),
    );
  });

  test('every dimension score is within 0–3', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [option('o1', score: 4), option('o2'), option('o3')],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('o1: a dimension score is outside 0–3'),
    );
  });

  test('a flag caps the dimension it lowers', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [
        option('o1', score: 3, flags: {Flag.vague}),
        option('o2'),
        option('o3'),
      ],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('o1: flagged vague but scores above 1 on specificity'),
    );
  });

  test('beats are open, evidence, land, with 3–4 options each', () {
    final reversed = base.beats.reversed.toList();
    expect(
      problems(withMission(beats: reversed)),
      contains('m_fixture: beats must be open, evidence, land, in that order'),
    );
    final beats = [...base.beats];
    beats[1] = Beat(
      kind: BeatKind.evidence,
      options: [option('e1'), option('e2')],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('m_fixture evidence beat: has 2 options, needs 3–4'),
    );
  });

  test('a mission has exactly one default follow-up', () {
    final noDefault = base.followUps.where((f) => f.trigger != null).toList();
    expect(
      problems(withMission(followUps: noDefault)),
      contains('m_fixture: needs exactly one default follow-up, has 0'),
    );
  });

  test('references to lessons and speakers resolve', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [
        option('o1', lessonId: 'lesson_missing'),
        option('o2'),
        option('o3'),
      ],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('o1: lesson lesson_missing does not exist'),
    );
    expect(
      problems(
        withMission(
          scene: const [SceneLine(speakerId: 'nobody', text: 'Hi.')],
        ),
      ),
      contains('m_fixture: speaker nobody is not an interviewer'),
    );
  });

  test('a hinted mission cannot unlock a skill', () {
    expect(
      problems(withMission(hinted: true)),
      contains('m_fixture: a hinted mission can never unlock a skill'),
    );
  });

  test('the baseline is unhinted and untimed', () {
    const issue = 'm_fixture: the baseline must be unhinted and untimed';
    expect(problems(withMission(timed: true)), contains(issue));
    expect(problems(withMission(hinted: true)), contains(issue));
  });

  test('a flagged option must teach a lesson', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [
        option('o1', score: 1, flags: {Flag.vague}),
        option('o2'),
        option('o3'),
      ],
    );
    expect(
      problems(withMission(beats: beats)),
      contains('o1: is flagged but teaches no lesson'),
    );
  });

  test('an option exposes only points and flags to the engine', () {
    final weak = base.beats.first.options[1];
    expect(weak.scored.optionId, weak.id);
    expect(weak.scored.flags, {Flag.weNotI, Flag.vague});
  });

  test('an answer line is at most $maxOptionWords words (writing note 4)', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [
        option('o1', text: List.filled(maxOptionWords + 1, 'word').join(' ')),
        option('o2', text: List.filled(maxOptionWords, 'word').join(' ')),
        option('o3'),
      ],
    );
    expect(problems(withMission(beats: beats)), [
      'o1: is ${maxOptionWords + 1} words, over $maxOptionWords',
    ]);
  });

  test('an interviewer line fits two subtitle lines', () {
    final long = 'a' * (maxSubtitleChars + 1);
    expect(
      problems(
        withMission(
          scene: [SceneLine(speakerId: 'priya', text: long)],
        ),
      ),
      [
        'm_fixture: a line by priya is ${maxSubtitleChars + 1} characters, '
            'over $maxSubtitleChars',
      ],
    );
  });

  test('a line can only teach a lesson for a flag it carries', () {
    final beats = [...base.beats];
    beats[0] = Beat(
      kind: BeatKind.open,
      options: [
        option(
          'o1',
          score: 1,
          flags: {Flag.vague},
          lessonId: 'lesson_name_your_part',
        ),
        option('o2'),
        option('o3'),
      ],
    );
    expect(problems(withMission(beats: beats)), [
      'o1: teaches lesson_name_your_part, a we_not_i lesson, but is not flagged we_not_i',
    ]);
  });
}
