import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 12, "The Uncomfortable Request" (brief §6, brief 37): Priya asks about judgement.
///
/// A strong answer is concrete: what was asked, what the player actually said back, and what
/// they offered instead, so the other person still had a way forward. The common miss is a
/// speech about values with no words from the room in it, so Priya's follow-up adds pressure
/// ("just do it") to see whether the answer holds.
const missionTheUncomfortableRequest = Mission(
  id: 'm12_the_uncomfortable_request',
  chapter: 2,
  number: 12,
  title: 'The Uncomfortable Request',
  practises: "Saying no to a request you're not comfortable with, and offering another way.",
  answerMode: AnswerMode.voice,
  hinted: false,
  scene: [
    SceneLine(
      speakerId: priyaId,
      text: "Hello again. Marcus asked me to take this one. It's about judgement.",
    ),
    SceneLine(
      speakerId: priyaId,
      text: "There's no perfect answer. Your own story, or one from the practice CV.",
    ),
  ],
  question: SceneLine(
    speakerId: priyaId,
    text: "Tell me about a time you were asked to do something that didn't feel right.",
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm12_listen_the_request',
        text:
            "Says what you were asked and why it didn't sit right, without making it sound "
            'bigger than it was.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm12_listen_what_you_said',
        text: 'Says what you actually said back, close to the words you used.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm12_listen_another_way',
        text: 'Names what you offered instead, so the person still had a way forward.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm12_listen_how_it_ended',
        text: 'Ends on what happened next, and how you got on with that person afterwards.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: priyaId,
      text: "And if your manager had said, 'Just do it'? What then?",
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm12_reply_holds_line',
        text: 'Stays calm and keeps your answer, without giving in or making a threat.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm12_reply_next_person',
        text: 'Says who you would take it to next, and how you would put it to them.',
        dimension: Dimension.adaptability,
      ),
    ],
    lessonId: 'lesson_no_with_a_way',
  ),
);
