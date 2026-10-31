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
    Continuity? continuity,
    List<SceneLine>? epilogue,
    List<Chapter>? chapters,
  }) => ContentBundle(
    chapters: chapters ?? fixture.chapters,
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
        continuity: continuity,
        epilogue: epilogue ?? base.epilogue,
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

  test(
    'chapters are numbered in order, and a playable one lists its missions',
    () {
      expect(
        problems(
          withMission(
            chapters: const [
              Chapter(
                number: 1,
                title: 'One',
                missionTitles: ['Other'],
                playable: true,
              ),
              Chapter(
                number: 3,
                title: 'Three',
                missionTitles: ['Later'],
                playable: false,
              ),
            ],
          ),
        ),
        [
          'chapter 3: chapters must be 1, 2, 3…',
          "chapter 1: its mission titles don't match its missions",
        ],
      );
    },
  );

  test('a mission must sit in a playable chapter', () {
    expect(
      problems(
        withMission(
          chapters: const [
            Chapter(
              number: 1,
              title: 'One',
              missionTitles: ['Fixture'],
              playable: false,
            ),
          ],
        ),
      ),
      contains('m_fixture: chapter 1 is not a playable chapter'),
    );
  });

  test('continuity quotes an earlier mission, once per beat line', () {
    const line = SceneLine(speakerId: 'priya', text: 'You said that.');
    expect(
      problems(
        withMission(
          continuity: const Continuity(
            fromMissionId: 'm_fixture',
            variants: [ContinuityVariant(sourceOptionId: 'o1', line: line)],
          ),
        ),
      ),
      contains(
        'm_fixture: continuity must come from an earlier mission, not m_fixture',
      ),
    );
  });

  test('the continuity line must still fit the scene', () {
    final mission = fixture.missions.single;
    final bundle = ContentBundle(
      chapters: const [
        Chapter(
          number: 1,
          title: 'One',
          missionTitles: ['Fixture', 'Next'],
          playable: true,
        ),
      ],
      interviewers: fixture.interviewers,
      lessons: fixture.lessons,
      missions: [
        mission,
        Mission(
          id: 'm_next',
          chapter: 1,
          number: 2,
          title: 'Next',
          scene: const [
            SceneLine(speakerId: 'priya', text: 'One.'),
            SceneLine(speakerId: 'priya', text: 'Two.'),
            SceneLine(speakerId: 'priya', text: 'Three.'),
          ],
          question: mission.question,
          beats: mission.beats
              .map(
                (b) => Beat(
                  kind: b.kind,
                  options: [
                    for (final o in b.options)
                      AnswerOption(
                        id: 'next_${o.id}',
                        text: o.text,
                        scores: o.scores,
                        flags: o.flags,
                        lessonId: o.lessonId,
                      ),
                  ],
                ),
              )
              .toList(),
          followUps: const [],
          hinted: true,
          continuity: const Continuity(
            fromMissionId: 'm_fixture',
            variants: [
              ContinuityVariant(
                sourceOptionId: 'o1',
                line: SceneLine(speakerId: 'priya', text: 'You said that.'),
              ),
              ContinuityVariant(
                sourceOptionId: 'o1',
                line: SceneLine(speakerId: 'priya', text: 'Again.'),
              ),
              ContinuityVariant(
                sourceOptionId: 'fd1',
                line: SceneLine(speakerId: 'priya', text: 'A reply.'),
              ),
            ],
          ),
        ),
      ],
    );
    expect(
      problems(bundle),
      containsAll([
        'm_next: o1 is challenged twice',
        'm_next: fd1 is not a beat line of m_fixture',
        'm_next: the continuity line makes 4 scene lines, at most 3',
      ]),
    );
  });

  test('lineFor picks the costliest line that has a challenge', () {
    const early = SceneLine(speakerId: 'priya', text: 'Early.');
    const late = SceneLine(speakerId: 'priya', text: 'Late.');
    const continuity = Continuity(
      fromMissionId: 'm_fixture',
      variants: [
        ContinuityVariant(sourceOptionId: 'o1', line: early),
        ContinuityVariant(sourceOptionId: 'e2', line: late),
      ],
    );
    expect(continuity.lineFor(['fd2', 'e2', 'o1']), same(late));
    expect(continuity.lineFor(['fd2', 'o1', 'e2']), same(early));
    expect(continuity.lineFor(['fd2']), isNull);
  });

  test('an epilogue has at most three lines, all by interviewers', () {
    expect(
      problems(
        withMission(
          epilogue: const [
            SceneLine(speakerId: 'priya', text: 'One.'),
            SceneLine(speakerId: 'priya', text: 'Two.'),
            SceneLine(speakerId: 'priya', text: 'Three.'),
            SceneLine(speakerId: 'nobody', text: 'Four.'),
          ],
        ),
      ),
      [
        'm_fixture: has 4 epilogue lines, at most 3',
        'm_fixture: speaker nobody is not an interviewer',
      ],
    );
  });

  group('why step and reaction (wave 5)', () {
    // The fixture's open beat (o1, o2, o3) with a why step and a reaction.
    Beat openWith({List<Reason>? reasons, SceneLine? reacting}) {
      final open = base.beats.first;
      return Beat(
        kind: open.kind,
        options: open.options,
        why: ReasonPrompt(
          line: const SceneLine(speakerId: 'priya', text: 'Why that line?'),
          reasons:
              reasons ??
              const [
                Reason(id: 'r1', text: 'It is specific.', soundFor: {'o1'}),
                Reason(id: 'r2', text: 'It is modest.', soundFor: {'o2'}),
                Reason(id: 'r3', text: 'It is safe.', soundFor: {'o3'}),
              ],
        ),
        reaction: BeatReaction(
          strong:
              reacting ?? const SceneLine(speakerId: 'priya', text: 'Good.'),
          weak: const SceneLine(speakerId: 'priya', text: 'Hm.'),
          guessed: const SceneLine(speakerId: 'priya', text: 'Too quick.'),
        ),
      );
    }

    List<String> problemsWith(Beat open) =>
        problems(withMission(beats: [open, ...base.beats.skip(1)]));

    test('a well-formed why step and reaction pass', () {
      expect(problemsWith(openWith()), isEmpty);
    });

    test('every option has exactly one sound reason', () {
      expect(
        problemsWith(
          openWith(
            reasons: const [
              Reason(id: 'r1', text: 'It is specific.', soundFor: {'o1', 'o2'}),
              Reason(id: 'r2', text: 'It is modest.', soundFor: {'o2'}),
              Reason(id: 'r3', text: 'It is safe.'),
            ],
          ),
        ),
        [
          'o2: has 2 sound reasons, needs exactly 1',
          'o3: has 0 sound reasons, needs exactly 1',
        ],
      );
    });

    test('a sound reason only names options of its own beat', () {
      expect(
        problemsWith(
          openWith(
            reasons: const [
              Reason(id: 'r1', text: 'It is specific.', soundFor: {'o1', 'e1'}),
              Reason(id: 'r2', text: 'It is modest.', soundFor: {'o2'}),
              Reason(id: 'r3', text: 'It is safe.', soundFor: {'o3'}),
            ],
          ),
        ),
        ['r1: is sound for e1, not an option of its beat'],
      );
    });

    test('3–4 reasons, with unique snake_case ids', () {
      expect(
        problemsWith(
          openWith(
            reasons: const [
              Reason(id: 'r1', text: 'It is specific.', soundFor: {'o1'}),
              Reason(id: 'r1', text: 'It is modest.', soundFor: {'o2', 'o3'}),
            ],
          ),
        ),
        [
          'm_fixture open beat: has 2 reasons, needs $minReasons–$maxReasons',
          'r1: id is used more than once',
        ],
      );
    });

    test('a reason is at most $maxReasonWords words', () {
      final long = List.filled(maxReasonWords + 1, 'word').join(' ');
      expect(
        problemsWith(
          openWith(
            reasons: [
              Reason(id: 'r1', text: long, soundFor: const {'o1'}),
              const Reason(id: 'r2', text: 'It is modest.', soundFor: {'o2'}),
              const Reason(id: 'r3', text: 'It is safe.', soundFor: {'o3'}),
            ],
          ),
        ),
        ['r1: is ${maxReasonWords + 1} words, over $maxReasonWords'],
      );
    });

    test('the interviewer says the why line and the reactions', () {
      expect(
        problemsWith(
          openWith(
            reacting: const SceneLine(speakerId: 'nobody', text: 'Hi.'),
          ),
        ),
        ['m_fixture open beat: speaker nobody is not an interviewer'],
      );
    });

    test('a reason marks itself sound only for the options it names', () {
      const reason = Reason(id: 'r', text: 'x', soundFor: {'a'});
      expect(reason.pickFor('a').sound, isTrue);
      expect(reason.pickFor('b').sound, isFalse);
      expect(reason.pickFor('a').reasonId, 'r');
    });
  });

  group('Beat.isStrongest', () {
    test(
      'the line with the smallest weighted shortfall; ties are all strongest',
      () {
        final beat = Beat(
          kind: BeatKind.open,
          options: [option('a', score: 3), option('b', score: 3), option('c')],
        );
        expect(beat.isStrongest('a'), isTrue);
        expect(beat.isStrongest('b'), isTrue);
        expect(beat.isStrongest('c'), isFalse);
        expect(beat.isStrongest('missing'), isFalse);
      },
    );
  });
}
