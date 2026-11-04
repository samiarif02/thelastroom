import 'dart:io';
import 'dart:ui' as ui;

import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/progression/progression_store.dart';

import '../../mission/mission_harness.dart';
import '../../tower/played_attempt.dart';

/// Your file after the owner's phone review (brief 63): doors on the room cards and the hero's
/// "Best gain". Every state must draw without an exception; with `WRITE_STILLS=1` each is saved
/// at 2x in `STILLS_DIR` (default `.pr-screenshots/63/`).
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  final dir = Platform.environment['STILLS_DIR'] ?? '../../.pr-screenshots/63';
  const pixelRatio = 2.0;
  const phone = Size(411, 914);
  const tall = Size(411, 2200);

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
      File('$dir/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  MissionRig rig(WidgetTester tester) {
    final rig = MissionRig(tester);
    rig.overrides.add(
      progressionStoreProvider.overrideWithValue(InMemoryProgressionStore()),
    );
    return rig;
  }

  for (final (name, replayed) in [
    ('file-replayed', true),
    ('file-no-replay', false),
  ]) {
    testWidgets('Your file: $name', (tester) async {
      final r = rig(tester);
      // Room 1 first, then rooms 2 and 3; with [replayed], room 1 again, better.
      await r.progress.recordAttempt(playedAttempt(missions[0], pick: 2));
      await r.progress.recordAttempt(playedAttempt(missions[1], pick: 1));
      await r.progress.recordAttempt(playedAttempt(missions[2], pick: 2));
      if (replayed) {
        await r.progress.recordAttempt(playedAttempt(missions[0], attempt: 2));
      }
      await r.boot(Routes.progress, size: tall);
      await r.until(find.byType(ProgressScreen));
      await r.run(const Duration(seconds: 2));
      await still(tester, name, tall);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('Your file at the phone, scrolled to the rooms', (tester) async {
    final r = rig(tester);
    await r.progress.recordAttempt(playedAttempt(missions[0], pick: 2));
    await r.progress.recordAttempt(playedAttempt(missions[1], pick: 1));
    await r.progress.recordAttempt(playedAttempt(missions[0], attempt: 2));
    await r.boot(Routes.progress, size: phone);
    await r.until(find.byType(ProgressScreen));
    await r.run(const Duration(seconds: 2));
    await still(tester, 'file-hero', phone);
    await tester.dragUntilVisible(
      find.text(ProgressScreen.roomsTitle),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await r.run(const Duration(seconds: 1));
    await still(tester, 'file-rooms', phone);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
