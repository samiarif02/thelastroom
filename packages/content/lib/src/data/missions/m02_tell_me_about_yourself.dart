import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 2, "Tell Me About Yourself" (brief §6): Priya asks the oldest question there is.
///
/// The beats are present, past and future: what Jordan does now, one thing from before that
/// fits this job, and why this job is next. Relevance over life story: the tempting lines
/// start at the beginning, tour the whole CV or jump to a five-year plan.
const missionTellMeAboutYourself = Mission(
  id: 'm02_tell_me_about_yourself',
  chapter: 1,
  number: 2,
  title: 'Tell Me About Yourself',
  hinted: true,
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: "Welcome back, Jordan. Today it's one of the oldest questions there is.",
    ),
    SceneLine(
      speakerId: priyaId,
      text: "Keep it to about a minute. I'll stop you if I want more.",
    ),
  ],
  question: SceneLine(speakerId: priyaId, text: 'So, tell me about yourself.'),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'Why start there?'),
        reasons: [
          Reason(
            id: 'm02_open_why_fit_first',
            text: 'Start with what makes me fit this job, not with my whole life.',
            soundFor: {'m02_open_graduate'},
          ),
          Reason(
            id: 'm02_open_why_origin',
            text: 'A personal origin story makes me memorable from the first line.',
            tempts: {'m02_open_hometown'},
          ),
          Reason(
            id: 'm02_open_why_qualities',
            text: 'Naming my best qualities is the clearest way to introduce myself.',
            tempts: {'m02_open_adjectives'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Good, straight to the part that matters here.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Okay. Let's get to the bit about the job.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: 'Hold on, Jordan. You barely looked at those.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm02_open_graduate',
          text:
              "I've finished a degree in Information Systems, and the part I enjoyed most "
              'was user research: finding out why people get stuck.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm02_open_hometown',
          text:
              "I grew up in a small town where I was the one who fixed everyone's "
              "computers, and that's really where my love of technology began.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 2,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.rambling},
          lessonId: 'lesson_now_then_next',
        ),
        AnswerOption(
          id: 'm02_open_adjectives',
          text:
              "I'd describe myself as curious, hard-working and a good communicator, and "
              'I think those three words sum me up pretty well, honestly.',
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
        line: SceneLine(speakerId: priyaId, text: 'Why that example?'),
        reasons: [
          Reason(
            id: 'm02_evidence_why_one_result',
            text: 'One result I caused, with a number, proves more than a long list.',
            soundFor: {'m02_evidence_tickets'},
          ),
          Reason(
            id: 'm02_evidence_why_range',
            text: 'Covering everything on my CV shows the full range I offer.',
            tempts: {'m02_evidence_whole_cv'},
          ),
          Reason(
            id: 'm02_evidence_why_rounded',
            text: 'Life outside work shows the well-rounded person behind the CV.',
            tempts: {'m02_evidence_hobbies'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: '600 tickets and a quarter fewer. I like that.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Mm. I'd rather hear one thing properly.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: 'That was a quick pick. Read them, then choose.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm02_evidence_tickets',
          text:
              'At my Larkfield internship I tagged 600 support tickets, found a third '
              'were password resets, and wrote a help page that cut them by a quarter.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm02_evidence_whole_cv',
          text:
              "I've also worked at the campus café for two years, interned at Larkfield, "
              "built a study app and helped at open days, so I've done a real range.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.rambling},
          lessonId: 'lesson_one_story',
        ),
        AnswerOption(
          id: 'm02_evidence_hobbies',
          text:
              'Outside of work I play five-a-side football every Sunday, which keeps me '
              "balanced, and I think it's made me really good in a team.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'And why end on that?'),
        reasons: [
          Reason(
            id: 'm02_land_why_connect',
            text:
                'End by connecting who I am to what the role does day to day.',
            soundFor: {'m02_land_this_role'},
          ),
          Reason(
            id: 'm02_land_why_ambition',
            text: 'A long-term career plan shows ambition and commitment.',
            tempts: {'m02_land_five_years'},
          ),
          Reason(
            id: 'm02_land_why_inviting',
            text: "Inviting questions at the end shows I'm open and easy to talk to.",
            tempts: {'m02_land_trail'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'There it is: users and numbers. Nicely done.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Hm. Let's bring it back to this role.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: 'You rushed that ending, Jordan. Take a second.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm02_land_this_role',
          text:
              'Now I want a job where I talk to users and read the numbers every day, '
              'which is exactly what this Product Associate role is.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm02_land_five_years',
          text:
              'In five years I see myself leading a product team, and I think Northstar '
              'is the right place to build towards that kind of future.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_answer_the_question',
        ),
        AnswerOption(
          id: 'm02_land_trail',
          text:
              "And that's me, really. I'm not sure what else you'd like to know, so "
              'please feel free to ask me anything about my CV.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 1,
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
      id: 'm02_follow_why_product',
      line: SceneLine(
        speakerId: priyaId,
        text: 'Nice and clear. Why product, after an internship in support?',
      ),
      replies: [
        AnswerOption(
          id: 'm02_reply_product_cause',
          text:
              'Support showed me the same problems every day, and I kept wanting to fix '
              "the cause, not just answer the ticket. That's product work.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm02_reply_product_decisions',
          text:
              'Product is where the big decisions get made, and I want to be in the room '
              'where that happens, not just answering tickets.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
        AnswerOption(
          id: 'm02_reply_product_pay',
          text:
              "Honestly, support roles don't pay very well, and product has a much "
              'clearer path up, so it felt like the smarter move for me to make.',
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
      id: 'm02_follow_pick_one',
      trigger: Flag.rambling,
      line: SceneLine(
        speakerId: priyaId,
        text: 'Let me stop you there. If you had to pick one thing, what would it be?',
      ),
      replies: [
        AnswerOption(
          id: 'm02_reply_one_tickets',
          text:
              'The support tickets. Finding that one in three were password resets, and '
              'fixing the cause, is the work I want to keep doing.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm02_reply_one_all_three',
          text:
              'Probably my study app, my internship and the café together, because each '
              'one shows a different side of me, if that makes sense.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.rambling},
          lessonId: 'lesson_one_story',
        ),
        AnswerOption(
          id: 'm02_reply_one_people_skills',
          text:
              "I'd say my people skills in general. They've helped me in every job and "
              "project I've done, so that's the main thing for me.",
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
      id: 'm02_follow_the_job',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: priyaId,
        text: "Let's stay on work. How does that connect to this job?",
      ),
      replies: [
        AnswerOption(
          id: 'm02_reply_job_cafe',
          text:
              'Fair point. The café taught me to stay calm with upset customers, and in '
              "this role I'd be talking to frustrated users every week.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm02_reply_job_teamwork',
          text:
              'Well, team sport teaches you teamwork and resilience, and those are skills '
              'any good employer is looking for, including Northstar.',
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
          id: 'm02_reply_job_who_i_am',
          text:
              "It doesn't directly, I suppose. I just wanted you to get a sense of who I "
              'am as a person, outside of my CV.',
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
  ],
);
