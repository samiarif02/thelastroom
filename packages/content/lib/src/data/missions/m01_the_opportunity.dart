import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 1, "The Opportunity" (brief §6): Priya asks why you applied.
///
/// The baseline every later score is compared with (FR-30), so it is unhinted and untimed, and
/// no model answer is shown before it. The role is the Product Associate at Northstar Labs;
/// Priya greets Jordan by name and names the role's two halves (users and numbers), so the
/// player knows who they play and a strong answer has something concrete to tie back to.
///
/// Reworked to the owner's writing notes (2026-10-30): every set has one tempting wrong line
/// with a hidden flaw, the options are close in length, and every line draws on Jordan's
/// facts (`player`, the character sheet).
const missionTheOpportunity = Mission(
  id: 'm01_the_opportunity',
  chapter: 1,
  number: 1,
  title: 'The Opportunity',
  hinted: false,
  timed: false,
  isBaseline: true,
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: "Hi Jordan, I'm Priya. I hire for the product team here at Northstar Labs.",
    ),
    SceneLine(
      speakerId: priyaId,
      text: "I've read your CV. This role is talking to users and reading the numbers.",
    ),
    SceneLine(
      speakerId: priyaId,
      text:
          'No trick questions today. I just want to hear it in your own words.',
    ),
  ],
  question: SceneLine(
    speakerId: priyaId,
    text: 'So, what made you apply for this role?',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(
          speakerId: priyaId,
          text: 'Why lead with that, Jordan?',
        ),
        reasons: [
          Reason(
            id: 'm01_open_why_the_question',
            text: 'It answers what she actually asked: why this role, not why this company.',
            soundFor: {'m01_open_role_fit'},
          ),
          Reason(
            id: 'm01_open_why_passion',
            text: 'Passion for the company is what wins an interviewer over.',
            tempts: {'m01_open_believe'},
          ),
          Reason(
            id: 'm01_open_why_candour',
            text:
                'Saying what suits me is honest, and honesty is always safest.',
            tempts: {'m01_open_first_job'},
          ),
          Reason(
            id: 'm01_open_why_boxes',
            text:
                "Interviewers want to hear you've ticked every box on the ad.",
            tempts: {'m01_open_job_ad'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: "Good. You're talking about the job itself, not just us.",
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: 'Hm. I hear that one a lot. Go on.',
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: "That was quick, Jordan. Slow down, I've got time.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm01_open_role_fit',
          text:
              'I like finding out why people get stuck in a product, and this role is '
              'built around exactly that: real users and real numbers.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm01_open_believe',
          text:
              "I've followed Northstar for a while, and I really believe in what you're "
              'building. I want my first job to be somewhere with real purpose.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
        AnswerOption(
          id: 'm01_open_first_job',
          text:
              "Honestly, I'm looking for my first full-time job, and the hybrid schedule "
              'and the location here would suit me really well.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
        AnswerOption(
          id: 'm01_open_job_ad',
          text:
              'I read the job description closely, and I match almost every point on it: '
              'user research, data analysis, teamwork and communication.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
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
        line: SceneLine(speakerId: priyaId, text: 'Why that example?'),
        reasons: [
          Reason(
            id: 'm01_evidence_why_one_story',
            text: 'One story with my own part and a number beats a list of strengths.',
            soundFor: {'m01_evidence_sign_up'},
          ),
          Reason(
            id: 'm01_evidence_why_modest',
            text: "Saying 'we' sounds more modest than saying 'I'.",
            tempts: {'m01_evidence_team_did'},
          ),
          Reason(
            id: 'm01_evidence_why_pattern',
            text: 'A pattern across my whole life is stronger than a single example.',
            tempts: {'m01_evidence_always'},
          ),
          Reason(
            id: 'm01_evidence_why_background',
            text: "The full background helps her see where I'm coming from.",
            tempts: {'m01_evidence_whole_story'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: "Twelve interviews, two screens, 75%. That's what I wanted.",
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Okay. I'll want more of you in that, though.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: "You picked that before you'd read it. Want to think again?",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm01_evidence_sign_up',
          text:
              'In my final-year project I interviewed twelve students, cut our study '
              "app's sign-up from five screens to two, and finished sign-ups went from "
              '40% to 75%.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm01_evidence_team_did',
          text:
              'In my final-year project our team interviewed twelve students, rebuilt the '
              'sign-up together, and we took finished sign-ups from 40% to 75%.',
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
          id: 'm01_evidence_always',
          text:
              "Across my degree, my internship and my café job, I've always been the one "
              'who listens to users first and then checks what the data says.',
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
          id: 'm01_evidence_whole_story',
          text:
              'It started in second year, when a friend needed help with an app, and then '
              'I took a data module, and later my project went that way…',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 0,
            adaptability: 0,
          ),
          flags: {Flag.rambling},
          lessonId: 'lesson_one_story',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'And why finish there?'),
        reasons: [
          Reason(
            id: 'm01_land_why_tie_back',
            text:
                "A good close ties my story back to the job she's hiring for.",
            soundFor: {'m01_land_bring_habit'},
          ),
          Reason(
            id: 'm01_land_why_promise',
            text: 'A confident promise of results is the strongest way to finish.',
            tempts: {'m01_land_same_impact'},
          ),
          Reason(
            id: 'm01_land_why_eager',
            text:
                "Showing I'd take anything proves how much I want to be here.",
            tempts: {'m01_land_any_role'},
          ),
          Reason(
            id: 'm01_land_why_offer_more',
            text: 'Offering more examples shows I have plenty to talk about.',
            tempts: {'m01_land_trail_off'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Nice. You came back to the role. That lands.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Right. Let's leave it there for now.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: "You're rushing the ending, Jordan. Finish it properly.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm01_land_bring_habit',
          text:
              "That's the work I want to do every day: talk to users first, then check "
              'the numbers to see if the change actually worked.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm01_land_same_impact',
          text:
              "I'm confident I could bring that same kind of impact here from day one, "
              'and help your team move its own numbers just as quickly.',
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
          id: 'm01_land_any_role',
          text:
              "Honestly, I'd be happy in any role here. I just really want to get my foot "
              'in the door at a company like Northstar.',
          scores: DimensionScores(
            relevance: 0,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
        AnswerOption(
          id: 'm01_land_trail_off',
          text:
              "So yes, that's basically it, I think, unless you'd like to hear about my "
              'other projects too, because there are a few more of those…',
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
      id: 'm01_follow_hardest_part',
      line: SceneLine(
        speakerId: priyaId,
        text: "Thanks, that's clear. What will be the hardest part of this job for you?",
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_hardest_big_data',
          text:
              "Big company data. I've only used small spreadsheets, so I'm halfway "
              "through an SQL course, and I'd ask the data team to check my first "
              'queries.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_hardest_perfectionist',
          text:
              "Probably that I care a lot about getting things perfect, so I'll need to "
              'learn when good enough really is good enough in a fast team.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_talk_like_yourself',
        ),
        AnswerOption(
          id: 'm01_reply_hardest_technical',
          text:
              "Maybe some of the technical side at first, but I learn quickly, and I'm "
              "sure I'll pick it all up within my first few months.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
      ],
    ),
    FollowUp(
      id: 'm01_follow_your_part',
      trigger: Flag.weNotI,
      line: SceneLine(
        speakerId: priyaId,
        text: "You said 'we' a lot there. What was your part?",
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_part_mine',
          text:
              'I ran all twelve interviews and designed the new two-screen sign-up. Two '
              'teammates built the back end, and one built the screens.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_part_team_effort',
          text:
              "It was a real team effort. I'd rather not single myself out, because the "
              'result only happened since all four of us pulled together.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
        AnswerOption(
          id: 'm01_reply_part_led_it',
          text:
              'Honestly, I led most of it: the research, the design and the sign-up fix. '
              'The others mainly helped out with the coding side of things.',
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
      id: 'm01_follow_one_example',
      trigger: Flag.vague,
      line: SceneLine(
        speakerId: priyaId,
        text: 'Can you give me one real example?',
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_example_sign_up',
          text:
              'Sure. In my project I interviewed twelve students, saw most of them quit '
              'at sign-up, and cut it from five screens to two.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_example_in_general',
          text:
              'The best example is really how I work in general: I always start from what '
              'users tell me, and then I let the data decide.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
        AnswerOption(
          id: 'm01_reply_example_list',
          text:
              'There are a few: my project, my internship, the café, a class assignment, '
              'and they all used data in slightly different ways…',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.rambling},
          lessonId: 'lesson_one_story',
        ),
      ],
    ),
    FollowUp(
      id: 'm01_follow_why_here',
      trigger: Flag.generic,
      line: SceneLine(
        speakerId: priyaId,
        text: 'A lot of people tell me that. Why this role, not any other product job?',
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_why_here_both',
          text:
              'Because here one person talks to users and reads the numbers. In most '
              'roles I looked at, those were two separate teams.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_why_here_growing',
          text:
              'Because Northstar is growing fast, and I want to be somewhere a new '
              'graduate can make a real impact early on, not just watch.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
        AnswerOption(
          id: 'm01_reply_why_here_replied',
          text:
              'Honestly, I applied to quite a few places, and Northstar was one of the '
              'first to reply and invite me in for a chat.',
          scores: DimensionScores(
            relevance: 0,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
      ],
    ),
    FollowUp(
      id: 'm01_follow_the_work',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: priyaId,
        text: "That's fair. But what about the work itself interests you?",
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_work_research',
          text:
              "The user research. I'd rather find out why people get stuck than guess, "
              "and in this role that's half of the job.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_work_learn',
          text:
              "Mostly the chance to learn from experienced people. I know I'd grow faster "
              "here than anywhere else I've applied to so far.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
        AnswerOption(
          id: 'm01_reply_work_anything',
          text:
              "I'm open to anything, really. I just enjoy working with technology and "
              'people, so most of the work sounds good to me.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
      ],
    ),
  ],
);
