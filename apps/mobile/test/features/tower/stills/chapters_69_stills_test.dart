import 'dart:io';
import 'dart:ui' as ui;

import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/tower/all_chapters_screen.dart';
import 'package:the_last_room/features/tower/chapter_section.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../../mission/mission_harness.dart';

/// "View all chapters" (brief 69): the link under the tower and the chapters list for a new
/// player, mid-game and all done, a locked room's note, every floor open, and 2x text. Every
/// state must draw without an exception; with `WRITE_STILLS=1` each is saved at 2x in
/// `STILLS_DIR` (default `.pr-screenshots/69/`).
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  final dir = Platform.environment['STILLS_DIR'] ?? '../../.pr-screenshots/69';
  const pixelRatio = 2.0;
  const phone = Size(411, 914);
  const tall = Size(411, 3400);

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

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openAll(WidgetTester tester, MissionRig r) async {
    for (final c in chapters) {
      final head = find.bySemanticsLabel(
        RegExp('^${RegExp.escape(ChapterSection.title(c))},.*Show its rooms'),
      );
      if (head.evaluate().isEmpty) continue;
      await tester.ensureVisible(head);
      await tester.tap(head);
      await r.run(const Duration(milliseconds: 800));
    }
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 6000),
    );
    await r.run(const Duration(milliseconds: 400));
  }

  testWidgets('the link under the tower', (tester) async {
    final r = rig(tester);
    await r.unlockThrough(3);
    await r.boot(Routes.tower(), size: phone);
    await r.until(find.byType(TowerScreen));
    await r.run(const Duration(seconds: 2));
    final link = find.byType(AllChaptersLink);
    await tester.ensureVisible(link);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -260),
    );
    await r.run(const Duration(seconds: 1));
    await still(tester, '01-tower-link', phone);
    await done(tester);
  });

  for (final (name, through) in [
    ('02-new-player', 1),
    ('03-mid-game', 10),
    ('04-all-done', missions.length + 1),
  ]) {
    testWidgets('chapters: $name', (tester) async {
      final r = rig(tester);
      if (through > 1) await r.unlockThrough(through);
      await r.boot(Routes.chapters, size: phone);
      await r.until(find.byType(ChapterSection));
      await r.run(const Duration(seconds: 2));
      await still(tester, name, phone);
      await done(tester);
    });
  }

  testWidgets('a locked room says what opens it', (tester) async {
    final r = rig(tester);
    await r.unlockThrough(3);
    await r.boot(Routes.chapters, size: phone);
    await r.until(find.byType(ChapterSection));
    await r.run(const Duration(seconds: 2));
    final locked = find.bySemanticsLabel(RegExp('^Room 5,'));
    await tester.ensureVisible(locked);
    await tester.tap(locked);
    await r.run(const Duration(seconds: 1));
    await still(tester, '05-locked-note', phone);
    await done(tester);
  });

  testWidgets('every floor open, mid-game', (tester) async {
    final r = rig(tester);
    await r.unlockThrough(10);
    await r.boot(Routes.chapters, size: tall);
    await r.until(find.byType(ChapterSection));
    await r.run(const Duration(seconds: 2));
    await openAll(tester, r);
    await still(tester, '06-every-floor-open', tall);
    await done(tester);
  });

  testWidgets('2x text', (tester) async {
    final r = rig(tester);
    await r.unlockThrough(3);
    await r.boot(Routes.chapters, size: phone, textScale: 2);
    await r.until(find.byType(ChapterSection));
    await r.run(const Duration(seconds: 2));
    await still(tester, '07-text-2x', phone);
    await done(tester);
  });
}
