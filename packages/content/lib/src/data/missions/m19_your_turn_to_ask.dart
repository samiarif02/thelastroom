import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 19, "Your Turn to Ask" (brief §6, brief 38): Sam hands the interview over.
///
/// A choices mission: choosing good questions is the skill. The beats are three questions in
/// the order Jordan would ask them: one that shows Jordan listened (Sam's sign-up problem from
/// Mission 15), one about doing the job well, and a last one that invites Sam's doubts. The
/// tempting lines ask what the website already says, ask what the job gives Jordan, or cram
/// in everything at the end.
const missionYourTurnToAsk = Mission(
  id: 'm19_your_turn_to_ask',
  chapter: 3,
  number: 19,
  title: 'Your turn to ask',
  practises: 'Asking questions that show you listened and that you care about the work.',
  hinted: true,
  scene: [
    SceneLine(speakerId: samId, text: "That's all from me. Thank you, Jordan."),
    SceneLine(
      speakerId: samId,
      text: 'The last few minutes are yours. I mean that.',
    ),
  ],
  question: SceneLine(speakerId: samId, text: 'What would you like to ask me?'),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: samId, text: 'Why ask that first?'),
        reasons: [
          Reason(
            id: 'm19_open_why_listened',
            text: 'Picking up something said today shows I listened and care about the work.',
            soundFor: {'m19_open_sign_up_drop'},
          ),
          Reason(
            id: 'm19_open_why_fit_in',
            text: 'Asking about culture shows I care about fitting in.',
            tempts: {'m19_open_values'},
          ),
          Reason(
            id: 'm19_open_why_practical',
            text: 'Getting the practical details early saves everyone time later.',
            tempts: {'m19_open_holidays'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(speakerId: samId, text: 'You were listening. Good.'),
        weak: SceneLine(
          speakerId: samId,
          text: "Hm. That's not really a question for me.",
        ),
        guessed: SceneLine(
          speakerId: samId,
          text: 'Quick. Take your time with this part.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm19_open_sign_up_drop',
          text:
              'You mentioned sign-ups fell last month. What did the team find, and would '
              'this role work on it?',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm19_open_values',
          text:
              "What are the company's values, and how would you describe the everyday "
              'culture here at Northstar Labs?',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_ask_what_only_they_know',
        ),
        AnswerOption(
          id: 'm19_open_holidays',
          text:
              'How many holiday days does the role come with, and how many days a week '
              'could I work from home?',
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_ask_about_the_work',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      why: ReasonPrompt(
        line: SceneLine(speakerId: samId, text: 'Why that one next?'),
        reasons: [
          Reason(
            id: 'm19_evidence_why_success',
            text: 'Asking what a good start looks like shows I am already thinking about the job.',
            soundFor: {'m19_evidence_first_months'},
          ),
          Reason(
            id: 'm19_evidence_why_big_picture',
            text:
                'A big-picture question shows ambition and long-term thinking.',
            tempts: {'m19_evidence_five_years'},
          ),
          Reason(
            id: 'm19_evidence_why_driven',
            text: 'Showing I want to grow fast makes me sound driven.',
            tempts: {'m19_evidence_move_up'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: samId,
          text: "Good question. I'll answer it properly.",
        ),
        weak: SceneLine(
          speakerId: samId,
          text: "Hm. That's one for later, I think.",
        ),
        guessed: SceneLine(
          speakerId: samId,
          text: "You didn't read them all. Try again.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm19_evidence_first_months',
          text:
              'At Larkfield, knowing my first project early helped most. What would a good '
              'first three months look like here?',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm19_evidence_five_years',
          text:
              "Where do you see Northstar Labs in five years' time, and how does the "
              'product team fit into that bigger picture?',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_ask_what_only_they_know',
        ),
        AnswerOption(
          id: 'm19_evidence_move_up',
          text:
              'How soon could someone in this role move up to a more senior position, if '
              'they did really well?',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_ask_about_the_work',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      why: ReasonPrompt(
        line: SceneLine(speakerId: samId, text: 'Why end on that?'),
        reasons: [
          Reason(
            id: 'm19_land_why_doubts',
            text: "Inviting their doubts lets me answer them before I've left the room.",
            soundFor: {'m19_land_any_doubts'},
          ),
          Reason(
            id: 'm19_land_why_result',
            text: 'Asking about my chances shows I care about the result.',
            tempts: {'m19_land_how_did_i_do'},
          ),
          Reason(
            id: 'm19_land_why_squeeze',
            text:
                'Squeezing in every last question gets the most from the time.',
            tempts: {'m19_land_one_more'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: samId,
          text: "Brave, and fair. I'll tell you straight.",
        ),
        weak: SceneLine(
          speakerId: samId,
          text: 'Hm. Not the strongest way to finish.',
        ),
        guessed: SceneLine(
          speakerId: samId,
          text: "Don't rush your last question.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm19_land_any_doubts',
          text:
              "Is there anything from today that makes you unsure about me? If it's SQL, "
              "I'm halfway through a course.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm19_land_how_did_i_do',
          text:
              'So how do you think I did today? Honestly, do you think I have a good '
              'chance of getting it?',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_ask_about_the_work',
        ),
        AnswerOption(
          id: 'm19_land_one_more',
          text:
              'And one more, sorry: the data side, and also the team, and how it all fits '
              'with the engineers, if there is time…',
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
      id: 'm19_follow_learn_first',
      line: SceneLine(
        speakerId: samId,
        text: 'Good. Before you go: what would you want to learn first here?',
      ),
      replies: [
        AnswerOption(
          id: 'm19_reply_learn_tests',
          text:
              "How you size and read tests. I'm halfway through an SQL course, and I'd "
              'want the data team checking my first queries.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm19_reply_learn_sponge',
          text:
              "Everything, honestly. I'm a sponge, and I'd want to soak up as much as I "
              'possibly can from everyone here.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_talk_like_yourself',
        ),
        AnswerOption(
          id: 'm19_reply_learn_promotion',
          text:
              'Mostly how reviews and promotions work here, so I can plan my next step '
              'up from the very start.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_ask_about_the_work',
        ),
      ],
    ),
    FollowUp(
      id: 'm19_follow_website',
      trigger: Flag.generic,
      line: SceneLine(
        speakerId: samId,
        text: "That's on our website. What do you actually want to know?",
      ),
      replies: [
        AnswerOption(
          id: 'm19_reply_website_drop',
          text:
              "Fair. What did the team find behind last month's sign-up drop, and would "
              'I be working on it?',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm19_reply_website_different',
          text:
              'Then maybe what makes Northstar Labs different from the other companies '
              'doing similar things?',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_ask_what_only_they_know',
        ),
        AnswerOption(
          id: 'm19_reply_website_hours',
          text:
              'Then mainly the hours, really, and whether the role is flexible about '
              'working from home.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_ask_about_the_work',
        ),
      ],
    ),
    FollowUp(
      id: 'm19_follow_the_work',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: samId,
        text: 'Priya can cover that. What do you want to know about the work?',
      ),
      replies: [
        AnswerOption(
          id: 'm19_reply_work_first_project',
          text:
              'What a good first project looks like here. At Larkfield, knowing mine early '
              'is what helped me most.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm19_reply_work_typical_day',
          text:
              'What a typical day looks like, I suppose, and what the team culture is '
              'like, day to day.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_ask_what_only_they_know',
        ),
        AnswerOption(
          id: 'm19_reply_work_bonus',
          text:
              'Mainly whether there is a bonus, since that would really help me decide '
              'between offers.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_ask_about_the_work',
        ),
      ],
    ),
  ],
);
