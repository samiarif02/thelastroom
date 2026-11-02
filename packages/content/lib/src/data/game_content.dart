import '../mission.dart';
import '../validation.dart';
import 'chapters.dart';
import 'interviewers.dart';
import 'lessons.dart';
import 'missions/m01_the_opportunity.dart';
import 'missions/m02_tell_me_about_yourself.dart';
import 'missions/m03_the_experience_gap.dart';
import 'missions/m04_show_me_the_evidence.dart';
import 'missions/m05_something_went_wrong.dart';
import 'missions/m06_the_follow_up_trap.dart';
import 'missions/m07_first_round_review.dart';
import 'missions/m15_solve_the_problem.dart';
import 'missions/m16_the_interruption.dart';
import 'missions/m17_i_dont_know.dart';
import 'missions/m18_the_salary_question.dart';
import 'missions/m19_your_turn_to_ask.dart';
import 'missions/m20_the_final_interview.dart';
import 'missions/m21_the_decision.dart';

/// Everything the game ships, as one bundle: the app plays it, `validateContent` checks it.
/// Bundled in the app as Dart, so it works offline with nothing fetched (ADR 0005).
const gameContent = ContentBundle(
  chapters: chapters,
  interviewers: interviewers,
  lessons: lessons,
  missions: missions,
);

/// Every playable mission, in campaign order.
const List<Mission> missions = [
  missionTheOpportunity,
  missionTellMeAboutYourself,
  missionTheExperienceGap,
  missionShowMeTheEvidence,
  missionSomethingWentWrong,
  missionTheFollowUpTrap,
  missionFirstRoundReview,
];

/// Chapter 3, "The Final Round" (brief 38): missions 15–21, three answered by choices and four
/// by voice. Written and validated, but not in [missions] yet: the app plays every mission in
/// that list, and the voice player (brief 35) has to land before the tower offers a voice
/// mission. The flip, once briefs 35 and 37 are merged: append these to [missions] and set
/// Chapter 3 `playable: true` in `chapters.dart`.
const List<Mission> chapterThreeMissions = [
  missionSolveTheProblem,
  missionTheInterruption,
  missionIDontKnow,
  missionTheSalaryQuestion,
  missionYourTurnToAsk,
  missionTheFinalInterview,
  missionTheDecision,
];
