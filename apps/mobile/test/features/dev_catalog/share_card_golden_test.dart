import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/share/floor_card.dart';
import 'package:the_last_room/features/share/floor_card_facts.dart';

import '../../ui/harness.dart';
import '../progression/progression_test.dart' show attempt;

/// The floor card (brief 54) for each floor, at its layout size (432 × 540, 1x: the shared PNG
/// is the same layout at 2.5x). Linux pixels, like the catalog goldens: redraw them as
/// `goldens/README.md` says and look at every changed image.
void main() {
  const cardKey = ValueKey('floor-card');

  for (final n in [1, 2, 3]) {
    testWidgets('share card floor $n', (tester) async {
      tester.view.devicePixelRatio = 1;
      final rooms = [
        for (final m in missions)
          if (m.chapter == n) m,
      ];
      final facts = FloorCardFacts.of(
        floor: n,
        progression: Progression(
          xp: 1247 * n,
          lastXp: 0,
          unlocked: Skill.values.toSet(),
          uncelebrated: const {},
          sessionsThisWeek: 3,
          weeklyGoal: 3,
        ),
        attempts: [attempt(rooms.first, 41), attempt(rooms.last, 72)],
        name: n == 1 ? 'Sami' : null,
      );
      await pumpKit(
        tester,
        RepaintBoundary(
          key: cardKey,
          child: FloorCard(facts: facts),
        ),
        size: FloorCard.size,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(FloorCard), findsOneWidget);
      await expectLater(
        find.byKey(cardKey),
        matchesGoldenFile('goldens/share-card-floor-$n.png'),
      );
    });
  }
}
