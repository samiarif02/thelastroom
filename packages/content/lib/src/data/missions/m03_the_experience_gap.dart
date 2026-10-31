import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 3, "The Experience Gap" (brief §6): Priya names the gap between Jordan and the
/// rest of the shortlist.
///
/// The first recall checkpoint: no hint cards (FR-30), and the distractors repeat the mistakes
/// Missions 1 and 2 taught ("we", the over-promise, the trailing end). Passing it unhinted with
/// relevance of [clearIntroductionsMinRelevance] or more unlocks *Clear Introductions*.
const missionTheExperienceGap = Mission(
  id: 'm03_the_experience_gap',
  chapter: 1,
  number: 3,
  title: 'The Experience Gap',
  hinted: false,
  skillRequirements: [
    SkillRequirement(
      skill: Skill.clearIntroductions,
      dimension: Dimension.relevance,
      minScore: clearIntroductionsMinRelevance,
    ),
  ],
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: "Jordan, I'll be straight with you about where you stand.",
    ),
    SceneLine(
      speakerId: priyaId,
      text:
          'Most people on our shortlist have two or three years of experience.',
    ),
  ],
  question: SceneLine(
    speakerId: priyaId,
    text: 'Why should we take a chance on a graduate?',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'Why answer it that way?'),
        reasons: [
          Reason(
            id: 'm03_open_why_both_halves',
            text: "It admits the concern, then shows I've done both halves of the job.",
            soundFor: {'m03_open_fair_concern'},
          ),
          Reason(
            id: 'm03_open_why_fresh',
            text: 'It turns my lack of experience into a fresh perspective.',
            soundFor: {'m03_open_fresh_eyes'},
          ),
          Reason(
            id: 'm03_open_why_modest',
            text: "It's modest, so I don't come across as arrogant.",
            soundFor: {'m03_open_not_strongest'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Good. You took the worry seriously.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: 'Hm. Most graduates say something like that.',
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: 'Slow down. That question deserves a real pick.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm03_open_fair_concern',
          text:
              "That's a fair concern. I don't have years of experience, but I've already "
              'done both halves of this job: users and numbers.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm03_open_fresh_eyes',
          text:
              "I'd say experience isn't everything. A graduate brings fresh eyes and new "
              'ideas, without the bad habits people pick up over the years.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_own_the_gap',
        ),
        AnswerOption(
          id: 'm03_open_not_strongest',
          text:
              "I know I'm probably not the strongest candidate on paper, and I'd "
              'completely understand if you went with someone more experienced.',
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
    Beat(
      kind: BeatKind.evidence,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'Why that example?'),
        reasons: [
          Reason(
            id: 'm03_evidence_why_own_work',
            text: "It's my own work, with a number that changed because of it.",
            soundFor: {'m03_evidence_tickets'},
          ),
          Reason(
            id: 'm03_evidence_why_big_result',
            text: "It's a big result, with real numbers behind it.",
            soundFor: {'m03_evidence_we_project'},
          ),
          Reason(
            id: 'm03_evidence_why_trusted',
            text: 'It shows people trust me quickly wherever I go.',
            soundFor: {'m03_evidence_quick_learner'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: "Your help page, your number. That's convincing.",
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: 'I still need to hear what you did, Jordan.',
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: 'You picked before reading. Want another look?',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm03_evidence_tickets',
          text:
              'At Larkfield I tagged 600 support tickets myself, found one in three were '
              'password resets, and my help page cut those by a quarter.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm03_evidence_we_project',
          text:
              'Our final-year team took a real app from idea to launch, interviewed '
              'twelve students, and we raised finished sign-ups from 40% to 75%.',
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
          id: 'm03_evidence_quick_learner',
          text:
              "I pick things up quickly. In every job and project I've had so far, I was "
              'trusted with real responsibility within a couple of weeks.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
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
        line: SceneLine(speakerId: priyaId, text: 'Why close on that?'),
        reasons: [
          Reason(
            id: 'm03_land_why_gap',
            text: "It names my gap and shows how I'm already closing it.",
            soundFor: {'m03_land_closing_gap'},
          ),
          Reason(
            id: 'm03_land_why_commitment',
            text: "It shows how committed I'll be.",
            soundFor: {'m03_land_work_harder'},
          ),
          Reason(
            id: 'm03_land_why_open',
            text: 'It leaves room for whatever the team needs.',
            soundFor: {'m03_land_trail'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Halfway through SQL already. Good answer.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Hm. That doesn't quite answer my worry.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: "Don't rush the close. It's what I'll remember.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm03_land_closing_gap',
          text:
              "Where I'm still new, like big datasets, I'm closing the gap: I'm halfway "
              "through an SQL course, and I'd ask for reviews early.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm03_land_work_harder',
          text:
              "And I promise nobody on that shortlist will work harder than me. I'll be "
              'the first one in every morning and the last one to leave.',
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
          id: 'm03_land_trail',
          text:
              "So I think that's why, mostly. Although I suppose it depends on what the "
              "team needs right now, which I don't fully know yet…",
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
      id: 'm03_follow_first_months',
      line: SceneLine(
        speakerId: priyaId,
        text: 'Fine. What would you need from us in your first three months?',
      ),
      replies: [
        AnswerOption(
          id: 'm03_reply_months_review',
          text:
              "A clear first project and someone to review my SQL early. I'd rather hear "
              "what's wrong in week two than in month three.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm03_reply_months_independent',
          text:
              "Honestly, not much. I'm very independent, so you could give me a project "
              "and I'd figure it out without taking up anyone's time.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_promise_the_habit',
        ),
        AnswerOption(
          id: 'm03_reply_months_salary',
          text:
              'Mostly a fair salary and some flexibility on remote days, so I can keep my '
              'weekends free for football and family.',
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
      id: 'm03_follow_why_you',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: priyaId,
        text: "You're arguing my side for me. Why are you worth the chance?",
      ),
      replies: [
        AnswerOption(
          id: 'm03_reply_worth_both_halves',
          text:
              "Because I've done this job's two halves already: I talked to twelve "
              'students for my project and read 600 support tickets at Larkfield.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm03_reply_worth_attitude',
          text:
              "Because experience can be taught, but attitude can't, and I think my "
              'attitude is the thing that really sets me apart from the rest.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_own_the_gap',
        ),
        AnswerOption(
          id: 'm03_reply_worth_start_now',
          text:
              "I suppose because I'm available to start straight away, and I'm flexible "
              'on the salary, if that helps your decision at all.',
          scores: DimensionScores(
            relevance: 1,
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
      id: 'm03_follow_your_part',
      trigger: Flag.weNotI,
      line: SceneLine(
        speakerId: priyaId,
        text: 'Your team did well. What was your part in it?',
      ),
      replies: [
        AnswerOption(
          id: 'm03_reply_part_research',
          text:
              'I ran all twelve interviews and designed the two-screen sign-up. Two '
              'teammates built the back end, and one built the screens.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm03_reply_part_glue',
          text:
              'I was more the glue of the team, really: keeping everyone on track, '
              'running our meetings, and making sure we hit every deadline.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
        AnswerOption(
          id: 'm03_reply_part_shared',
          text:
              "Honestly, it's hard to separate. We made every decision together as four, "
              'so it really was a shared result in the end.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
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

/// The relevance (0–100) an unhinted Mission 3 needs to unlock *Clear Introductions*: most
/// lines must answer the question Priya asked.
const int clearIntroductionsMinRelevance = 80;
