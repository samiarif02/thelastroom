import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';
import 'package:the_last_room/features/tower/tower_chapter_card.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../features/mission/mission_harness.dart';

/// Brief 31: a theme pick rebuilds each screen exactly once (no rebuild storm), and the tower
/// keeps only the hero's face breathing.
void main() {
  tearDown(() {
    BrandVivid.current = VividThemes.eveningForest;
    debugOnRebuildDirtyWidget = null;
  });

  testWidgets('a theme pick rebuilds each screen once, in one frame', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final rig = MissionRig(tester);
    await rig.boot(Routes.settings, reduceMotion: true);
    await rig.until(find.byType(SettingsScreen));
    await rig.run(const Duration(milliseconds: 500));
    final ocean = find.bySemanticsLabel(RegExp('^Ocean Night theme'));
    await tester.ensureVisible(ocean);
    await tester.pump();

    final builds = <Type, int>{};
    debugOnRebuildDirtyWidget = (e, _) =>
        builds[e.widget.runtimeType] = (builds[e.widget.runtimeType] ?? 0) + 1;
    await tester.tap(ocean);
    await tester.pump();
    expect(builds[SettingsScreen], 1);
    expect(builds[TowerScreen], 1, reason: 'the tower under Settings');
    builds.clear();
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      builds[SettingsScreen],
      isNull,
      reason: 'nothing left for a second pass',
    );
  });

  testWidgets('on the tower only the hero face breathes', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 500));
    final inCards = tester.widgetList<InterviewerBadge>(
      find.descendant(
        of: find.byType(ChapterCard),
        matching: find.byType(InterviewerBadge),
      ),
    );
    expect(inCards, isNotEmpty);
    expect(inCards.every((b) => !b.idle), isTrue);
  });
}
