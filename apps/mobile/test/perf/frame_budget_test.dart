import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../features/mission/mission_harness.dart';

/// What a screen costs per frame once it's at rest, measured at the widget level (NFR-3,
/// docs/status/56.md): how many frames it still asks for, and how many render objects repaint
/// in each. The device run (integration_test/perf_test.dart) gives the milliseconds.
typedef FrameCost = ({int framesAsked, double paintsPerFrame});

Future<FrameCost> costAtRest(WidgetTester tester, {int frames = 30}) async {
  var paints = 0;
  var asked = 0;
  debugOnProfilePaint = (_) => paints++;
  addTearDown(() => debugOnProfilePaint = null);
  for (var i = 0; i < frames; i++) {
    if (SchedulerBinding.instance.hasScheduledFrame) asked++;
    await tester.pump(const Duration(milliseconds: 16));
  }
  debugOnProfilePaint = null;
  return (framesAsked: asked, paintsPerFrame: paints / frames);
}

/// The QA phone's screen (realme RMX3085), where the tower is tallest.
const Size _realme = Size(411, 914);

void main() {
  testWidgets('the title at rest asks for no frames: the ambient clock only '
      'runs while a painter listens', (tester) async {
    final rig = MissionRig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.home, size: _realme);
    await rig.until(find.byType(TitleScreen));
    await rig.run(const Duration(seconds: 3));
    final cost = await costAtRest(tester);
    expect(cost.framesAsked, 0, reason: 'it ticked every frame for nothing');
  });

  testWidgets('the tower at rest repaints only the play cue and the up-next '
      'face, never the whole tower', (tester) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(5);
    await rig.boot(Routes.tower(), size: _realme);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(seconds: 4));
    final cost = await costAtRest(tester);
    expect(cost.framesAsked, greaterThan(0), reason: 'the cue still bobs');
    // Before: ~394 render objects a frame (the cue's rebuild relaid out the room's
    // LayoutBuilder, and the tower repainted round it).
    expect(cost.paintsPerFrame, lessThan(20));
  });

  testWidgets(
    'a timed room repaints only its timer line while the cards wait',
    (tester) async {
      final rig = MissionRig(tester);
      await rig.unlockThrough(2);
      await rig.boot(Routes.mission(2), size: _realme);
      expect(rig.state(2).mission.timed, isTrue);
      await rig.playLines(2);
      if (rig.state(2).mission.offersDraft) await rig.skipDraft();
      await rig.until(find.byType(ChoiceCard));
      await rig.run(const Duration(seconds: 2));
      final cost = await costAtRest(tester);
      // Before: ~140 a frame (the whole room and its cards, with the line).
      expect(cost.paintsPerFrame, lessThan(24));
    },
  );

  testWidgets('a screen over the tower asks for no frames: the faces under it '
      'stop breathing', (tester) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(5);
    await rig.boot(Routes.progress, size: _realme);
    await rig.until(find.byType(ProgressScreen));
    await rig.run(const Duration(seconds: 3));
    final cost = await costAtRest(tester);
    expect(cost.framesAsked, 0);
  });

  testWidgets('reduced motion: the tower at rest asks for no frames', (
    tester,
  ) async {
    final rig = MissionRig(tester);
    await rig.unlockThrough(5);
    await rig.boot(Routes.tower(), size: _realme, reduceMotion: true);
    await rig.until(find.byType(TowerScreen));
    await rig.run(const Duration(seconds: 2));
    final cost = await costAtRest(tester);
    expect(cost.framesAsked, 0);
  });
}
