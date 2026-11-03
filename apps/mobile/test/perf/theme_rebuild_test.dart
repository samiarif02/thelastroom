import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/tower/northstar_tower.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';

import '../features/mission/mission_harness.dart';

/// Brief 31's budget, in Daylight (brief 46): on the tower the faces in the windows are still
/// (21 rooms must not each repaint every frame); only the up-next card's window breathes.
void main() {
  testWidgets('on the tower the windows are still; only the up-next face '
      'breathes', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.tower(), reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(milliseconds: 500));
    final inWindows = tester.widgetList<CastFigure>(
      find.descendant(
        of: find.byType(NorthstarTower),
        matching: find.byType(CastFigure),
      ),
    );
    expect(inWindows, isNotEmpty);
    expect(inWindows.every((f) => !f.idle), isTrue);
  });
}
