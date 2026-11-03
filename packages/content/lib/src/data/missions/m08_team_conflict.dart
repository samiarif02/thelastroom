import 'package:engine/engine.dart';

import '../../mission.dart';
import '../interviewers.dart';

/// Mission 8, "Team Conflict" (brief §6, brief 37): Lena opens Chapter 2, and the player
/// answers out loud for the first time.
///
/// From here the answer is the player's own story (or one borrowed from the practice CV), so
/// the points are what any strong conflict story does: a real disagreement about the work,
/// the other person's view given fairly, the player's own move, and a clear ending. Lena's
/// follow-up turns the story round, which is where the common miss (making the other person
/// the problem) shows.
const missionTeamConflict = Mission(
  id: 'm08_team_conflict',
  chapter: 2,
  number: 8,
  title: 'Team conflict',
  practises: 'Describing a disagreement fairly: their view, your view, and how it was settled.',
  answerMode: AnswerMode.voice,
  hinted: false,
  scene: [
    SceneLine(
      speakerId: lenaId,
      text: 'Welcome upstairs. From here on, you answer out loud, in your own words.',
    ),
    SceneLine(
      speakerId: lenaId,
      text: 'Your own story is best. If you need one, borrow from the practice CV.',
    ),
  ],
  question: SceneLine(
    speakerId: lenaId,
    text: 'Tell me about a time you disagreed with someone you worked with.',
  ),
  beats: [],
  followUps: [],
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm08_listen_real_disagreement',
        text:
            'Picks a real disagreement about the work, with one person, not a clash of '
            'personalities.',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm08_listen_their_side',
        text:
            "Gives the other person's view fairly: what they wanted, and why it made sense "
            'to them.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm08_listen_your_move',
        text:
            'Says what you did to settle it: the conversation you started, or the test or '
            'compromise you suggested.',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm08_listen_how_it_ended',
        text: 'Ends on how it was settled and how you worked together afterwards, then stops.',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: lenaId,
      text: 'If they told me this story, what would they say you got wrong?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm08_reply_own_misstep',
        text:
            'Names one thing you would do differently, without taking back the rest of the '
            'story.',
        dimension: Dimension.adaptability,
      ),
      ListenFor(
        id: 'm08_reply_their_eyes',
        text: 'Answers from their side, what they would say, not why you were right.',
        dimension: Dimension.relevance,
      ),
    ],
    lessonId: 'lesson_both_sides',
  ),
);
