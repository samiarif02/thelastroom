import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/voice/widgets/listen_tile.dart';
import 'package:the_last_room/features/voice/widgets/self_check_panel.dart';

import '../voice_rig.dart';

/// The self-check's player (brief 63): idle, playing at 0:07, paused. Every state must draw
/// without an exception; with `WRITE_STILLS=1` each is saved at 2x in `STILLS_DIR` (default
/// `.pr-screenshots/63/`).
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  final dir = Platform.environment['STILLS_DIR'] ?? '../../.pr-screenshots/63';
  const pixelRatio = 2.0;

  Future<void> still(VoiceRig rig, String name) async {
    await rig.tester.pump();
    expect(rig.tester.takeException(), isNull, reason: name);
    if (!write) return;
    final boundary = rig.tester.renderObject<RenderRepaintBoundary>(
      find.byKey(VoiceRig.frame),
    );
    await rig.tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('the self-check player: idle, playing, paused', (tester) async {
    final rig = VoiceRig(tester);
    await rig.boot();
    await rig.answerBoth();
    await rig.until(find.text(SelfCheckPanel.title));
    // Past the panel's fade in.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await still(rig, 'listen-idle');
    await rig.tap(find.text(SelfCheckPanel.listenAnswer));
    rig.playback.at = const Duration(seconds: 1);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await still(rig, 'listen-playing');
    await rig.tap(find.text(ListenTile.pause));
    await still(rig, 'listen-paused');
    await rig.tap(find.text(SelfCheckPanel.score));
  });
}
