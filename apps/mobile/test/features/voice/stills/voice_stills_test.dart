import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/debrief/deliberation_scene.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/features/voice/voice_debrief.dart';
import 'package:the_last_room/features/voice/widgets/self_check_panel.dart';

import '../voice_fixture.dart';
import '../voice_mission_test.dart' show verdict;
import '../voice_rig.dart';

/// Plays the voice mission into each state the PR shows, with real type. Every state must draw
/// without an exception; with `WRITE_STILLS=1` each is also saved as a PNG for the PR
/// (`.pr-screenshots/35/`), at 2x, the phone's 390 × 844.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
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
      final file = File('../../.pr-screenshots/35/$name.png')
        ..createSync(recursive: true);
      file.writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('the recorder, from the explainer to the cap', (tester) async {
    final rig = VoiceRig(tester)
      ..newMic = () => FakeMicrophone(alreadyAllowed: false);
    await rig.boot();
    await rig.playToAnswerExplained();
    await still(rig, '01-explainer');
    await rig.tap(find.text(RecorderPanel.allow));
    await rig.until(find.text(RecorderPanel.readyLine));
    await still(rig, '02-ready');
    await rig.tap(find.bySemanticsLabel(RecorderPanel.recordLabel));
    rig.mic.speak(const Duration(seconds: 12));
    await still(rig, '03-recording');
    rig.mic.hush(const Duration(seconds: 5));
    await rig.until(find.text(RecorderPanel.silenceLine));
    await still(rig, '04-paused-by-silence');
    await rig.tap(find.text(RecorderPanel.delete));
    await still(rig, '05-delete-confirm');
    await rig.tap(find.text('Keep it'));
    await rig.tap(find.text(RecorderPanel.resume));
    rig.mic.speak(const Duration(seconds: 20));
    await rig.until(
      find.text(RecorderPanel.fullLine(const Duration(seconds: 30))),
    );
    await still(rig, '06-full-at-the-cap');
  });

  testWidgets('the microphone refused', (tester) async {
    final rig = VoiceRig(tester)
      ..newMic = () => FakeMicrophone(alreadyAllowed: false, granted: false);
    await rig.boot();
    await rig.playToAnswerExplained();
    await rig.tap(find.text(RecorderPanel.allow));
    await rig.until(find.text(RecorderPanel.deniedTitle));
    await still(rig, '07-microphone-refused');
  });

  testWidgets('the follow-up, the self-check and its debrief', (tester) async {
    final rig = VoiceRig(tester);
    await rig.boot();
    await rig.playToAnswer();
    await rig.recordAndSubmit();
    await rig.until(find.text(RecorderPanel.readyLine), absent: true);
    await rig.until(find.text(RecorderPanel.readyLine).hitTestable());
    await still(rig, '08-follow-up-reply');
    await rig.recordAndSubmit(length: const Duration(seconds: 2));
    await rig.until(find.text(SelfCheckPanel.title));
    await rig.tap(find.text('Names what changed and when'));
    await rig.tap(find.text('Names one thing you would change'));
    await still(rig, '09-self-check');
    await rig.tap(find.text(SelfCheckPanel.score));
    await rig.settleDebrief();
    await still(rig, '10-debrief-self-check');
  });

  testWidgets('the AI verdict: listening, then the debrief', (tester) async {
    final rig = VoiceRig(tester, online: true);
    rig.backend.voiceScorer = (_) async {
      await Future<void>.delayed(const Duration(seconds: 3));
      return verdict();
    };
    await rig.boot();
    await rig.answerBoth();
    await rig.until(find.byType(DeliberationScene));
    // Past the entrance and into the first ticks.
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await still(rig, '11-listening');
    await rig.settleDebrief();
    await still(rig, '12-debrief-ai');
    await tester.ensureVisible(find.text(HeardSlip.heading));
    await tester.pump();
    await still(rig, '13-debrief-what-we-heard');
    await tester.ensureVisible(find.text(VoiceLessonSlip.heading));
    await tester.pump();
    await still(rig, '14-debrief-points-and-lesson');
  });
}
