import '../mission.dart';

/// The three floors of the tower (brief §6). Chapter 1 is playable; Chapters 2 and 3 are
/// visible, locked and teased by their mission titles (FR-31).
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
    playable: false,
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
    playable: false,
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
