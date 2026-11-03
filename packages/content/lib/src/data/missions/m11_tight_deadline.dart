import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 11, "Tight Deadline" (brief §6, brief 37): Marcus wants to know how the player
/// chooses when it can't all get done.
///
/// A strong answer is about choosing: what came first, what was dropped or delayed, and who
/// was told. The common miss is effort instead of choice ("I stayed late"), so the follow-up
/// asks who was told that something wouldn't get done, and when.
const missionTightDeadline = Mission(
  id: 'm11_tight_deadline',
  chapter: 2,
  number: 11,
  title: 'Tight deadline',
  practises: 'Showing how you prioritise when time runs out: what came first, what you cut, who you told.',
  answerMode: AnswerMode.voice,
  hinted: false,
  scene: [
    SceneLine(
      speakerId: marcusId,
      text: 'Everything here is due yesterday. I want to know how you choose.',
    ),
    SceneLine(
      speakerId: marcusId,
      text: "Your own story if you have one. The practice CV if you don't.",
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell me about a time you had too much to do and not enough time.',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm11_listen_the_squeeze',
        text: "Sets up the squeeze quickly: what was due, by when, and why it couldn't all fit.",
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm11_listen_what_first',
        text: 'Says what you did first, and why it mattered most.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm11_listen_what_cut',
        text: 'Names what you dropped, delayed or did more simply, and who you told.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm11_listen_outcome',
        text: "Ends on what you delivered on time, and what you'd plan differently.",
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: marcusId,
      text: "So who did you tell that something wouldn't get done? And when?",
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm11_reply_told_early',
        text: 'Names who you told, and says you told them before the deadline, not after.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm11_reply_offered_instead',
        text: 'Says what you offered them instead: a later date, a smaller version, or help.',
        dimension: Dimension.adaptability,
      ),
    ],
    lessonId: 'lesson_cut_dont_cram',
  ),
);
