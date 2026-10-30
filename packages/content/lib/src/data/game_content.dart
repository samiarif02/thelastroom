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
