import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 14, "Panel Review" (brief §6, brief 37): Marcus and Lena together, the review of
/// Chapter 2.
///
/// One question that needs every Chapter 2 skill: a plan that fell apart (the failure), with
/// people counting on the player (the pressure), a call made under time (the deadline), and
/// Lena's follow-up about who was let down (the conflict, said without blame). The lesson is
/// Chapter 1's "Say what you did": a panel story told all in "we" hides the player. Doing
/// well on the reply, unhinted, earns *Conflict Navigator*.
const missionPanelReview = Mission(
  id: 'm14_panel_review',
  chapter: 2,
  number: 14,
  title: 'Panel review',
  practises: 'Answering a panel under pressure: one story, your own part, and a calm reply to a push.',
  answerMode: AnswerMode.voice,
  hinted: false,
  skillRequirements: [
    SkillRequirement(
      skill: Skill.conflictNavigator,
      dimension: Dimension.adaptability,
      minScore: conflictNavigatorMinAdaptability,
    ),
  ],
  scene: [
    SceneLine(
      speakerId: marcusId,
      text: 'Last one on this floor. Lena and I are both here for it.',
    ),
    SceneLine(
      speakerId: lenaId,
      text: 'Answer us both. Your own story, or one from the practice CV.',
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell us about a time a plan fell apart and people were counting on you.',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm14_listen_on_question',
        text: 'Picks a time a plan really fell apart, with people depending on the result.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm14_listen_your_part',
        text: "Says what you did yourself, using 'I' for your part and 'we' for the team's.",
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm14_listen_the_call',
        text: 'Names the call you made under pressure: what you did first and what you dropped.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm14_listen_one_story',
        text: 'Tells one story from start to finish, and ends on how it turned out.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: lenaId,
      text: "You said it worked out. Who wasn't happy, and what did you tell them?",
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm14_reply_names_person',
        text: 'Names someone who was let down and what you told them, without blaming anyone.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm14_reply_sooner',
        text: 'Says what you would do sooner next time, such as warning people earlier.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm14_reply_same_facts',
        text: 'Answers Lena directly, and keeps the facts from your first answer.',
        dimension: Dimension.relevance,
      ),
    ],
    lessonId: 'lesson_name_your_part',
  ),
);

/// The adaptability score (0–100) a Panel Review attempt needs to unlock *Conflict Navigator*:
/// the reply to Lena's push is where owning a hard moment without blame shows.
const int conflictNavigatorMinAdaptability = 75;
