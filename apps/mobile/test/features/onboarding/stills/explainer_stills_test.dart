import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/onboarding/explainer_copy.dart';
import 'package:the_last_room/features/onboarding/how_it_works_screen.dart';
import 'package:the_last_room/features/progression/interview_date_choices.dart';
import 'package:the_last_room/features/settings/settings_screen.dart';

import '../../mission/mission_harness.dart';

/// Issue 75's "How it works" with real type at a 390 × 844 phone, and at 2x text: each of the
/// five pages, the first question after it, and the Settings card that replays it. Each must
/// draw without an exception; with `WRITE_STILLS=1` each is saved as a PNG at 2x in
/// `.pr-screenshots/75/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const phone = Size(390, 844);
  const settle = Duration(seconds: 3);

  Future<void> still(WidgetTester tester, String name) async {
    await tester.pump();
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & (phone * dpr),
        pixelRatio: pixelRatio / dpr,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/75/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> tap(MissionRig rig, String text) async {
    final f = find.text(text);
    await rig.tester.ensureVisible(f);
    await rig.tester.pump();
    await rig.tester.tap(f);
    await rig.tester.pump();
  }

  for (final scale in [1.0, 2.0]) {
    final x = scale == 1 ? '' : '-2x';
    testWidgets('the five pages, then the first question$x', (tester) async {
      final rig = MissionRig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.onboarding, size: phone, textScale: scale);
      for (var i = 0; i < ExplainerCopy.pages.length; i++) {
        await rig.until(find.text(ExplainerCopy.pages[i].title));
        await rig.run(settle);
        await still(tester, 'page-${i + 1}$x');
        final last = i == ExplainerCopy.pages.length - 1;
        await tap(rig, last ? ExplainerCopy.ready : ExplainerCopy.next);
      }
      await rig.until(find.text(InterviewDateChoices.title));
      await rig.run(settle);
      await still(tester, 'questions-1$x');
    });
  }

  testWidgets('Settings: "How it works", and its replay', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.settings, size: phone);
    await rig.until(find.byType(SettingsScreen));
    await rig.run(settle);
    final how = find.text(SettingsScreen.how);
    await tester.ensureVisible(how);
    await rig.run(settle);
    await still(tester, 'settings-how-it-works');
    await tester.tap(how);
    await rig.until(find.byType(HowItWorksScreen));
    await rig.run(settle);
    await still(tester, 'replay-page-1');
  });
}
