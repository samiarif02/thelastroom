/// Fake Mission 1 data for the direction prototypes. The engine and content packages aren't
/// needed to judge a look; brief 06 replaces this with the real mission.
abstract final class MissionOne {
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
    DossierScore('Relevance', 78),
    DossierScore('Specificity', 52),
    DossierScore('Structure', 70),
    DossierScore('Adaptability', 64),
  ];

  static const int total = 66;

  /// The weakest dimension, which the red pen marks.
  static const int weakestIndex = 1;

  static const String weakLine = '“We shipped it in two weeks.”';
  static const String note = 'Who is “we”? Say what you did.';
}

/// One stamped score on the dossier.
class DossierScore {
  const DossierScore(this.dimension, this.value);

  final String dimension;

  /// 0–100.
  final int value;
}
