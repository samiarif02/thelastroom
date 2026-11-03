import 'dart:io';
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/recall/recall_controller.dart';
import 'package:the_last_room/features/tips/tip_overlay.dart';
import 'package:the_last_room/features/tips/tips.dart';
import 'package:the_last_room/ui/paper/dossier.dart';

import '../../../core/notifications/reminder_fakes.dart'
    show MemoryReminderStore;
import '../../mission/mission_harness.dart';
import '../../tower/played_attempt.dart';
import '../../voice/voice_rig.dart';

/// Every first-time tip as the player meets it, with real type, at the owner's phone
/// (360 × 800), and the larger ones at 2x text. Every state must draw without an exception;
/// with `WRITE_STILLS=1` each is saved as a PNG at 2x in `.pr-screenshots/48/tips-*.png`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const small = Size(360, 800);

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
      File('../../.pr-screenshots/48/tips-$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  MissionRig rig(WidgetTester tester, Tip tip) {
    final r = MissionRig(tester);
    r.tips.flags.remove(tip);
    r.overrides.add(
      reminderSettingsStoreProvider.overrideWithValue(
        MemoryReminderStore(const ReminderSettings(offered: true)),
      ),
    );
    return r;
  }

  for (final scale in [1.0, 2.0]) {
    final x = scale == 1 ? '' : '-2x';
    testWidgets('tower_door$x', (tester) async {
      final r = rig(tester, Tip.towerDoor);
      await r.boot(Routes.tower(), size: small, textScale: scale);
      await r.until(find.byType(TipOverlay));
      await r.run(const Duration(seconds: 1));
      await still(tester, 'door$x', small);
    });

    testWidgets('answer_cards$x', (tester) async {
      final r = rig(tester, Tip.answerCards);
      await r.boot(Routes.mission(1), size: small, textScale: scale);
      await r.playLines(1);
      await r.skipDraft();
      await r.until(find.byType(TipOverlay));
      await r.run(const Duration(seconds: 1));
      await still(tester, 'cards$x', small);
    });
  }

  testWidgets('why_step', (tester) async {
    final r = rig(tester, Tip.whyStep);
    await r.boot(Routes.mission(1), size: small);
    await r.playLines(1);
    await r.skipDraft();
    await r.until(find.byType(ChoiceCard));
    await r.pick(r.state(1).optionsForBeat(0).first);
    await r.until(find.byType(TipOverlay));
    await r.run(const Duration(seconds: 1));
    await still(tester, 'why', small);
  });

  testWidgets('first_result', (tester) async {
    final r = rig(tester, Tip.firstResult);
    await r.boot(Routes.mission(1), size: small);
    await r.play(
      1,
      beats: const [
        'm01_open_role_fit',
        'm01_evidence_team_did',
        'm01_land_bring_habit',
      ],
      reply: 'm01_reply_part_led_it',
    );
    await r.until(find.byType(Dossier));
    await r.run(BrandMotion.dossier + BrandMotion.pen);
    await r.until(find.byType(TipBubble));
    await r.run(const Duration(seconds: 1));
    await still(tester, 'result', small);
  });

  testWidgets('your_file', (tester) async {
    final r = rig(tester, Tip.yourFile);
    await r.progress.recordAttempt(playedAttempt(missions[0]));
    await r.boot(Routes.tower(lit: 1), size: small);
    await r.until(find.byType(TipOverlay));
    await r.run(const Duration(seconds: 1));
    await still(tester, 'file', small);
  });

  testWidgets('recall_due', (tester) async {
    final r = rig(tester, Tip.recallDue);
    r.overrides.add(recallDueCountProvider.overrideWith((ref) async => 2));
    await r.progress.recordAttempt(playedAttempt(missions[0]));
    await r.boot(Routes.tower(), size: small);
    await r.until(find.byType(TipOverlay));
    await r.run(const Duration(seconds: 1));
    await still(tester, 'recall', small);
  });

  testWidgets('voice_mic', (tester) async {
    final r = VoiceRig(tester);
    r.tips.flags.remove(Tip.voiceMic);
    await r.boot();
    await r.playToAnswer();
    await r.until(find.byType(TipOverlay));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await still(tester, 'mic', VoiceRig.phone);
  });
}
