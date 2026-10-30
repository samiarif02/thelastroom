import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 6, "The Follow-Up Trap" (brief §6): Lena picks up the story Jordan told Marcus.
///
/// Continuity (FR-30): Lena quotes the Mission 5 beat line that cost the most
/// ([Continuity.lineFor]) and challenges it: one variant per Mission 5 beat line that can cost
/// the most (a perfect evidence or land line never can: ties go to the earliest beat). The beats
/// are the same whichever line she quotes: keep the story straight, add detail, own it. The
/// tempting lines rewrite the story under pressure.
const missionTheFollowUpTrap = Mission(
  id: 'm06_the_follow_up_trap',
  chapter: 1,
  number: 6,
  title: 'The Follow-Up Trap',
  hinted: true,
  scene: [
    SceneLine(
      speakerId: lenaId,
      text: "I'm Lena. I build what the product team decides on, so I check details.",
    ),
    SceneLine(
      speakerId: lenaId,
      text: 'Marcus told me about your report story.',
    ),
  ],
  question: SceneLine(
    speakerId: lenaId,
    text: 'So walk me through it again. What actually happened?',
  ),
  continuity: Continuity(
    fromMissionId: 'm05_something_went_wrong',
    variants: [
      ContinuityVariant(
        sourceOptionId: 'm05_open_half_not_third',
        line: SceneLine(
          speakerId: lenaId,
          text: "You said half became one in three. That's a big gap to miss.",
        ),
      ),
      ContinuityVariant(
        sourceOptionId: 'm05_open_star_labels',
        line: SceneLine(
          speakerId: lenaId,
          text: 'You gave Marcus situation, task, action. I want the actual story.',
        ),
      ),
      ContinuityVariant(
        sourceOptionId: 'm05_open_too_much',
        line: SceneLine(
          speakerId: lenaId,
          text: "You said your mistake was taking on too much. That's not a mistake.",
        ),
      ),
      ContinuityVariant(
        sourceOptionId: 'm05_evidence_export_tool',
        line: SceneLine(
          speakerId: lenaId,
          text: "You said the export tool broke your numbers. Tools don't send reports.",
        ),
      ),
      ContinuityVariant(
        sourceOptionId: 'm05_evidence_we_caught',
        line: SceneLine(
          speakerId: lenaId,
          text: "You said 'we' caught the error. Who actually caught it?",
        ),
      ),
      ContinuityVariant(
        sourceOptionId: 'm05_land_never_again',
        line: SceneLine(
          speakerId: lenaId,
          text: "You said you haven't made a mistake like that since. Really?",
        ),
      ),
      ContinuityVariant(
        sourceOptionId: 'm05_land_not_big_deal',
        line: SceneLine(
          speakerId: lenaId,
          text: "You said it wasn't a big deal. Your lead might disagree.",
        ),
      ),
    ],
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      options: [
        AnswerOption(
          id: 'm06_open_short_version',
          text:
              'The short version: I counted duplicate rows, my report said half instead '
              'of one in three, and I told my lead that afternoon.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm06_open_data_issue',
          text:
              'To be fair, it was less a mistake than a data quality issue. The export '
              'was messy, and I was actually the one who spotted it.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_keep_your_story',
        ),
        AnswerOption(
          id: 'm06_open_as_i_told',
          text:
              'Sure. As I told Marcus, the situation was my internship, and the task was '
              'to write a report on our support tickets.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_tell_it_dont_recite',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.evidence,
      options: [
        AnswerOption(
          id: 'm06_evidence_rows',
          text:
              "The export had 900 rows, and 300 were duplicates. I'd counted them all, so "
              'password resets looked like half instead of a third.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm06_evidence_doesnt_matter',
          text:
              "Exactly how many doesn't matter much now. What matters is that I caught "
              'it, owned it, and the team trusted me more afterwards.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 0,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.vague},
          lessonId: 'lesson_be_concrete',
        ),
        AnswerOption(
          id: 'm06_evidence_three_weeks',
          text:
              "I'd only been there three weeks, nobody showed me how the export worked, "
              "and the deadline was the same day. It wasn't an easy setup.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.blame},
          lessonId: 'lesson_own_your_part',
        ),
      ],
    ),
    Beat(
      kind: BeatKind.land,
      options: [
        AnswerOption(
          id: 'm06_land_same_story',
          text:
              "So it's the same story I told Marcus: my mistake, caught the same day, and "
              "I've checked for duplicates before every report since.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm06_land_lead_caught_it',
          text:
              'Thinking about it now, maybe my lead caught it first and I just fixed it. '
              'Either way, the important thing is that it got fixed.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_keep_your_story',
        ),
        AnswerOption(
          id: 'm06_land_anything_else',
          text:
              "Anyway, I hope that's clearer. I'm happy to go through any other part of "
              'it again if that helps, or anything else at all.',
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
      id: 'm06_follow_tomorrow',
      line: SceneLine(
        speakerId: lenaId,
        text: 'If I gave you that export tomorrow, what would you do first?',
      ),
      replies: [
        AnswerOption(
          id: 'm06_reply_tomorrow_count',
          text:
              "Count the rows, then count the unique ticket IDs. If the two don't match, "
              "I'd find the duplicates before I calculate anything.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm06_reply_tomorrow_tool',
          text:
              "I'd run it through a proper data tool instead of a spreadsheet, so that "
              "mistakes like that one simply can't happen again.",
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
          id: 'm06_reply_tomorrow_someone_else',
          text:
              "Honestly, I'd ask someone more experienced to handle it, because I "
              "wouldn't want to risk making the same mistake twice.",
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
      id: 'm06_follow_not_what_you_said',
      trigger: Flag.offQuestion,
      line: SceneLine(
        speakerId: lenaId,
        text: "That's not what you told Marcus.",
      ),
      replies: [
        AnswerOption(
          id: 'm06_reply_said_stick',
          text:
              "You're right, and I'll stick with what I told him: I made the counting "
              'mistake, and I told my lead the same afternoon.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm06_reply_said_better',
          text:
              "I think I just explained it better this time. The core of the story hasn't "
              "really changed, only the way I'm telling it.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.offQuestion},
          lessonId: 'lesson_keep_your_story',
        ),
        AnswerOption(
          id: 'm06_reply_said_details',
          text:
              'Maybe I mixed up a few details. It was a while ago, and honestly the '
              "details don't change what I learned from it.",
          scores: DimensionScores(
            relevance: 1,
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
      id: 'm06_follow_what_you_missed',
      trigger: Flag.blame,
      line: SceneLine(
        speakerId: lenaId,
        text: 'You keep mentioning the export. What did you miss?',
      ),
      replies: [
        AnswerOption(
          id: 'm06_reply_missed_ids',
          text:
              "I didn't compare the row count with the unique ticket IDs. One check would "
              'have caught it, and I skipped it.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm06_reply_missed_warned',
          text:
              'Nothing I could have known at the time, honestly. Nobody had told me the '
              'export could duplicate rows like that.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 2,
            adaptability: 1,
          ),
          flags: {Flag.blame},
          lessonId: 'lesson_own_your_part',
        ),
        AnswerOption(
          id: 'm06_reply_missed_everyone',
          text:
              'We all missed it, really. The whole team used that export every week, and '
              'nobody else had spotted it either.',
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
