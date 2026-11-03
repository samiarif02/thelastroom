import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 17, "I Don't Know" (brief §6, brief 38): Lena asks a question a graduate isn't
/// expected to know.
///
/// A voice mission: admitting a gap well is about how it's said. A strong answer names the gap
/// in a sentence, reasons from what the player does know, and says how they'd find out. Lena's
/// follow-up asks what they'd actually do on Monday. Bluffing and freezing both miss.
const missionIDontKnow = Mission(
  id: 'm17_i_dont_know',
  chapter: 3,
  number: 17,
  title: '"I don\'t know"',
  practises: "Saying 'I don't know' well: name the gap, reason it out, say how you'd find out.",
  answerMode: AnswerMode.voice,
  hinted: false,
  timed: false,
  scene: [
    SceneLine(
      speakerId: lenaId,
      text: 'Hello again. Sam asked me to cover the technical side.',
    ),
    SceneLine(
      speakerId: lenaId,
      text: "Answer as yourself. There's no story to tell on this one.",
    ),
  ],
  question: SceneLine(
    speakerId: lenaId,
    text: 'How long would you run an A/B test on our pricing page, and why?',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm17_listen_names_gap',
        text: "Says plainly which part you don't know, in a sentence, without bluffing.",
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm17_listen_reasons',
        text: 'Reasons from what you do know, like needing enough visitors in each version.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm17_listen_find_out',
        text: "Says how you'd find out: who you'd ask, or what you'd check.",
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm17_listen_in_order',
        text: 'Keeps it short and in order: the gap, your reasoning, your next step.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: lenaId,
      text: 'Fine. I ask you to run it on Monday. What do you do?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm17_listen_first_step',
        text: 'Gives a real first step, like asking the data team how past tests were sized.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm17_listen_check_back',
        text: 'Offers to bring a plan back for a check before the test starts.',
        dimension: Dimension.adaptability,
      ),
    ],
    lessonId: 'lesson_honest_gap',
  ),
);
