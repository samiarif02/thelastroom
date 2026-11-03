import 'package:engine/engine.dart';

import '../../build_beat.dart';
import '../../mission.dart';
import '../interviewers.dart';

/// Mission 15, "Solve the Problem" (brief §6, brief 38): Sam opens the final round with a
/// problem from Northstar's own app.
///
/// A choices mission: structure is the skill, and seeing the shapes side by side teaches it.
/// The strong answer checks the problem is real, finds where it sits, asks why, then changes one
/// thing and measures it. The tempting lines jump to a fix that worked before, recite a
/// framework, list every cause, or promise the result. The evidence beat is built from
/// fragments: putting the steps in order is the reasoning.
const missionSolveTheProblem = Mission(
  id: 'm15_solve_the_problem',
  chapter: 3,
  number: 15,
  title: 'Solve the problem',
  practises: 'Working a problem out loud: check it, find the cause, then change one thing.',
  hinted: true,
  scene: [
    SceneLine(
      speakerId: samId,
      text: "I'm Sam. I run product here. Marcus says you like a number.",
    ),
    SceneLine(speakerId: samId, text: "So here's a real one, from last month."),
  ],
  question: SceneLine(
    speakerId: samId,
    text: 'Sign-ups to our app fell by a fifth last month. Where do you start?',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: samId, text: 'Why start there?'),
        reasons: [
          Reason(
            id: 'm15_open_why_check',
            text: 'Make sure the problem is real, and where it sits, before choosing any fix.',
            soundFor: {'m15_open_check_real'},
          ),
          Reason(
            id: 'm15_open_why_method',
            text: 'Naming a clear method shows I can handle any problem.',
            tempts: {'m15_open_framework'},
          ),
          Reason(
            id: 'm15_open_why_proven',
            text: 'A fix that has worked before is the best proof I can offer.',
            tempts: {'m15_open_fix_first'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: samId,
          text: 'Good. Most people skip that check.',
        ),
        weak: SceneLine(
          speakerId: samId,
          text: "Hm. You haven't looked at the problem yet.",
        ),
        guessed: SceneLine(
          speakerId: samId,
          text: 'That was quick. Read them again.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm15_open_check_real',
          text:
              "First I'd check the drop is real: the same tracking as before, and whether "
              'it hit every step of sign-up or just one.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm15_open_framework',
          text:
              "I'd use a clear framework for it: define the problem, gather the data, list "
              'the hypotheses, then prioritise and test them.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_use_the_method',
        ),
        AnswerOption(
          id: 'm15_open_fix_first',
          text:
              "I'd go straight to the sign-up screens. On my study app, cutting them from "
              'five to two took sign-ups from 40% to 75%.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 3,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_cause_before_fix',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      build: BuildBeat(
        id: 'm15_evidence_build',
        parts: [
          Fragment(
            id: 'm15_build_where',
            text: "I'd find the step where most people stop.",
          ),
          Fragment(
            id: 'm15_build_compare',
            text: 'Then compare it with last month.',
          ),
          Fragment(
            id: 'm15_build_ask',
            text: 'Then ask a few who stopped why.',
          ),
          Fragment(
            id: 'm15_build_twelve',
            text: 'Twelve interviews did that on my project.',
          ),
        ],
        decoys: [
          Fragment(
            id: 'm15_build_redesign',
            text: "I'd redesign the whole sign-up straight away.",
            flags: {Flag.offQuestion},
            lessonId: 'lesson_cause_before_fix',
          ),
        ],
        orderLessonId: 'lesson_one_story',
        missingLessonId: 'lesson_be_concrete',
        weakReaction: SceneLine(
          speakerId: samId,
          text: "The pieces are there. Put them in the order you'd do them.",
        ),
      ),
      why: ReasonPrompt(
        line: SceneLine(speakerId: samId, text: 'Why in that order?'),
        reasons: [
          Reason(
            id: 'm15_evidence_why_where_then_why',
            text: 'Numbers show where people stop; talking to them shows why. I need both.',
            soundFor: {'m15_evidence_where_then_why'},
          ),
          Reason(
            id: 'm15_evidence_why_cover_all',
            text: "Covering every possible cause means I can't miss the real one.",
            tempts: {'m15_evidence_every_cause'},
          ),
          Reason(
            id: 'm15_evidence_why_together',
            text: 'Deciding together gets the team behind the answer from the start.',
            tempts: {'m15_evidence_team_huddle'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: samId,
          text: "Where, then why. That's the right order.",
        ),
        weak: SceneLine(
          speakerId: samId,
          text: "I still don't know what you'd do first.",
        ),
        guessed: SceneLine(
          speakerId: samId,
          text: 'Too fast. Take the time to read them.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm15_evidence_where_then_why',
          text:
              "I'd find the step where most people stop, compare it with last month, then "
              'ask a few who quit why, as I did with twelve students.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm15_evidence_every_cause',
          text:
              'It could be marketing, a bug, the time of year or a competitor, so I would '
              'look into all of those and see which one stands out most.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_first_step',
        ),
        AnswerOption(
          id: 'm15_evidence_team_huddle',
          text:
              "We'd pull up the dashboards together as a team, compare our ideas, and agree "
              'on the likeliest cause as a group.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      why: ReasonPrompt(
        line: SceneLine(speakerId: samId, text: 'Why finish on that?'),
        reasons: [
          Reason(
            id: 'm15_land_why_measure',
            text: 'Change one thing and measure it, so I know what actually worked.',
            soundFor: {'m15_land_one_change'},
          ),
          Reason(
            id: 'm15_land_why_confident',
            text:
                'Sounding sure of the result is what a head of product wants.',
            tempts: {'m15_land_back_up'},
          ),
          Reason(
            id: 'm15_land_why_thorough',
            text: 'Mentioning every other angle shows how thorough I am.',
            tempts: {'m15_land_and_also'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: samId,
          text: "One change, measured. I'd trust that.",
        ),
        weak: SceneLine(
          speakerId: samId,
          text: 'Hm. And how would you know it worked?',
        ),
        guessed: SceneLine(
          speakerId: samId,
          text: "Don't rush the end. That's the plan.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm15_land_one_change',
          text:
              "Then I'd change only that step and check the next week's sign-ups. If they "
              "don't recover, I'd go back to the interviews.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm15_land_back_up',
          text:
              "And I'm confident that approach would get sign-ups back above where they "
              'were within the month, if not sooner.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_promise_the_habit',
        ),
        AnswerOption(
          id: 'm15_land_and_also',
          text:
              "Then there's pricing too, and the store reviews, and maybe the emails, and "
              'the onboarding, so I would check those as well…',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 0,
            adaptability: 0,
          ),
          flags: {Flag.rambling},
          lessonId: 'lesson_one_story',
        ),
      ],
    ),
  ],
  followUps: [
    FollowUp(
      id: 'm15_follow_nothing_unusual',
      line: SceneLine(
        speakerId: samId,
        text: 'Say the numbers show nothing unusual. What then?',
      ),
      replies: [
        AnswerOption(
          id: 'm15_reply_nothing_talk',
          text:
              "Then I'd talk to people who started signing up and stopped. On my project, "
              'twelve interviews found what numbers missed.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm15_reply_nothing_seasonal',
          text:
              "Then it's probably just a seasonal dip, so I'd wait a month or so and see "
              'whether sign-ups recover on their own.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_first_step',
        ),
        AnswerOption(
          id: 'm15_reply_nothing_marketing',
          text:
              "Then it's most likely a marketing problem, since nothing in the product "
              'itself has changed at all in the last few months.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.blame},
          lessonId: 'lesson_own_your_part',
        ),
      ],
    ),
    FollowUp(
      id: 'm15_follow_fixed_too_soon',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: samId,
        text:
            "You've fixed it before we know what's broken. What do you check?",
      ),
      replies: [
        AnswerOption(
          id: 'm15_reply_fixed_funnel',
          text:
              'Fair. Where people stop in the sign-up, this month against last. Then I '
              'know which screen to touch, if any.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm15_reply_fixed_still_screens',
          text:
              "I'd still start with the screens. Shorter sign-ups nearly always do "
              "better, so it's a safe bet.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_cause_before_fix',
        ),
        AnswerOption(
          id: 'm15_reply_fixed_everything',
          text:
              'A bit of everything, to save time: the screens, the emails and the store '
              'page, all in one go.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_first_step',
        ),
      ],
    ),
    FollowUp(
      id: 'm15_follow_which_first',
      trigger: Flag.vague,
      line: SceneLine(
        speakerId: samId,
        text: "That's a list. Which one would you check first, and why?",
      ),
      replies: [
        AnswerOption(
          id: 'm15_reply_which_steps',
          text:
              'The sign-up steps, because a drop that big usually shows up in one place, '
              'and that tells me where to look next.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm15_reply_which_all',
          text:
              'All of them at once, really, because any of them could be it, and I '
              "wouldn't want to miss the real one.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_first_step',
        ),
        AnswerOption(
          id: 'm15_reply_which_team',
          text:
              'Whichever one the team thinks is likeliest. They know the product far '
              'better than I do, at least for now.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
      ],
    ),
  ],
);
