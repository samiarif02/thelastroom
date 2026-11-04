import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/features/settings/account/save_progress_card.dart';
import 'package:the_last_room/features/settings/account/save_progress_controller.dart';

import '../../../core/backend/fakes.dart';
import '../../mission/mission_harness.dart';

/// FR-3 in the real Settings screen ("You" tab), at a 390 × 844 phone: every face of the "Save
/// your progress" card, from no backend to linked, plus the sign-in path and 2x text. Every
/// still must draw without an exception; with `WRITE_STILLS=1` each is also saved as a PNG at
/// 2x in `.pr-screenshots/67/` (the link flow; #68's code flow was `60/`).
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const phone = Size(390, 844);
  const email = 'sami@example.com';

  Future<void> still(WidgetTester tester, String name) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
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
      File('../../.pr-screenshots/67/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<(MissionRig, FakeBackend)> boot(
    WidgetTester tester, {
    bool backend = true,
    BackendSession session = const GuestSession(userId: FakeBackend.guestId),
    double textScale = 1,
  }) async {
    final server = FakeBackend();
    final rig = MissionRig(tester)
      ..overrides.addAll([
        envProvider.overrideWithValue(backend ? keyedEnv : emptyEnv),
        backendProvider.overrideWithValue(server),
        accountDevicePrepProvider.overrideWithValue(() async => true),
      ]);
    await rig.boot(
      Routes.settings,
      size: phone,
      textScale: textScale,
      reduceMotion: true,
    );
    if (session is GuestSession) {
      rig.container.read(sessionProvider.notifier).signedIn(session);
    }
    await rig.until(find.byType(SaveProgressCard));
    return (rig, server);
  }

  SaveProgressController flow(MissionRig rig) =>
      rig.container.read(saveProgressProvider.notifier);

  testWidgets('no backend, offline, idle and the email error', (tester) async {
    await boot(tester, backend: false, session: const NoSession());
    await still(tester, '01-no-backend');

    await boot(tester, session: const NoSession());
    await still(tester, '02-offline');

    var (rig, _) = await boot(tester);
    await still(tester, '03-idle');

    await tester.enterText(find.byType(EditableText), email);
    await still(tester, '04-email-typed');

    (rig, _) = await boot(tester);
    await flow(rig).sendLink('not an email');
    await still(tester, '05-invalid-email');
    await _done(tester);
  });

  testWidgets('link sent, resend, rate-limited, offline, linked', (
    tester,
  ) async {
    var (rig, server) = await boot(tester);
    final sending = server.authGate = Completer<void>();
    unawaited(flow(rig).sendLink(email));
    await still(tester, '06-sending');
    sending.complete();
    server.authGate = null;
    await still(tester, '07-link-sent');

    await tester.pump(resendCooldown);
    await flow(rig).resend();
    await still(tester, '08-link-resent');

    (rig, server) = await boot(tester);
    server.nextAuthFailure = AccountFailure.rateLimited;
    await flow(rig).sendLink(email);
    await still(tester, '09-rate-limited');

    (rig, server) = await boot(tester);
    server.nextAuthFailure = AccountFailure.offline;
    await flow(rig).sendLink(email);
    await still(tester, '10-offline-sending');

    (rig, server) = await boot(tester);
    await flow(rig).sendLink(email);
    server.tapLink();
    await flow(rig).checkLink();
    await still(tester, '11-linked');
    await _done(tester);
  });

  testWidgets('sign in on another device, the expired link, and 2x text', (
    tester,
  ) async {
    var (rig, server) = await boot(tester);
    flow(rig).useMode(AccountMode.signIn);
    await still(tester, '12-sign-in');

    server.accounts[email] = FakeBackend.accountId;
    await flow(rig).sendLink(email);
    await still(tester, '13-sign-in-link-sent');

    server.openRefusedLink();
    await still(tester, '14-link-expired');

    (rig, server) = await boot(tester);
    server.accounts[email] = FakeBackend.accountId;
    server.openSignInLink(email);
    await still(tester, '15-signed-in-here');

    (rig, server) = await boot(tester);
    flow(rig).useMode(AccountMode.signIn);
    await flow(rig).sendLink(email);
    await still(tester, '16-no-account');

    (rig, server) = await boot(tester, textScale: 2);
    await flow(rig).sendLink(email);
    await still(tester, '17-link-sent-2x');
    await _done(tester);
  });
}

/// Unmounts the app and lets its timers (the tower's idle loops, the link step's poll and
/// resend cooldown) run out.
Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(linkPollWindow + resendCooldown);
}
