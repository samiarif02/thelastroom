import '../mission.dart';

/// The three floors of the tower (brief §6), all playable: Chapter 1 answered by choices,
/// Chapter 2 by voice, Chapter 3 by both (owner, 2026-11-02; briefs 37, 38).
const List<Chapter> chapters = [
  Chapter(
    number: 1,
    title: 'Get through the door',
    playable: true,
    missionTitles: [
      'The opportunity',
      'Tell me about yourself',
      'The experience gap',
      'Show me the evidence',
      'Something went wrong',
      'The follow-up trap',
      'First round review',
    ],
  ),
  Chapter(
    number: 2,
    title: 'Under pressure',
    playable: true,
    missionTitles: [
      'Team conflict',
      'The failure',
      'No clear instructions',
      'Tight deadline',
      'The uncomfortable request',
      'The unexpected follow-up',
      'Panel review',
    ],
  ),
  Chapter(
    number: 3,
    title: 'The final round',
    playable: true,
    missionTitles: [
      'Solve the problem',
      'The interruption',
      '"I don\'t know"',
      'The salary question',
      'Your turn to ask',
      'The final interview',
      'The decision',
    ],
  ),
];
