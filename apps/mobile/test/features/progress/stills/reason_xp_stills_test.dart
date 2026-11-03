import 'dart:io';
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart' show FeedbackSheet;

import '../../mission/mission_harness.dart';

/// Brief 55 in the real room: the feedback sheet's "+10 XP" (sound) and "+5 XP" (close), and the
/// debrief's XP line with its room/reasons breakdown, at the owner's phone (360 × 800), a large
/// one (411 × 914) and 2x text with reduced motion. Every state must draw without an exception;
/// with `WRITE_STILLS=1` each is also saved as a PNG at 2x in `.pr-screenshots/55/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const mission = missionTheOpportunity;
  final open = mission.beats.first;
  final strongest = [
    for (final b in mission.beats)
      b.options.firstWhere((o) => b.isStrongest(o.id)),
  ];

  Future<void> still(WidgetTester tester, String name, Size size) async {
    await tester.pump();
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & (size * dpr),
        pixelRatio: pixelRatio / dpr,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/55/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  MissionRig rigFor(WidgetTester tester) => MissionRig(tester)
    ..overrides.add(
      progressionStoreProvider.overrideWithValue(InMemoryProgressionStore()),
    );

  for (final (tag, size, scale, calm) in [
    ('360', const Size(360, 800), 1.0, false),
    ('411', const Size(411, 914), 1.0, false),
    ('360-2x-still', const Size(360, 800), 2.0, true),
  ]) {
    Future<MissionRig> toTheCards(WidgetTester tester) async {
      final rig = rigFor(tester);
      await rig.boot(
        Routes.mission(1),
        size: size,
        textScale: scale,
        reduceMotion: calm,
      );
      await rig.playLines(1);
      await rig.skipDraft();
      await rig.until(find.byType(ChoiceCard));
      return rig;
    }

    testWidgets('the feedback sheet at $tag: sound +10, close +5', (
      tester,
    ) async {
      var rig = await toTheCards(tester);
      await rig.say(strongest.first);
      await rig.until(find.byType(FeedbackSheet));
      await rig.run(_settle);
      expect(find.text(FeedbackSheet.xpLabel(reasonSoundXp)), findsOneWidget);
      await still(tester, 'sheet-sound-$tag', size);

      rig = await toTheCards(tester);
      await rig.say(
        strongest.first,
        reason: open.why!.reasons.firstWhere(
          (r) => !r.isSoundFor(strongest.first.id),
        ),
      );
      await rig.until(find.byType(FeedbackSheet));
      await rig.run(_settle);
      expect(find.text(FeedbackSheet.xpLabel(reasonCloseXp)), findsOneWidget);
      await still(tester, 'sheet-close-$tag', size);
      await _done(tester);
    });

    testWidgets('the debrief XP line at $tag', (tester) async {
      final rig = rigFor(tester);
      await rig.boot(
        Routes.mission(1),
        size: size,
        textScale: scale,
        reduceMotion: calm,
      );
      await rig.play(
        1,
        beats: [for (final o in strongest) o.id],
        reply: mission.followUps
            .firstWhere((f) => f.trigger == null)
            .replies
            .first
            .id,
      );
      await rig.settleDossier();
      await rig.run(const Duration(seconds: 3));
      final line = find.textContaining('for your reasons');
      await rig.until(line);
      // Mid-screen: the bottom of the assessment sheet above it, the rest of the debrief below.
      await tester.runAsync(
        () => Scrollable.ensureVisible(tester.element(line), alignment: 0.5),
      );
      await rig.run(const Duration(milliseconds: 600));
      await still(tester, 'debrief-xp-$tag', size);
      await _done(tester);
    });
  }
}

/// The sheet has risen and its XP counted up.
final Duration _settle = DaylightMotion.countUp + DaylightMotion.move;

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
