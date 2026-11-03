import 'dart:io';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/share/card_renderer.dart';
import 'package:the_last_room/features/share/floor_card.dart';
import 'package:the_last_room/features/share/floor_card_facts.dart';

import '../progression/progression_test.dart' show attempt;

/// The PR's stills (brief 54): each floor's card drawn by the real renderer at 1080 × 1350,
/// written to `.pr-screenshots/54/` when `WRITE_STILLS=1`. Without it, each card is still
/// drawn (a failure to draw fails the test) and nothing is written.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';

  FloorCardFacts factsFor(int n, {String? name}) {
    final rooms = [
      for (final m in missions)
        if (m.chapter == n) m,
    ];
    return FloorCardFacts.of(
      floor: n,
      progression: Progression(
        xp: switch (n) {
          1 => 1247,
          2 => 2630,
          _ => 4105,
        },
        lastXp: 0,
        unlocked: {
          for (final s in Skill.values)
            if (s != Skill.clearIntroductions || n != 2) s,
        },
        uncelebrated: const {},
        sessionsThisWeek: 3,
        weeklyGoal: 3,
      ),
      attempts: [
        attempt(rooms.first, 41 + n * 3),
        attempt(rooms.last, 72 + n * 4),
      ],
      name: name,
    );
  }

  for (final (n, name) in [(1, 'Sami'), (2, null), (3, 'Sami')]) {
    testWidgets('floor $n card', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final png = await tester.runAsync(
        () => const OffscreenCardRenderer().render(
          FloorCard(facts: factsFor(n, name: name)),
          size: FloorCard.size,
          pixelRatio: FloorCard.pixelRatio,
          view: tester.view,
        ),
      );
      expect(png, isNotNull);
      if (write) {
        // Real file I/O never completes in the test's fake time: run it for real.
        await tester.runAsync(() async {
          final out = File('../../.pr-screenshots/54/share-card-floor-$n.png');
          await out.parent.create(recursive: true);
          await out.writeAsBytes(png!);
        });
      }
    });
  }
}
