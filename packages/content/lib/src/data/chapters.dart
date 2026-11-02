import '../mission.dart';

/// The three floors of the tower (brief §6), all playable: Chapter 1 answered by choices,
/// Chapter 2 by voice, Chapter 3 by both (owner, 2026-11-02; briefs 37, 38).
const List<Chapter> chapters = [
  Chapter(
    number: 1,
    title: 'Get Through the Door',
    playable: true,
    missionTitles: [
      'The Opportunity',
      'Tell Me About Yourself',
      'The Experience Gap',
      'Show Me the Evidence',
      'Something Went Wrong',
      'The Follow-Up Trap',
      'First Round Review',
    ],
  ),
  Chapter(
    number: 2,
    title: 'Under Pressure',
    playable: true,
    missionTitles: [
      'Team Conflict',
      'The Failure',
      'No Clear Instructions',
      'Tight Deadline',
      'The Uncomfortable Request',
      'The Unexpected Follow-Up',
      'Panel Review',
    ],
  ),
  Chapter(
    number: 3,
    title: 'The Final Round',
    playable: true,
    missionTitles: [
      'Solve the Problem',
      'The Interruption',
      '"I Don\'t Know"',
      'The Salary Question',
      'Your Turn to Ask',
      'The Final Interview',
      'The Decision',
    ],
  ),
];
