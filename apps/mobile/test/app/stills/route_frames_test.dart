import 'dart:io';
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/back_to_exit.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/features/mission/mission_screen.dart';
import 'package:the_last_room/features/progress/chapter_report_screen.dart';
import 'package:the_last_room/features/recall/recall_screen.dart';
import 'package:the_last_room/features/tower/northstar_tower.dart';
import 'package:the_last_room/features/tower/tower_screen.dart';

import '../../features/mission/mission_harness.dart';
import '../../features/tower/played_attempt.dart';

/// Frame strips of the route transitions (brief 50), for the PR: each transition drawn at
/// even steps through its length at the owner's phone size, with real type. Every frame must
/// draw without an exception; with `WRITE_STILLS=1` each strip is saved as one PNG in
/// `.pr-screenshots/50/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const size = Size(360, 800);
  const frames = 6;
  const scale = 0.5;

  Future<ui.Image?> grab(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    if (!write) return null;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    return tester.runAsync(
      () => layer.toImage(Offset.zero & (size * dpr), pixelRatio: scale / dpr),
    );
  }

  /// Pumps [length] in [frames] − 1 even steps from the first frame, grabbing each.
  Future<void> strip(
    WidgetTester tester,
    String name,
    Duration length, {
    Future<void> Function()? start,
  }) async {
    await start?.call();
    await tester.pump();
    final shots = <ui.Image?>[await grab(tester)];
    for (var i = 1; i < frames; i++) {
      await tester.pump(length ~/ (frames - 1));
      shots.add(await grab(tester));
    }
    if (!write) return;
    final w = size.width * scale;
    final h = size.height * scale;
    const gap = 8.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        Rect.fromLTWH(0, 0, frames * (w + gap) + gap, h + 2 * gap),
        Paint()..color = DaylightColors.sand2,
      );
    for (final (i, shot) in shots.indexed) {
      canvas.drawImage(shot!, Offset(gap + i * (w + gap), gap), Paint());
    }
    final picture = recorder.endRecording();
    await tester.runAsync(() async {
      final image = await picture.toImage(
        (frames * (w + gap) + gap).round(),
        (h + 2 * gap).round(),
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/50/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<MissionRig> atTower(WidgetTester tester, {bool still = false}) async {
    final rig = MissionRig(tester);
    await rig.progress.recordAttempt(playedAttempt(missions[0], pick: 2));
    await rig.boot(Routes.tower(), size: size, reduceMotion: still);
    await rig.until(find.byType(NorthstarTower));
    await rig.run(const Duration(seconds: 2));
    return rig;
  }

  testWidgets('push and back: the Chapter 1 report', (tester) async {
    final rig = await atTower(tester);
    final router = rig.container.read(routerProvider);
    await strip(
      tester,
      'push-report',
      DaylightMotion.page,
      start: () async => router.go(Routes.report),
    );
    await rig.until(find.byType(ChapterReportScreen));
    await rig.run(const Duration(seconds: 1));
    await strip(
      tester,
      'back-report',
      DaylightMotion.page,
      start: () async => router.go(Routes.tower()),
    );
  });

  testWidgets('a tab: fade-through to the Recall Room and back', (
    tester,
  ) async {
    final rig = await atTower(tester);
    await strip(
      tester,
      'tab-recall',
      DaylightMotion.page,
      start: () => tester.tap(find.text(TowerScreen.recallTab)),
    );
    await rig.until(find.byType(RecallScreen));
    await rig.run(const Duration(seconds: 1));
    await strip(
      tester,
      'tab-back',
      DaylightMotion.page,
      start: () => tester.binding.handlePopRoute().then((_) {}),
    );
  });

  testWidgets('through the door: into room 2 and back out', (tester) async {
    final rig = await atTower(tester);
    final door = find.bySemanticsLabel(RegExp(r'^Room 2, .*\. Play\.$'));
    await tester.ensureVisible(door);
    await rig.run(const Duration(milliseconds: 600));
    await tester.tap(door);
    // The ride (skippable): its doors shut, then the room opens from the tapped door.
    await rig.until(
      find.byType(MissionScreen),
      step: const Duration(milliseconds: 16),
    );
    await strip(tester, 'door-in', DaylightMotion.door);
    await rig.run(const Duration(seconds: 2));
    await strip(
      tester,
      'door-out',
      DaylightMotion.door,
      start: () async => rig.container.read(routerProvider).go(Routes.tower()),
    );
  });

  testWidgets('reduced motion: the door is a short cross-fade', (tester) async {
    final rig = await atTower(tester, still: true);
    await strip(
      tester,
      'door-reduced',
      DaylightMotion.reducedPage,
      start: () async =>
          rig.container.read(routerProvider).go(Routes.mission(2)),
    );
  });

  testWidgets('a sheet rises with a settle: floor 2', (tester) async {
    final rig = await atTower(tester);
    final floor = find.text(NorthstarTower.floorLine(chapters[1]));
    await tester.ensureVisible(floor);
    await rig.run(const Duration(milliseconds: 600));
    await strip(
      tester,
      'sheet-floor',
      DaylightMotion.move,
      start: () => tester.tap(floor),
    );
  });

  testWidgets('back at the root: the Daylight exit hint', (tester) async {
    final rig = await atTower(tester);
    await strip(
      tester,
      'exit-hint',
      DaylightMotion.colour,
      start: () => tester.binding.handlePopRoute().then((_) {}),
    );
    expect(find.text(BackToExit.hint), findsOneWidget);
    await rig.run(BackToExit.window);
  });
}
