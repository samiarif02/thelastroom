import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 20, "The Final Interview" (brief §6, brief 38): Sam and Marcus, and the whole
/// answer out loud.
///
/// A voice mission and the chapter's review: "why you?" asks for every skill at once. A strong
/// case names what the job needs, proves each with one example, and ends on why this job.
/// Marcus's follow-up asks for the weakest part of it: a real gap, what's being done about it,
/// and a case that still stands.
const missionTheFinalInterview = Mission(
  id: 'm20_the_final_interview',
  chapter: 3,
  number: 20,
  title: 'The final interview',
  practises: 'Making your whole case out loud: what the job needs, your proof, why you want it.',
  answerMode: AnswerMode.voice,
  hinted: false,
  timed: false,
  scene: [
    SceneLine(
      speakerId: samId,
      text: "Marcus has told me a lot about you. I'd like to hear it from you.",
    ),
    SceneLine(
      speakerId: marcusId,
      text: 'Your own story or the practice CV. Take a breath first.',
    ),
  ],
  question: SceneLine(
    speakerId: samId,
    text: 'In your own words: why are you the right person for this job?',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm20_listen_job_needs',
        text: "Names two or three things this job needs, and matches each to something you've done.",
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm20_listen_proof',
        text: 'Backs each one with a specific example: what you did, and what changed.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm20_listen_own_words',
        text: 'Uses your own words, with no "hard-working team player" phrases standing in for proof.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm20_listen_shape',
        text: 'Has a clear shape: the case, the proof, then why you want this job.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: marcusId,
      text: "And what's the weakest part of that case?",
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm20_listen_real_gap',
        text: 'Names a real gap, not a strength in disguise.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm20_listen_closing_it',
        text: "Says what you're already doing about it.",
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm20_listen_case_stands',
        text: "Finishes, briefly, on why you're still the right pick.",
        dimension: Dimension.structure,
      ),
    ],
    lessonId: 'lesson_make_the_case',
  ),
);
