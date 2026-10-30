import 'package:content/content.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  const mission = missionTheOpportunity;
  final paths = allPaths(mission);
  final totals = [for (final p in paths) p.score.total];

  test('Mission 1 is the unhinted, untimed baseline (FR-13, FR-30)', () {
    expect(mission.isBaseline, isTrue);
    expect(mission.hinted, isFalse);
    expect(mission.timed, isFalse);
    expect(mission.chapter, 1);
    expect(mission.number, 1);
    expect(gameContent.missions.first, same(mission));
  });

  test('Priya says every line', () {
    final speakers = {
      for (final line in mission.scene) line.speakerId,
      mission.question.speakerId,
      for (final followUp in mission.followUps) followUp.line.speakerId,
    };
    expect(speakers, {priya.id});
  });

  test('the setup makes clear who the player plays (note 3)', () {
    final firstName = player.name.split(' ').first;
    expect(mission.scene.first.text, contains(firstName));
  });

  test('the best path scores at least 90, the worst at most 30', () {
    // So the baseline has room to show growth either way.
    expect(totals.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(90));
    expect(totals.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(30));
  });
}
