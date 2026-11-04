import 'dart:io';
import 'dart:ui' as ui;

import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/debrief/deliberation_scene.dart';

import '../../../core/backend/fakes.dart';
import '../../mission/mission_harness.dart';

const Env _withBackend = Env(
  appEnv: 'dev',
  supabaseUrl: 'http://192.168.1.20:54321',
  supabaseAnonKey: 'public-anon-key',
  sentryDsn: '',
  posthogApiKey: '',
  posthogHost: '',
);

const Map<String, Object?> _verdict = {
  'model': 'gemini-3.8-flash',
  'overall': {'score': 74, 'basis': 'A relevant, evidenced answer.'},
  'dimensions': {
    'relevance': {'score': 85, 'basis': 'It answers why this role.'},
    'specificity': {'score': 70, 'basis': 'One project with a number.'},
    'structure': {'score': 60, 'basis': 'The close trails off.'},
    'adaptability': {'score': 80, 'basis': 'The reply names their part.'},
  },
};

/// Issue 70's moments at a 390 × 844 phone: the interviewer reading the file while the AI
/// scores (three beats, "Almost there…", reduced motion), and a late verdict's banner over the
/// offline sheet, then swapped in. Each must draw without an exception; with `WRITE_STILLS=1`
/// each is saved at 2x in `.pr-screenshots/70/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const phone = Size(390, 844);

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
      File('../../.pr-screenshots/70/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<MissionRig> playToDebrief(
    WidgetTester tester,
    FakeBackend backend, {
    bool reduceMotion = false,
  }) async {
    final rig = MissionRig(tester)
      ..scorer = AiScorer(
        env: _withBackend,
        session: const GuestSession(userId: FakeBackend.guestId),
        backend: () => backend,
        log: Log(),
      );
    await rig.boot(Routes.mission(1), size: phone, reduceMotion: reduceMotion);
    const m = missionTheOpportunity;
    await rig.playLines(1);
    await rig.skipDraft();
    for (final beat in m.beats) {
      await rig.say(beat.options.firstWhere((o) => beat.isStrongest(o.id)));
    }
    final followUp = rig.state(1).followUpLine!;
    await rig.until(find.text(followUp.text));
    await rig.run(const Duration(milliseconds: 300));
    if (rig.typing) await rig.tapScene();
    await rig.say(rig.state(1).replyOptions.first);
    await rig.until(find.byType(DeliberationScene));
    return rig;
  }

  testWidgets('the interviewer reads the file while the AI scores', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..scorer = (_) =>
          Future<Object?>.delayed(const Duration(seconds: 7), () => _verdict);
    final rig = await playToDebrief(tester, backend);
    await rig.run(const Duration(milliseconds: 1200));
    await still(tester, '01-reading');
    await rig.run(const Duration(milliseconds: 1500));
    await still(tester, '02-weighing-ticks');
    await rig.run(const Duration(milliseconds: 1800));
    await still(tester, '03-writing-almost-there');
    await rig.until(find.text(ScoreSourceLabel.aiLabel));
    await rig.settleDossier();
    await still(tester, '04-then-the-ai-sheet');
  });

  testWidgets('reduced motion: one still frame', (tester) async {
    final backend = FakeBackend()
      ..scorer = (_) =>
          Future<Object?>.delayed(const Duration(seconds: 3), () => _verdict);
    final rig = await playToDebrief(tester, backend, reduceMotion: true);
    await rig.run(const Duration(seconds: 1));
    await still(tester, '05-reduced-motion');
    await rig.until(find.text(ScoreSourceLabel.aiLabel));
    await rig.settleDossier();
  });

  testWidgets('a late verdict waits in a banner, then swaps in', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..scorer = (_) => Future<Object?>.delayed(
        AiScorer.timeout + const Duration(seconds: 4),
        () => _verdict,
      );
    final rig = await playToDebrief(tester, backend);
    final banner = find.text(LateVerdictBanner.title).hitTestable();
    await rig.until(banner);
    await rig.run(const Duration(seconds: 1));
    await still(tester, '06-late-banner-over-offline');
    await tester.tap(banner);
    await rig.run(const Duration(seconds: 1));
    await still(tester, '07-late-swapped-in');
  });
}
