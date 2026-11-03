import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 16, "The Interruption" (brief §6, brief 38): Marcus cuts in halfway through.
///
/// A voice mission: recovering mid-answer has to be spoken. The question invites a long story;
/// the follow-up is the interruption, and the reply is the recovery: straight to the result,
/// calm, and short. An answer that led with its point has already said what matters when the
/// interruption comes, which is the lesson.
const missionTheInterruption = Mission(
  id: 'm16_the_interruption',
  chapter: 3,
  number: 16,
  title: 'The interruption',
  practises:
      "Getting back on track when you're cut off, without losing your point.",
  answerMode: AnswerMode.voice,
  hinted: false,
  timed: false,
  scene: [
    SceneLine(
      speakerId: marcusId,
      text: "Good to see you again. Sam's running late, so I'll start.",
    ),
    SceneLine(
      speakerId: marcusId,
      text: 'Use your own story, or one from the practice CV.',
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: "Tell me about the piece of work you're proudest of.",
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm16_listen_point_first',
        text: 'Says what the work was and why it mattered in the first two sentences.',
        dimension: Dimension.structure,
      ),
      ListenFor(
        id: 'm16_listen_fits_role',
        text: 'Picks work that fits a product job: users, data or a decision.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm16_listen_own_part',
        text:
            'Says what you did yourself, with "I", not only what the team did.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm16_listen_result',
        text: 'Names one result someone could check: a number, or a change people noticed.',
        dimension: Dimension.specificity,
      ),
    ],
    followUp: SceneLine(
      speakerId: marcusId,
      text: 'Sorry, let me stop you there. What was the result?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm16_listen_straight_back',
        text: 'Goes straight to the result, without starting the story again.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm16_listen_calm',
        text: 'Stays calm: no long apology, no "as I was saying".',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm16_listen_stops',
        text: 'Says it in a sentence or two, then stops.',
        dimension: Dimension.structure,
      ),
    ],
    lessonId: 'lesson_answer_first',
  ),
);
