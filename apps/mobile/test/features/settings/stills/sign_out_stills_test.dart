import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/features/settings/account/save_progress_card.dart';
import 'package:the_last_room/features/settings/account/save_progress_controller.dart';

import '../../../core/backend/fakes.dart';
import '../../mission/mission_harness.dart';

/// "Sign out" (#68) in the real Settings screen at a 390 × 844 phone: the saved card with its
/// two ways out, each confirm sheet, the blocked sign-out, and where a sign-out lands (the
/// title, as a new player). With `WRITE_STILLS=1` each is saved at 2x in `.pr-screenshots/68/`.
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
      File('../../.pr-screenshots/68/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<MissionRig> boot(
    WidgetTester tester, {
    PendingUploads left = (rooms: 0, other: 0),
  }) async {
    final server = FakeBackend()..confirmedEmail = email;
    final rig = MissionRig(tester);
    rig.overrides.addAll([
      envProvider.overrideWithValue(keyedEnv),
      backendProvider.overrideWithValue(server),
      accountDevicePrepProvider.overrideWithValue(() async => true),
      signOutBackupProvider.overrideWithValue(() async => left),
      playerDataWipeProvider.overrideWithValue(
        () => rig.profile.save(const PlayerProfile()),
      ),
    ]);
    await rig.boot(Routes.settings, size: phone, reduceMotion: true);
    rig.container
        .read(sessionProvider.notifier)
        .signedIn(
          const GuestSession(userId: FakeBackend.guestId, email: email),
        );
    await rig.until(find.text(SaveProgressCard.switchEmail));
    return rig;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pump();
    await tester.tap(find.text(text).last);
  }

  testWidgets('the saved card, the sheets, blocked, and signed out', (
    tester,
  ) async {
    await boot(tester);
    await still(tester, '20-saved-sign-out');

    await tap(tester, SaveProgressCard.signOut);
    await still(tester, '21-sign-out-sheet');
    await tap(tester, SaveProgressCard.cancel);

    await tap(tester, SaveProgressCard.switchEmail);
    await still(tester, '22-different-email-sheet');
    await tap(tester, SaveProgressCard.cancel);

    await boot(tester, left: (rooms: 3, other: 0));
    await tap(tester, SaveProgressCard.signOut);
    await tester.pump(const Duration(milliseconds: 400));
    await tap(tester, SaveProgressCard.signOut);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text(SaveProgressCard.heading));
    await still(tester, '23-sign-out-blocked');

    await boot(tester);
    await tap(tester, SaveProgressCard.signOut);
    await tester.pump(const Duration(milliseconds: 400));
    await tap(tester, SaveProgressCard.signOut);
    await still(tester, '24-signed-out-title');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(linkPollWindow + resendCooldown);
  });
}
