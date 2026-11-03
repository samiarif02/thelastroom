import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 10, "No Clear Instructions" (brief §6, brief 37): Lena hands over a one-line brief.
///
/// A strong answer shows how the player got moving: what was unclear, who they asked, what
/// they assumed where nobody knew and how they checked it. The common miss is "I used my
/// initiative" with nothing underneath, so the follow-up takes the people away ("and if
/// nobody answered?").
const missionNoClearInstructions = Mission(
  id: 'm10_no_clear_instructions',
  chapter: 2,
  number: 10,
  title: 'No clear instructions',
  practises: 'Explaining how you get started when the brief is vague: ask, assume, then check.',
  answerMode: AnswerMode.voice,
  hinted: false,
  scene: [
    SceneLine(
      speakerId: lenaId,
      text: "Briefs here are often one line long. Sometimes they're just a title.",
    ),
    SceneLine(
      speakerId: lenaId,
      text: 'Use your own story, or one from the practice CV.',
    ),
  ],
  question: SceneLine(
    speakerId: lenaId,
    text: 'Tell me about a time you had to start something with no clear instructions.',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm10_listen_what_was_unclear',
        text: 'Says exactly what was unclear, so the listener knows the gap you faced.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm10_listen_who_you_asked',
        text:
            'Names who you asked and what you asked them, instead of only working it out '
            'alone.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm10_listen_your_guess',
        text: 'Says what you assumed where nobody knew, and how you checked it early.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm10_listen_result',
        text: 'Ends on what you delivered and whether your assumption turned out right.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: lenaId,
      text: 'And if nobody had answered your questions? Then what?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm10_reply_small_step',
        text:
            'Names a small first version you could make and show someone, instead of '
            'waiting.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm10_reply_write_it_down',
        text:
            'Says you would write your assumptions down and share them, so a wrong one is '
            'caught early.',
        dimension: Dimension.specificity,
      ),
    ],
    lessonId: 'lesson_ask_then_act',
  ),
);
