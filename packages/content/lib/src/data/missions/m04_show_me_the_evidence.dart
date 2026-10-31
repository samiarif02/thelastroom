import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 4, "Show Me the Evidence" (brief §6): Marcus wants the details.
///
/// "I" versus "we": the tempting lines tell the right story in the team's voice, and a "we"
/// or a vague pick brings Marcus's "What did *you* do?" or "How many?". Jordan's Larkfield
/// internship is the story; the help page was Jordan's, the reset link an engineer's.
const missionShowMeTheEvidence = Mission(
  id: 'm04_show_me_the_evidence',
  chapter: 1,
  number: 4,
  title: 'Show Me the Evidence',
  hinted: true,
  scene: [
    SceneLine(
      speakerId: marcusId,
      text: "I'm Marcus. I run the product team, so I'll want the details.",
    ),
    SceneLine(
      speakerId: marcusId,
      text: "Priya says you can talk. Let's see what's underneath it.",
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell me about a time you used data to change something.',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: marcusId, text: 'Why start there?'),
        reasons: [
          Reason(
            id: 'm04_open_why_mine',
            text: 'Open with the specific problem I noticed, so the story is clearly mine.',
            soundFor: {'m04_open_same_question'},
          ),
          Reason(
            id: 'm04_open_why_collaborative',
            text: "Starting with the team shows I'm collaborative, which every manager wants.",
            tempts: {'m04_open_team_realised'},
          ),
          Reason(
            id: 'm04_open_why_frame',
            text: 'Stating my approach first frames the example the right way.',
            tempts: {'m04_open_data_lead'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: 'Fine. You noticed something. Go on.',
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: "Noted. I'll need you and a number.",
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'That took under two seconds. Read them.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm04_open_same_question',
          text:
              'At my Larkfield internship, I noticed the support team kept answering the '
              'same question, so I decided to count how often it came up.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm04_open_team_realised',
          text:
              'During my internship our support team realised we had a problem with '
              'repeated questions, so we decided to look into the data together.',
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
          id: 'm04_open_data_lead',
          text:
              "I'm someone who always lets the data lead, and my Larkfield internship was "
              'a great example of putting that approach into practice.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.generic},
          lessonId: 'lesson_why_this_role',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      why: ReasonPrompt(
        line: SceneLine(speakerId: marcusId, text: 'Why those details?'),
        reasons: [
          Reason(
            id: 'm04_evidence_why_numbers',
            text: 'He asked about data, so give the actual numbers and what I did with them.',
            soundFor: {'m04_evidence_tagged'},
          ),
          Reason(
            id: 'm04_evidence_why_share_credit',
            text:
                'Sharing credit with the team is the professional thing to do.',
            tempts: {'m04_evidence_we_cut'},
          ),
          Reason(
            id: 'm04_evidence_why_summary',
            text: 'Summarising the findings is clearer than burying him in figures.',
            tempts: {'m04_evidence_patterns'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: '600 tickets, one in three. Good. Numbers.',
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: "I'd want the actual count. And whose it was.",
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'Too quick to have read them. Again, slowly.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm04_evidence_tagged',
          text:
              'I tagged 600 tickets from one month in a spreadsheet. One in three were '
              'password resets, so I wrote a step-by-step help page for them.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm04_evidence_we_cut',
          text:
              'We went through a month of tickets, found password resets were the biggest '
              'group, and then we cut those by a quarter with a help page.',
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
          id: 'm04_evidence_patterns',
          text:
              'I looked through a lot of tickets and found some really clear patterns, '
              'mostly around logins, so I suggested some improvements to the team.',
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
        line: SceneLine(speakerId: marcusId, text: 'Why end there?'),
        reasons: [
          Reason(
            id: 'm04_land_why_measured',
            text: "Close with the measured result and what I'd carry into this job.",
            soundFor: {'m04_land_quarter'},
          ),
          Reason(
            id: 'm04_land_why_big_claim',
            text: 'Big claims about impact are what make an answer memorable.',
            tempts: {'m04_land_huge_impact'},
          ),
          Reason(
            id: 'm04_land_why_everyone_happy',
            text:
                'Ending on how pleased everyone was proves the work went well.',
            tempts: {'m04_land_team_proud'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: 'A quarter fewer, and a lesson. That I believe.',
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: "That's a claim, not a result.",
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'You rushed the ending. Results matter most.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm04_land_quarter',
          text:
              'The next month, password tickets fell by a quarter. It taught me to count '
              "before I suggest anything, and I'd do the same here.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm04_land_huge_impact',
          text:
              "It ended up saving the company a huge amount of time and money, and I'm "
              'confident I could deliver that kind of impact for you too.',
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
          id: 'm04_land_team_proud',
          text:
              'Everyone in the team was really happy with how it turned out, and I think '
              'we all learned a lot from working on it together.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
      ],
    ),
  ],
  followUps: [
    FollowUp(
      id: 'm04_follow_differently',
      line: SceneLine(
        speakerId: marcusId,
        text: 'Fine. What would you do differently with that data now?',
      ),
      replies: [
        AnswerOption(
          id: 'm04_reply_differently_month',
          text:
              "I'd tag a second month too. One month might have been unusual, so I'd "
              'check the pattern holds before anyone builds a fix.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm04_reply_differently_nothing',
          text:
              "Honestly, I'm not sure I'd change much. The results spoke for themselves, "
              'and the team was very happy with what we achieved.',
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
          id: 'm04_reply_differently_tools',
          text:
              "I'd probably use more advanced tools and look at more data overall, to get "
              'an even fuller and more accurate picture of it all.',
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
      id: 'm04_follow_what_you_did',
      trigger: Flag.weNotI,
      line: SceneLine(
        speakerId: marcusId,
        text: "You keep saying 'we'. What did you do?",
      ),
      replies: [
        AnswerOption(
          id: 'm04_reply_did_tagged',
          text:
              'I tagged all 600 tickets and wrote the help page. My lead approved it, and '
              'an engineer later added a reset link to the login screen.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm04_reply_did_drove_it',
          text:
              "I'd say I drove it. I spotted the problem, led the analysis and pushed the "
              'fix through, so it was really my project from start to finish.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_share_the_credit',
        ),
        AnswerOption(
          id: 'm04_reply_did_team_effort',
          text:
              "It was a real team effort. Everyone played their part, and I'd feel "
              'uncomfortable taking the credit for what we did together.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.weNotI},
          lessonId: 'lesson_name_your_part',
        ),
      ],
    ),
    FollowUp(
      id: 'm04_follow_how_many',
      trigger: Flag.vague,
      line: SceneLine(
        speakerId: marcusId,
        text: "'A lot of tickets.' How many? And what changed?",
      ),
      replies: [
        AnswerOption(
          id: 'm04_reply_many_600',
          text:
              '600 tickets from one month. A third were password resets, and after my '
              'help page went live, those fell by a quarter.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm04_reply_many_significant',
          text:
              'Quite a large number, honestly, and the change was significant. The whole '
              'team noticed a real difference within a few weeks.',
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
          id: 'm04_reply_many_guess',
          text:
              "I think it was thousands, and I'd guess the drop was about half, but I'd "
              'have to go back and check my old notes to be sure.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
      ],
    ),
  ],
);
