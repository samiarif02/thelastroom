import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 1, "The Opportunity" (brief §6): Priya asks why you applied.
///
/// The baseline every later score is compared with (FR-30), so it is unhinted and untimed, and
/// no model answer is shown before it. The role is a general entry-level product job, the
/// Product Associate at Northstar Labs; Priya's setup names its two halves (users and numbers)
/// so a strong answer has something concrete to tie back to.
///
/// Scores are 0–3 on relevance, specificity, structure and adaptability. Beat lines carry 0
/// adaptability: only the follow-up reply earns it. The PR for brief 04 has the review table:
/// every line, its scores and flags, and why.
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
      text:
          "Hi, thanks for coming in. I'm Priya, and I hire for the product team here at "
          'Northstar Labs.',
    ),
    SceneLine(
      speakerId: priyaId,
      text:
          'The Product Associate role is mostly two things: talking to users and reading the '
          'numbers, so the team knows what to build next.',
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
      options: [
        AnswerOption(
          id: 'm01_open_role_fit',
          text:
              'I applied because I like finding out why people get stuck in a product, and '
              'this role does that with real users and real data.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm01_open_great_company',
          text:
              "I've always been passionate about technology, and Northstar is a great "
              'company with an amazing culture.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
        AnswerOption(
          id: 'm01_open_first_job',
          text:
              "To be honest, I'm looking for my first full-time job, and the location and "
              'benefits here are really good.',
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
          id: 'm01_open_cv_words',
          text:
              'I am a highly motivated, detail-oriented team player who is eager to learn and '
              'grow in a fast-paced environment.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.memorized, Flag.generic},
          lessonId: 'lesson_talk_like_yourself',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      options: [
        AnswerOption(
          id: 'm01_evidence_sign_up',
          text:
              'In my final-year project, I interviewed twelve students who used our study app. '
              'Most gave up at sign-up, so I cut it from five screens to two, and finished '
              'sign-ups went from 40% to 75%.',
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
              'In my final-year project, we interviewed students about our study app, and we '
              'cut the sign-up from five screens to two.',
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
          id: 'm01_evidence_lots_of_projects',
          text:
              "I've done a lot of projects where I worked with users and data, so I have good "
              'experience with this kind of work.',
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
              'So it started in my second year, when I joined a coding club, and then a friend '
              'asked me to help with an app, and we tried a few ideas, and later I took a data '
              'course, which was also really interesting…',
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
      options: [
        AnswerOption(
          id: 'm01_land_bring_habit',
          text:
              "That's the work I want to do every day, and I'd bring the same habit here: "
              'talk to users first, then check the numbers to see if it worked.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm01_land_learn_and_grow',
          text:
              'I think this role would be a great opportunity for me to learn a lot and grow '
              'my career.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
        AnswerOption(
          id: 'm01_land_any_role',
          text:
              "Honestly, I'd be happy in any role here. I just really want to get my foot in "
              'the door.',
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
              "So yes, that's basically it, I think. Unless you want to hear about my other "
              'projects too, because there are a few more…',
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
        text:
            "Thanks, that's clear. What do you think will be the hardest part of this job "
            'for you?',
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_hardest_big_data',
          text:
              "Working with large company data. I've only used small datasets, so I've started "
              "an SQL course, and I'd ask someone on the data team to check my first queries.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_hardest_nothing',
          text: "I don't think anything will be too hard. I'm a fast learner and a hard worker.",
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
          id: 'm01_reply_hardest_technical',
          text: "Maybe some of the technical parts, but I'm sure I'll figure it out.",
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
              'I ran the twelve interviews myself and designed the new two-screen sign-up. Two '
              'teammates built the back end.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_part_team_effort',
          text: 'We all did everything together, really. It was a team effort.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
        AnswerOption(
          id: 'm01_reply_part_bit_of_all',
          text:
              'I did a bit of everything: the design, the testing, the meetings, the '
              'presentation, and some of the code as well.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
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
              'Sure. In my final-year project I interviewed twelve students, saw most of them '
              'quit at sign-up, and cut it from five screens to two.',
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
              'Well, in general I always try to listen to users and use data in everything I '
              'do.',
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
          id: 'm01_reply_example_list',
          text:
              'There are many, like my club app, my internship, a class project and some '
              'freelance work, and they all used data in different ways…',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 0,
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
        text: 'A lot of people tell me that. Why this role, and not any other product job?',
      ),
      replies: [
        AnswerOption(
          id: 'm01_reply_why_here_both',
          text:
              'Because here the same person talks to users and reads the numbers. In most '
              'roles I looked at, those are two different teams.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_why_here_values',
          text:
              "Northstar is a leader in the industry, and I really admire the company's "
              'values.',
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
              'Honestly, I applied to a lot of places, and Northstar was one of the first to '
              'reply.',
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
              "The user research. I'd rather find out why people get stuck than guess, and "
              'this role is built around that.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm01_reply_work_perks',
          text: 'The salary and the hybrid schedule are big reasons too, to be honest.',
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
          id: 'm01_reply_work_anything',
          text: "I'm open to anything, really. I just like working with technology.",
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
