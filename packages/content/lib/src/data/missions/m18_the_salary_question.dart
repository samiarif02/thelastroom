import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 18, "The Salary Question" (brief §6, brief 38): Priya asks what Jordan expects to
/// be paid.
///
/// A choices mission: the traps are easiest to see side by side. The strong answer gives a
/// range from what similar roles pay, says where Jordan sits in it and why, and stays open on
/// the whole package. The tempting lines name one number too early (too low or too high),
/// leave the number to Priya, argue from Jordan's rent, or give the range away again.
///
/// The range is written in words. The character sheet's figures are Jordan's CV; a salary
/// range is research, not a fact about Jordan, and only this mission quotes one.
const missionTheSalaryQuestion = Mission(
  id: 'm18_the_salary_question',
  chapter: 3,
  number: 18,
  title: 'The Salary Question',
  practises: 'Answering the salary question with a range you can explain, not a guess.',
  hinted: true,
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: "Jordan, before you see Sam again, there's the practical bit.",
    ),
    SceneLine(
      speakerId: priyaId,
      text: "I ask everyone this, so don't read anything into it.",
    ),
  ],
  question: SceneLine(
    speakerId: priyaId,
    text: 'What salary are you expecting for this role?',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'Why answer it like that?'),
        reasons: [
          Reason(
            id: 'm18_open_why_research',
            text: 'Research means I can name pay with a reason, not a hunch.',
            soundFor: {'m18_open_researched'},
          ),
          Reason(
            id: 'm18_open_why_easy',
            text: 'Showing I am easy to please makes me a safer hire.',
            tempts: {'m18_open_lowball'},
          ),
          Reason(
            id: 'm18_open_why_polite',
            text:
                'Leaving the number to them is the polite way to handle money.',
            tempts: {'m18_open_whatever_fair'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Good. A range is something I can work with.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Hm. That doesn't help me much, Jordan.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: "Slow down. Money's worth a careful pick.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm18_open_researched',
          text:
              "I've looked at what graduate product roles pay in the city, so I can give "
              'you a range rather than one number.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm18_open_lowball',
          text:
              'Twenty-eight thousand would be fine for me, honestly. I am mainly just happy '
              'to be getting a real start in product.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_researched_range',
        ),
        AnswerOption(
          id: 'm18_open_whatever_fair',
          text:
              "I'm not fussy about money. Whatever you think is fair for someone at my "
              'level would be fine with me.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_price_the_role',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'Why that number?'),
        reasons: [
          Reason(
            id: 'm18_evidence_why_placed',
            text: 'A range from real pay data, placed by what I bring, is easy to defend.',
            soundFor: {'m18_evidence_upper_half'},
          ),
          Reason(
            id: 'm18_evidence_why_costs',
            text: 'Pay has to cover my costs, so my costs are the place to start.',
            tempts: {'m18_evidence_rent'},
          ),
          Reason(
            id: 'm18_evidence_why_anchor',
            text: 'Starting high leaves plenty of room to come down later.',
            tempts: {'m18_evidence_start_high'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Researched, and you know where you sit. Helpful.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "I'd need a reason behind that number.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: 'You picked before reading. Look again.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm18_evidence_upper_half',
          text:
              'Similar roles mostly pay thirty to thirty-four thousand. With my internship '
              "and my project work, I'd aim for the upper half.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm18_evidence_rent',
          text:
              'Rent near the office is high, so realistically I would need at least '
              'thirty-five thousand a year to make the move work for me.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_price_the_role',
        ),
        AnswerOption(
          id: 'm18_evidence_start_high',
          text:
              "I've heard some product people earn fifty thousand, so I'd start at about "
              'forty-five and see where we end up.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_researched_range',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      why: ReasonPrompt(
        line: SceneLine(speakerId: priyaId, text: 'Why end there?'),
        reasons: [
          Reason(
            id: 'm18_land_why_package',
            text: 'Being open on the package keeps us talking without dropping my range.',
            soundFor: {'m18_land_whole_package'},
          ),
          Reason(
            id: 'm18_land_why_keen',
            text: "Saying I'd take less shows how much I want the role.",
            tempts: {'m18_land_take_less'},
          ),
          Reason(
            id: 'm18_land_why_list',
            text: 'Listing everything that matters to me means nothing gets forgotten.',
            tempts: {'m18_land_it_depends'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: priyaId,
          text: 'Open, but not a pushover. Good.',
        ),
        weak: SceneLine(
          speakerId: priyaId,
          text: "Hm. I'm not sure where that leaves us.",
        ),
        guessed: SceneLine(
          speakerId: priyaId,
          text: "Rushed. Money's the last thing to rush.",
        ),
      ),
      options: [
        AnswerOption(
          id: 'm18_land_whole_package',
          text:
              "But the role matters most, so I'm open on the package as a whole: "
              'training, reviews, and when pay is next looked at.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm18_land_take_less',
          text:
              "But honestly, I'd take less if I had to. I just really want this job, so "
              "please don't let money put you off.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_researched_range',
        ),
        AnswerOption(
          id: 'm18_land_it_depends',
          text:
              'Although it depends, I suppose, on the hours, and the pension, and whether '
              "there's a bonus, and the holidays, so maybe…",
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
      id: 'm18_follow_under_that',
      line: SceneLine(
        speakerId: priyaId,
        text: 'And if the offer came in a little under that?',
      ),
      replies: [
        AnswerOption(
          id: 'm18_reply_under_package',
          text:
              "I'd look at the whole package first: training, reviews, when pay is next "
              "looked at. Then I'd give you a clear answer.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm18_reply_under_accept',
          text:
              "Then I'd take it straight away, honestly. I'd much rather have the job "
              'than end up arguing with you about the money.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_researched_range',
        ),
        AnswerOption(
          id: 'm18_reply_under_rent',
          text:
              'Then I would struggle, because my rent near the office is high, so I '
              "really couldn't go any lower than that, I'm afraid.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_price_the_role',
        ),
      ],
    ),
    FollowUp(
      id: 'm18_follow_where_from',
      trigger: Flag.vague,
      line: SceneLine(
        speakerId: priyaId,
        text: 'Where does that number come from?',
      ),
      replies: [
        AnswerOption(
          id: 'm18_reply_from_ads',
          text:
              'Job ads and salary sites for graduate product roles in the city. My '
              'internship and project put me in the upper half.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm18_reply_from_feel',
          text:
              "It just felt about right for a first job in product. I didn't want to aim "
              'too high, or too low either.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_researched_range',
        ),
        AnswerOption(
          id: 'm18_reply_from_bills',
          text:
              "It's what I'd need to cover rent and travel, so it's really the lowest I "
              'could manage each month.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_price_the_role',
        ),
      ],
    ),
    FollowUp(
      id: 'm18_follow_your_range',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: priyaId,
        text: 'I asked what you expect, Jordan. What is your range?',
      ),
      replies: [
        AnswerOption(
          id: 'm18_reply_range_named',
          text:
              'Thirty to thirty-four thousand, from what similar roles pay. With my '
              "internship, I'd hope for the upper half.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm18_reply_range_offer_first',
          text:
              "I'd honestly rather you made me an offer first, and then we can see where "
              'we both are with it.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_price_the_role',
        ),
        AnswerOption(
          id: 'm18_reply_range_market',
          text:
              'Something competitive for a graduate role, I suppose, in line with what '
              "the market's paying now.",
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_researched_range',
        ),
      ],
    ),
  ],
);
