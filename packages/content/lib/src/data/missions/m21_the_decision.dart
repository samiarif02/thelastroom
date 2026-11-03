import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 21, "The Decision" (brief §6, brief 38): the last room. Sam makes the offer.
///
/// A voice mission: closing the interview. A strong reply thanks them, says plainly the player
/// wants the job, asks for the offer in writing and agrees when they'll answer. Priya's
/// follow-up is Mission 18's question come back: the offer sits at the bottom of the band, and
/// the reply asks calmly what could move. The [Mission.epilogue] closes the campaign.
const missionTheDecision = Mission(
  id: 'm21_the_decision',
  chapter: 3,
  number: 21,
  title: 'The decision',
  practises: 'Closing well when the offer comes: thank them, get it in writing, agree a date.',
  answerMode: AnswerMode.voice,
  hinted: false,
  timed: false,
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: 'Sam and I have talked it over, Jordan.',
    ),
    SceneLine(speakerId: samId, text: "We'd like to offer you the job."),
  ],
  question: SceneLine(
    speakerId: samId,
    text: "Take a moment. Then tell us how you'd like to take it from here.",
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm21_listen_wants_it',
        text: 'Thanks them, and says plainly that you want the job.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm21_listen_in_writing',
        text: "Asks for the offer in writing: the pay, the start date and what's in the package.",
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm21_listen_names_date',
        text: "Agrees when you'll answer, and names the day.",
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm21_listen_short',
        text: "Keeps it short and in order: thanks, the details, when you'll reply.",
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: priyaId,
      text: "It's at the bottom of our band for the role. Is that a problem?",
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm21_listen_calm_ask',
        text: "Says calmly where you'd hoped to be, and why, without a threat.",
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm21_listen_what_moves',
        text: 'Asks what could move: the start salary, a review date or training.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm21_listen_still_keen',
        text: 'Makes clear you still want the job while you talk it through.',
        dimension: Dimension.relevance,
      ),
    ],
    lessonId: 'lesson_close_the_offer',
  ),
  epilogue: [
    SceneLine(
      speakerId: priyaId,
      text: "I'll send it over tonight. Take the time you asked for.",
    ),
    SceneLine(
      speakerId: samId,
      text: 'For what it is worth, Jordan, you earned this room.',
    ),
    SceneLine(speakerId: samId, text: 'Welcome to the top floor.'),
  ],
);
