import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 5, "Something Went Wrong" (brief §6): Marcus asks for a mistake.
///
/// STAR without sounding memorised: the beats are the situation, what Jordan did, and what
/// changed, told as a story. The tempting lines recite the STAR labels, blame the export tool,
/// or promise it never happens again. Jordan's story is the Larkfield report that counted
/// duplicate rows. Mission 6 challenges whichever beat line here cost the most.
const missionSomethingWentWrong = Mission(
  id: 'm05_something_went_wrong',
  chapter: 1,
  number: 5,
  title: 'Something Went Wrong',
  hinted: true,
  scene: [
    SceneLine(
      speakerId: marcusId,
      text:
          'Everyone has a story where it all went well. I want the other kind.',
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell me about a time you made a mistake at work.',
  ),
  beats: [
    Beat(
      kind: BeatKind.open,
      why: ReasonPrompt(
        line: SceneLine(speakerId: marcusId, text: 'Why open like that?'),
        reasons: [
          Reason(
            id: 'm05_open_why_name_it',
            text: 'A real mistake, named plainly with its numbers, is what builds trust.',
            soundFor: {'m05_open_half_not_third'},
          ),
          Reason(
            id: 'm05_open_why_labels',
            text: 'Labelling each STAR step shows I know how to structure an answer.',
            tempts: {'m05_open_star_labels'},
          ),
          Reason(
            id: 'm05_open_why_safe_flaw',
            text: "The safest mistake to share is one that's secretly a strength.",
            tempts: {'m05_open_too_much'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: 'Half instead of a third. Clear. Go on.',
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: 'Hm. I asked about an actual mistake.',
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'That was fast. Did you read them?',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm05_open_half_not_third',
          text:
              'At Larkfield I sent my lead a ticket report saying half our tickets were '
              'password resets. The real number was one in three.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm05_open_star_labels',
          text:
              'Sure. The situation was my internship, my task was a ticket report, and '
              'the action I took was to fix an error I found in it.',
          scores: DimensionScores(
            relevance: 2,
            specificity: 1,
            structure: 1,
            adaptability: 0,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_tell_it_dont_recite',
        ),
        AnswerOption(
          id: 'm05_open_too_much',
          text:
              'Honestly, my biggest mistake is probably taking on too much, because I '
              'find it really hard to say no when someone needs my help.',
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
        line: SceneLine(speakerId: marcusId, text: 'Why tell it that way?'),
        reasons: [
          Reason(
            id: 'm05_evidence_why_own_it',
            text: 'Owning the cause and how fast I spoke up matters more than the error.',
            soundFor: {'m05_evidence_told_lead'},
          ),
          Reason(
            id: 'm05_evidence_why_explain',
            text: "Explaining what really went wrong shows I wasn't careless.",
            tempts: {'m05_evidence_export_tool'},
          ),
          Reason(
            id: 'm05_evidence_why_checks',
            text:
                'Saying the team caught it shows we had good checks in place.',
            tempts: {'m05_evidence_we_caught'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: 'Same afternoon, before the meeting. Good.',
        ),
        weak: SceneLine(speakerId: marcusId, text: 'So whose mistake was it?'),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'You picked that blind. Take your time.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm05_evidence_told_lead',
          text:
              "The export had duplicate rows I hadn't checked for. I told my lead that "
              'same afternoon, before the team meeting, and sent a corrected report.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm05_evidence_export_tool',
          text:
              'The export tool duplicated rows without warning anyone, so the numbers '
              'were wrong before I even touched them. I flagged it as soon as I saw.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 2,
            structure: 3,
            adaptability: 0,
          ),
          flags: {Flag.blame},
          lessonId: 'lesson_own_your_part',
        ),
        AnswerOption(
          id: 'm05_evidence_we_caught',
          text:
              'We caught the error as a team during the review, and we sent out a '
              'corrected version, so in the end there was no real harm done.',
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
        line: SceneLine(speakerId: marcusId, text: 'Why finish there?'),
        reasons: [
          Reason(
            id: 'm05_land_why_habit',
            text: 'Show the habit I changed and still use, so the lesson is believable.',
            soundFor: {'m05_land_check_now'},
          ),
          Reason(
            id: 'm05_land_why_never',
            text: "Saying it never happened again proves I've fully learned.",
            tempts: {'m05_land_never_again'},
          ),
          Reason(
            id: 'm05_land_why_downplay',
            text: 'Downplaying the damage keeps the mistake from looking serious.',
            tempts: {'m05_land_not_big_deal'},
          ),
        ],
      ),
      reaction: BeatReaction(
        strong: SceneLine(
          speakerId: marcusId,
          text: "A habit you still use. That's what I wanted.",
        ),
        weak: SceneLine(
          speakerId: marcusId,
          text: 'Everyone says they learned. Show me how.',
        ),
        guessed: SceneLine(
          speakerId: marcusId,
          text: 'Rushed. The ending is the part I remember.',
        ),
      ),
      options: [
        AnswerOption(
          id: 'm05_land_check_now',
          text:
              'Now I check for duplicates before any number leaves my desk, and on my '
              'project I asked a teammate to recheck our figures before the demo.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 0,
          ),
        ),
        AnswerOption(
          id: 'm05_land_never_again',
          text:
              "It taught me to be far more careful, and I can honestly say I haven't made "
              'a mistake like that since. It made me a better analyst.',
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
          id: 'm05_land_not_big_deal',
          text:
              "In the end it wasn't a big deal, because my lead hadn't shared it widely "
              "yet, so luckily it didn't cause any real damage at all.",
          scores: DimensionScores(
            relevance: 1,
            specificity: 0,
            structure: 2,
            adaptability: 0,
          ),
          flags: {Flag.blame},
          lessonId: 'lesson_own_your_part',
        ),
      ],
    ),
  ],
  followUps: [
    FollowUp(
      id: 'm05_follow_lead_reaction',
      line: SceneLine(
        speakerId: marcusId,
        text: 'And how did your lead take it?',
      ),
      replies: [
        AnswerOption(
          id: 'm05_reply_reaction_thanked',
          text:
              'Calmly. My lead thanked me for flagging it before the meeting, and then '
              "asked me to check the next month's report as well.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm05_reply_reaction_tool',
          text:
              'My lead was fine, honestly. They knew the export tool was unreliable, so '
              'nobody really saw it as my mistake in the end.',
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
          id: 'm05_reply_reaction_moved_on',
          text:
              'It was fine. There was a short conversation about it, and then we all '
              'moved on to the next thing quite quickly after that, really.',
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
      id: 'm05_follow_your_part',
      trigger: Flag.blame,
      line: SceneLine(
        speakerId: marcusId,
        text: 'Leave the tool out of it. What was your part?',
      ),
      replies: [
        AnswerOption(
          id: 'm05_reply_part_no_check',
          text:
              "I didn't check the export for duplicates before I counted. That's on me, "
              "and it's why I check every export now.",
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm05_reply_part_defence',
          text:
              'Fair, though in my defence nobody had warned me about the export, and I '
              'was still very new to the team at the time.',
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
          id: 'm05_reply_part_process',
          text:
              'We all used that export, so the mistake was really in the process. We '
              'changed the process afterwards, which was the main thing.',
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
    FollowUp(
      id: 'm05_follow_drop_labels',
      trigger: Flag.memorized,
      line: SceneLine(
        speakerId: marcusId,
        text: 'Drop the labels. Just tell me what happened.',
      ),
      replies: [
        AnswerOption(
          id: 'm05_reply_labels_story',
          text:
              'I counted duplicate rows by mistake, and I told my lead the report was '
              'wrong the same afternoon. Then I sent a corrected one.',
          scores: DimensionScores(
            relevance: 3,
            specificity: 3,
            structure: 3,
            adaptability: 3,
          ),
        ),
        AnswerOption(
          id: 'm05_reply_labels_result',
          text:
              'Of course. The result of my action was a corrected report, and the key '
              'learning was the importance of attention to detail.',
          scores: DimensionScores(
            relevance: 1,
            specificity: 1,
            structure: 1,
            adaptability: 1,
          ),
          flags: {Flag.memorized},
          lessonId: 'lesson_tell_it_dont_recite',
        ),
        AnswerOption(
          id: 'm05_reply_labels_mix_up',
          text:
              'Basically there was a mix-up with some numbers, I sorted it all out, and '
              'everything was fine in the end, so it was a good lesson.',
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
  ],
);
