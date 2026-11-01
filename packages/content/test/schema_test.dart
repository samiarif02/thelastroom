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

  const reaction = BeatReaction(
    strong: SceneLine(speakerId: 'priya', text: 'Good.'),
    weak: SceneLine(speakerId: 'priya', text: 'Hm.'),
    guessed: SceneLine(speakerId: 'priya', text: 'Too quick.'),
  );

  /// An open beat over [options] with a valid why step: one principle sound for the strongest
  /// line, one misconception tempting each other line (unless [reasons] are given).
  Beat openBeat(List<AnswerOption> options, {List<Reason>? reasons}) {
    final beat = Beat(kind: BeatKind.open, options: options);
    return Beat(
      kind: BeatKind.open,
      options: options,
      why: ReasonPrompt(
        line: const SceneLine(speakerId: 'priya', text: 'Why that line?'),
        reasons:
            reasons ??
            [
              for (final o in options)
                beat.isStrongest(o.id)
                    ? Reason(
                        id: 'why_${o.id}',
                        text: 'Be specific.',
                        soundFor: {o.id},
                      )
                    : Reason(
                        id: 'why_${o.id}',
                        text: 'Myth ${o.id}.',
                        tempts: {o.id},
                      ),
            ],
      ),
      reaction: reaction,
    );
  }

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
    beats[0] = openBeat([
      option(
        'o1',
        score: 3,
        text: List.filled(maxOptionWords + 1, 'word').join(' '),
      ),
      option('o2', text: List.filled(maxOptionWords, 'word').join(' ')),
      option('o3', score: 1),
    ]);
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
    beats[0] = openBeat([
      option(
        'o1',
        score: 1,
        flags: {Flag.vague},
        lessonId: 'lesson_name_your_part',
      ),
      option('o2', score: 3),
      option('o3'),
    ]);
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
    // o1 is the strongest line (3s); o2 and o3 are weak (1s).
    final options = [
      option('o1', score: 3),
      option('o2', score: 1),
      option('o3', score: 1),
    ];
    List<String> problemsWith(Beat open) =>
        problems(withMission(beats: [open, ...base.beats.skip(1)]));
    const sound = Reason(id: 'r1', text: 'Be specific.', soundFor: {'o1'});
    const myth2 = Reason(id: 'r2', text: 'Modesty wins.', tempts: {'o2'});
    const myth3 = Reason(id: 'r3', text: 'Safe is best.', tempts: {'o3'});

    test(
      'one principle for the strongest line, one myth per weak line, passes',
      () {
        expect(problemsWith(openBeat(options)), isEmpty);
      },
    );

    test('every beat needs a why step and a reaction', () {
      expect(problemsWith(Beat(kind: BeatKind.open, options: options)), [
        'm_fixture open beat: needs a why step and a reaction',
      ]);
    });

    test('exactly one sound reason, and only for a strongest line', () {
      expect(
        problemsWith(
          openBeat(
            options,
            reasons: const [
              sound,
              Reason(
                id: 'r2',
                text: 'Modesty wins.',
                soundFor: {'o2'},
                tempts: {'o2'},
              ),
              myth3,
            ],
          ),
        ),
        [
          'm_fixture open beat: has 2 sound reasons, needs exactly 1',
          'r2: is sound for o2, which is not a strongest line',
        ],
      );
    });

    test('every weak line is tempted by exactly one misconception', () {
      expect(
        problemsWith(
          openBeat(
            options,
            reasons: const [
              sound,
              Reason(id: 'r2', text: 'Modesty wins.', tempts: {'o2', 'o1'}),
              Reason(id: 'r3', text: 'Safe is best.', tempts: {'o2'}),
            ],
          ),
        ),
        [
          'r2: tempts o1, which is a strongest line',
          'o2: is tempted by 2 reasons, needs exactly 1',
          'o3: is tempted by 0 reasons, needs exactly 1',
        ],
      );
    });

    test('a reason only names options of its own beat', () {
      expect(
        problemsWith(
          openBeat(
            options,
            reasons: const [
              sound,
              Reason(id: 'r2', text: 'Modesty wins.', tempts: {'o2', 'e2'}),
              myth3,
            ],
          ),
        ),
        ['r2: names e2, not an option of its beat'],
      );
    });

    test('a reason is a principle: it never repeats five words of a line', () {
      final lined = [
        option(
          'o1',
          score: 3,
          text: 'I tagged six hundred support tickets myself.',
        ),
        option('o2', score: 1),
        option('o3', score: 1),
      ];
      expect(
        problemsWith(
          openBeat(
            lined,
            reasons: const [
              Reason(
                id: 'r1',
                text: 'Because I Tagged Six Hundred Support tickets.',
                soundFor: {'o1'},
              ),
              myth2,
              myth3,
            ],
          ),
        ),
        ['r1: repeats "i tagged six hundred support" from o1'],
      );
      expect(sharedPhrase('one two three four', 'one two three four'), isNull);
    });

    test('3–4 reasons, with unique ids, of at most $maxReasonWords words', () {
      final long = List.filled(maxReasonWords + 1, 'word').join(' ');
      expect(
        problemsWith(
          openBeat(
            options,
            reasons: [
              Reason(id: 'r1', text: long, soundFor: const {'o1'}),
              const Reason(
                id: 'r1',
                text: 'Modesty wins.',
                tempts: {'o2', 'o3'},
              ),
            ],
          ),
        ),
        [
          'm_fixture open beat: has 2 reasons, needs $minReasons–$maxReasons',
          'r1: is ${maxReasonWords + 1} words, over $maxReasonWords',
          'r1: id is used more than once',
        ],
      );
    });

    test('the interviewer says the why line and the reactions', () {
      final beat = openBeat(options);
      expect(
        problemsWith(
          Beat(
            kind: beat.kind,
            options: beat.options,
            why: beat.why,
            reaction: const BeatReaction(
              strong: SceneLine(speakerId: 'nobody', text: 'Hi.'),
              weak: SceneLine(speakerId: 'priya', text: 'Hm.'),
              guessed: SceneLine(speakerId: 'priya', text: 'Too quick.'),
            ),
          ),
        ),
        ['m_fixture open beat: speaker nobody is not an interviewer'],
      );
    });

    test('reasonPick: the reason only counts on a strongest line', () {
      final beat = openBeat(options);
      final strongRight = beat.reasonPick(sound, 'o1');
      final strongWrong = beat.reasonPick(myth2, 'o1');
      final weak = beat.reasonPick(myth2, 'o2');
      expect((strongRight.sound, strongRight.counts), (true, true));
      expect((strongWrong.sound, strongWrong.counts), (false, true));
      expect((weak.sound, weak.counts), (false, false));
      expect(weak.reasonId, 'r2');
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

  group('build your answer (brief 27)', () {
    Lesson lesson(String id, Flag flag) => Lesson(
      id: id,
      title: id,
      flag: flag,
      flaw: 'A flaw.',
      takeaway: 'A takeaway.',
      recall: RecallCheck(
        prompt: 'Which?',
        options: [
          RecallOption(id: '${id}_a', text: 'A.'),
          RecallOption(id: '${id}_b', text: 'B.'),
        ],
        correctOptionId: '${id}_a',
      ),
    );

    const parts = [
      Fragment(id: 'b_s', text: 'Support was drowning in tickets.'),
      Fragment(id: 'b_t', text: 'I was asked to find out why.'),
      Fragment(id: 'b_a', text: 'I tagged 600 of them in a spreadsheet.'),
      Fragment(id: 'b_r', text: 'Resets fell by a quarter.'),
    ];
    const decoy = Fragment(
      id: 'b_we',
      text: 'We all pitched in.',
      flags: {Flag.weNotI},
      lessonId: 'lesson_name_your_part',
    );

    BuildBeat build({
      List<Fragment> parts = parts,
      List<Fragment> decoys = const [decoy],
      String orderLessonId = 'lesson_one_story',
      String missingLessonId = 'lesson_be_concrete',
    }) => BuildBeat(
      id: 'b_build',
      parts: parts,
      decoys: decoys,
      orderLessonId: orderLessonId,
      missingLessonId: missingLessonId,
    );

    List<String> problemsWith(BuildBeat b) {
      final beats = [...base.beats];
      final evidence = beats[1];
      beats[1] = Beat(
        kind: evidence.kind,
        options: evidence.options,
        why: evidence.why,
        reaction: evidence.reaction,
        build: b,
      );
      final bundle = withMission(beats: beats);
      return problems(
        ContentBundle(
          chapters: bundle.chapters,
          interviewers: bundle.interviewers,
          lessons: [
            ...bundle.lessons,
            lesson('lesson_one_story', Flag.rambling),
            lesson('lesson_be_concrete', Flag.vague),
          ],
          missions: bundle.missions,
        ),
      );
    }

    test('a well-formed build is valid', () {
      expect(problemsWith(build()), isEmpty);
    });

    test('3–4 parts and exactly one decoy', () {
      expect(
        problemsWith(build(parts: parts.take(2).toList())),
        contains('b_build: has 2 parts, needs 3–4'),
      );
      expect(
        problemsWith(build(decoys: const [])),
        contains('b_build: has 0 decoys, needs exactly 1'),
      );
    });

    test('a part is clean; a decoy is flagged and teaches its lesson', () {
      expect(
        problemsWith(
          build(
            parts: [
              ...parts.take(3),
              const Fragment(
                id: 'b_r',
                text: 'Resets fell.',
                flags: {Flag.vague},
              ),
            ],
          ),
        ),
        contains(
          'b_r: is a part of the strong answer, so has no flag or lesson',
        ),
      );
      expect(
        problemsWith(
          build(
            decoys: const [Fragment(id: 'b_we', text: 'We all pitched in.')],
          ),
        ),
        contains('b_we: is a decoy, so needs a flag and its lesson'),
      );
      expect(
        problemsWith(
          build(
            decoys: const [
              Fragment(
                id: 'b_we',
                text: 'We all pitched in.',
                flags: {Flag.blame},
                lessonId: 'lesson_name_your_part',
              ),
            ],
          ),
        ),
        contains(
          'b_we: teaches lesson_name_your_part, a we_not_i lesson, '
          'but is not flagged we_not_i',
        ),
      );
    });

    test('the order and gap lessons exist and match their flags', () {
      expect(
        problemsWith(build(orderLessonId: 'lesson_be_concrete')),
        contains(
          'b_build: teaches lesson_be_concrete, a vague lesson, '
          'where a rambling one is needed',
        ),
      );
      expect(
        problemsWith(build(missingLessonId: 'lesson_nope')),
        contains('b_build: lesson lesson_nope does not exist'),
      );
    });

    test('fragments are short, and ids unique and snake_case', () {
      final long = List.filled(maxFragmentWords + 1, 'word').join(' ');
      expect(
        problemsWith(
          build(
            parts: [
              ...parts.take(3),
              Fragment(id: 'b_r', text: long),
            ],
          ),
        ),
        contains(
          'b_r: is ${maxFragmentWords + 1} words, over $maxFragmentWords',
        ),
      );
      expect(
        problemsWith(
          build(
            parts: [
              ...parts.take(3),
              const Fragment(id: 'o1', text: 'x'),
            ],
          ),
        ),
        contains('o1: id is used more than once'),
      );
    });

    test('the built answer resolves through the beat, and only a full build is strongest', () {
      final b = build();
      final beat = Beat(
        kind: BeatKind.evidence,
        options: base.beats[1].options,
        build: b,
      );
      final strong = b.strongAnswer;
      expect(strong.text, parts.map((p) => p.text).join(' '));
      expect(strong.lessonId, isNull);
      expect(beat.optionById(strong.id)?.text, strong.text);
      expect(beat.isStrongest(strong.id), isTrue);

      final we = b.answerFor(['b_s', 'b_t', 'b_we', 'b_a', 'b_r']);
      expect(we.flags, {Flag.weNotI});
      expect(we.lessonId, 'lesson_name_your_part');
      expect(beat.isStrongest(we.id), isFalse);

      final jumbled = b.answerFor(['b_a', 'b_s', 'b_r', 'b_t']);
      expect(jumbled.lessonId, 'lesson_one_story');
      final thin = b.answerFor(['b_s', 'b_a']);
      expect(thin.lessonId, 'lesson_be_concrete');

      expect(beat.optionById('other_build=b_s'), isNull);
      final picked = base.beats[1].options.first.id;
      expect(beat.optionById(picked)?.id, picked);
    });
  });
}
