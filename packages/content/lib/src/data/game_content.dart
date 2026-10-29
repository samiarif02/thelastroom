import '../mission.dart';
import '../validation.dart';
import 'interviewers.dart';
import 'lessons.dart';
import 'missions/m01_the_opportunity.dart';

/// Everything the game ships, as one bundle: the app plays it, `validateContent` checks it.
/// Bundled in the app as Dart, so it works offline with nothing fetched (ADR 0005).
const gameContent = ContentBundle(
  interviewers: interviewers,
  lessons: lessons,
  missions: missions,
);

/// Every playable mission, in campaign order.
const List<Mission> missions = [missionTheOpportunity];
