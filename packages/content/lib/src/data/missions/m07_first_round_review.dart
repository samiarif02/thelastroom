import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 7, "First Round Review" (brief §6): Priya and Marcus, and a question Jordan hasn't
/// heard yet.
///
/// No hints (FR-30): a new question tests whether the Chapter 1 lessons transfer. Passing it
/// unhinted with specificity of [evidenceBuilderMinSpecificity] or more earns *Evidence
/// Builder*. The report against the Mission 1 baseline follows the debrief (brief 13), then
/// the [Mission.epilogue] cliffhanger, then the Chapter 2 teaser.
const missionFirstRoundReview = Mission(
  id: 'm07_first_round_review',
  chapter: 1,
  number: 7,
  title: 'First Round Review',
  hinted: false,
  skillRequirements: [
    SkillRequirement(
      skill: Skill.evidenceBuilder,
      dimension: Dimension.specificity,
      minScore: evidenceBuilderMinSpecificity,
    ),
  ],
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: 'Last one for today, Jordan. Marcus and I are both here for this one.',
    ),
    SceneLine(
      speakerId: marcusId,
      text: "And it's a question you haven't heard from us yet.",
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell me about something you improved that nobody asked you to.',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: marcusId, text: 'Why that one?'),
        reasons: [
          Reason(
            id: 'm07_open_why_unasked',
            text: "It's a problem nobody had asked me to fix.",
            soundFor: {'m07_open_cafe_late'},
          ),
          Reason(
            id: 'm07_open_why_research',
            text: "It's my strongest project, with real research behind it.",
            soundFor: {'m07_open_supervisor_asked'},
          ),
          Reason(
            id: 'm07_open_why_trait',
            text: "It tells him I'm proactive before I give the example.",
            soundFor: {'m07_open_proactive'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: "Nobody asked. Good, that's the question.",
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: "That's not quite what I asked for.",
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'You picked that fast. Read them first.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm07_open_cafe_late',
          text:
              'At the campus café, where I worked part-time for two years, we opened late '
              'about twice a week, and nobody had a fix for it.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm07_open_supervisor_asked',
          text:
              'In my final-year project, our supervisor asked us to improve the sign-up, '
              'so I interviewed twelve students to find the real problem.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
        AnswerOption(
          id: 'm07_open_proactive',
          text:
              "I'm naturally proactive, so I'm always looking for things to improve. One "
              'example is from my part-time job at the campus café.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_talk_like_yourself',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      why: ReasonPrompt(
        line: SceneLine(speakerId: marcusId, text: 'Why tell it like that?'),
        reasons: [
          Reason(
            id: 'm07_evidence_why_measured',
            text: 'It says what I measured, what I made and how I tested it.',
            soundFor: {'m07_evidence_checklist'},
          ),
          Reason(
            id: 'm07_evidence_why_agreed',
            text: 'It shows everyone agreed and followed the new routine.',
            soundFor: {'m07_evidence_team_routine'},
          ),
          Reason(
            id: 'm07_evidence_why_example',
            text: 'It shows my work ethic set an example.',
            soundFor: {'m07_evidence_harder'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: 'You timed it, then you tested it. Good.',
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: 'And what did you change, exactly?',
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'Too quick. I want the thinking, not the click.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm07_evidence_checklist',
          text:
              'I timed a few openings, saw we lost time hunting for keys and stock, and '
              'wrote a one-page opening checklist that I tested on my shifts.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm07_evidence_team_routine',
          text:
              'We talked it through as a team, agreed a new routine for the mornings, and '
              'then everyone started following it properly within about a week.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
        AnswerOption(
          id: 'm07_evidence_harder',
          text:
              'I just started coming in a bit earlier and working harder on my shifts, '
              'and I encouraged the others to do the same as me.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      why: ReasonPrompt(
        line: SceneLine(speakerId: marcusId, text: 'Why close on that?'),
        reasons: [
          Reason(
            id: 'm07_land_why_lasting',
            text: 'It gives the result, and how the fix outlasted my shifts.',
            soundFor: {'m07_land_on_time'},
          ),
          Reason(
            id: 'm07_land_why_leader',
            text: "It shows the leadership I'd bring to Northstar.",
            soundFor: {'m07_land_natural_leader'},
          ),
          Reason(
            id: 'm07_land_why_modest',
            text: "It's modest about a small example.",
            soundFor: {'m07_land_small_thing'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: 'On time all term, and three trained. Solid.',
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: "Hm. I'd rather hear what it changed.",
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: "Don't rush the end. That's where results go.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm07_land_on_time',
          text:
              'After that, the café opened on time every day for the rest of term, and I '
              'used the checklist to train three new staff.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm07_land_natural_leader',
          text:
              "It showed me I'm a natural leader, and I'd bring that same drive to "
              'improve things to every single team I join at Northstar.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_promise_the_habit',
        ),
        AnswerOption(
          id: 'm07_land_small_thing',
          text:
              "It was only a small thing in a café, to be honest, so I'm not sure it "
              'really counts as the kind of example you wanted from me.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
      ],
    ),
  ],
  followUps: [
    FollowUp(
      id: 'm07_follow_why_bother',
      line: SceneLine(
        speakerId: priyaId,
        text: 'Why did that one bother you enough to fix it?',
      ),
      replies: [
        AnswerOption(
          id: 'm07_reply_bother_queue',
          text:
              'Late openings meant a queue of annoyed students before their early '
              'lectures, and I was the one apologising to them every time.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm07_reply_bother_wired',
          text:
              "I've always been someone who can't leave a problem alone. It's just how "
              "I'm wired, and it has served me really well everywhere.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_talk_like_yourself',
        ),
        AnswerOption(
          id: 'm07_reply_bother_promotion',
          text:
              'Honestly, the manager had mentioned a shift-leader role might come up, and '
              'I wanted to show I was ready for it.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
      ],
    ),
    FollowUp(
      id: 'm07_follow_who_wrote_it',
      trigger: Flag.weNotI,
      line: SceneLine(
        speakerId: marcusId,
        text: 'Who wrote the routine? You or the team?',
      ),
      replies: [
        AnswerOption(
          id: 'm07_reply_wrote_me',
          text:
              'I wrote it and tested it on my own shifts first. Then the manager agreed '
              "we'd all use it, and I trained the others on it.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm07_reply_wrote_shared',
          text:
              'It was a shared effort, honestly. I had the idea, but the whole team '
              "shaped it, so I wouldn't want to call it mine.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
        AnswerOption(
          id: 'm07_reply_wrote_all_me',
          text:
              'Me. I designed the whole system and got everyone to follow it, so honestly '
              'the turnaround was all down to me in the end.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_share_the_credit',
        ),
      ],
    ),
    FollowUp(
      id: 'm07_follow_what_changed',
      trigger: Flag.vague,
      line: SceneLine(
        speakerId: marcusId,
        text: "'Working harder' isn't a fix. What actually changed?",
      ),
      replies: [
        AnswerOption(
          id: 'm07_reply_changed_list',
          text:
              'Fair. The real change was a one-page checklist: keys, float, stock, '
              'machine. After that, we opened on time every day that term.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm07_reply_changed_attitude',
          text:
              "Mostly the team's attitude. Once people saw me caring more, they started "
              'caring more too, and the mornings just improved.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
        AnswerOption(
          id: 'm07_reply_changed_manager',
          text:
              "I'd also say the new manager helped a lot, because they were much stricter "
              'about people turning up on time.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.blame},
          lessonId: 'lesson_own_your_part',
        ),
      ],
    ),
  ],
  epilogue: [
    SceneLine(
      speakerId: priyaId,
      text: "That's the first round done, Jordan. Marcus wants you back.",
    ),
    SceneLine(
      speakerId: marcusId,
      text: "Next time it's the floor upstairs. They won't be as friendly.",
    ),
    SceneLine(
      speakerId: priyaId,
      text: 'Oh, and Lena will be there. She asked for you by name.',
    ),
  ],
);

/// The specificity (0–100) an unhinted Mission 7 needs to earn *Evidence Builder*: concrete,
/// personal evidence in nearly every line.
const int evidenceBuilderMinSpecificity = 75;
