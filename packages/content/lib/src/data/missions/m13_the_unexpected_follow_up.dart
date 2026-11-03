import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 13, "The Unexpected Follow-Up" (brief §6, brief 37): an easy question, then the
/// one nobody prepares for.
///
/// The question is a gift (work the player is proud of); the test is Lena's follow-up, which
/// asks what the people who used it would say was wrong with it. So the follow-up carries
/// three points here: pause instead of filling the silence, name a real weakness without
/// getting defensive, and say what would change because of it.
const missionTheUnexpectedFollowUp = Mission(
  id: 'm13_the_unexpected_follow_up',
  chapter: 2,
  number: 13,
  title: 'The unexpected follow-up',
  practises: "Staying clear when a follow-up comes from an angle you didn't prepare for.",
  answerMode: AnswerMode.voice,
  hinted: false,
  scene: [
    SceneLine(
      speakerId: lenaId,
      text: "This one sounds easy. It isn't, and that's the point.",
    ),
    SceneLine(
      speakerId: lenaId,
      text: 'Pick your own work, or something from the practice CV.',
    ),
  ],
  question: SceneLine(
    speakerId: lenaId,
    text: "Tell me about a piece of work you're proud of.",
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm13_listen_one_piece',
        text: "Picks one piece of work and says why you're proud of it, not a list.",
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm13_listen_your_part',
        text: 'Says what you did on it yourself, with one detail or number.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm13_listen_short',
        text: 'Keeps it short, and ends on what it changed for the people who used it.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: lenaId,
      text: 'Good. What would the people who used it say was wrong with it?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm13_reply_pause',
        text:
            'Takes a moment if needed, then answers in one clear sentence instead of '
            'thinking aloud.',
        dimension: Dimension.structure,
      ),
      ListenFor(
        id: 'm13_reply_real_flaw',
        text: 'Names a real weakness of the work, without defending it or running it down.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm13_reply_what_next',
        text: 'Says what you would change because of it, or what you would ask the users.',
        dimension: Dimension.adaptability,
      ),
    ],
    lessonId: 'lesson_pause_then_answer',
  ),
);
