import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 9, "The Failure" (brief §6, brief 37): Marcus asks for something bigger than a
/// mistake.
///
/// Mission 5 was a mistake fixed the same afternoon; this is something the player worked hard
/// on that still failed. The common misses are a strength in disguise ("I care too much") and
/// an outside cause told first, so Marcus's follow-up asks whose fault it was, and the lesson
/// is Chapter 1's "Own your part".
const missionTheFailure = Mission(
  id: 'm09_the_failure',
  chapter: 2,
  number: 9,
  title: 'The Failure',
  practises: 'Talking about a real failure: owning your part, and what you do differently now.',
  answerMode: AnswerMode.voice,
  hinted: false,
  scene: [
    SceneLine(
      speakerId: marcusId,
      text:
          "A mistake you fix the same day. I'm asking about something bigger.",
    ),
    SceneLine(
      speakerId: marcusId,
      text: 'Your own story or the practice CV, your call. Just make it a real one.',
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell me about something you worked hard on that failed.',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm09_listen_real_failure',
        text:
            'Picks a real failure that mattered, not a strength in disguise like caring too '
            'much.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm09_listen_your_part',
        text:
            'Says plainly what your part in it was, before any outside cause.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm09_listen_what_you_did',
        text: 'Says what you did once you saw it failing: who you told and what you tried.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm09_listen_now_different',
        text: 'Ends on one thing you do differently since, and stops there.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: marcusId,
      text: 'Be honest with me. Whose fault was it?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm09_reply_owns_share',
        text: 'Owns your share in one sentence, without blaming others or taking all of it.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm09_reply_same_facts',
        text: 'Keeps the facts of your first answer, adding detail instead of changing them.',
        dimension: Dimension.adaptability,
      ),
    ],
    lessonId: 'lesson_own_your_part',
  ),
);
