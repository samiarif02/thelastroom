import '../../ui/film_kit.dart';

/// Sample Mission 1 copy for the catalog's components. The engine and content packages aren't
/// needed to judge a look; the mission player (brief 10) reads the real mission.
abstract final class SampleMission {
  static const String chapterNumber = 'CHAPTER ONE';
  static const String chapterTitle = 'GET THROUGH THE DOOR';
  static const String mission = 'The Opportunity';
  static const String missionIndex = '01';
  static const String company = 'NORTHSTAR LABS';
  static const String location = 'Lobby, floor 1';

  static const String interviewer = 'Priya';
  static const String interviewerRole = 'Recruiter';
  static const String line =
      'Four hundred people applied for this role. Tell me why this one caught your eye.';

  static const List<String> answers = [
    "I've used Northstar's tools for two years. The problem you're solving is the one I keep "
        'running into.',
    "Honestly, I'm applying to a lot of places, and this looked like a great opportunity.",
    "It's a long story. It really started back at university, when I first…",
  ];

  static const List<DossierScore> scores = [
    DossierScore(label: 'Relevance', value: 78),
    DossierScore(label: 'Specificity', value: 52),
    DossierScore(label: 'Structure', value: 70),
    DossierScore(label: 'Adaptability', value: 64),
  ];

  static const int total = 66;

  /// The weakest dimension, which the red pen marks.
  static const int weakestIndex = 1;

  static const String weakLine = '“We shipped it in two weeks.”';
  static const String note = 'Who is “we”? Say what you did.';
}
