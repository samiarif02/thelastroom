import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/sync/outbox.dart';
import 'package:the_last_room/features/settings/account/save_progress_card.dart';
import 'package:the_last_room/features/settings/account/save_progress_controller.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';

import '../../core/backend/fakes.dart';
import '../../ui/harness.dart';

/// FR-3, "Sign out" on a saved account: a confirm sheet; everything backs up first, and anything
/// that can't blocks it; on the way out the session ends, the player data is cleared and a new
/// guest signs in. Cancel changes nothing. No email in an event or the log.
void main() {
  const email = 'player@example.com';
  late FakeBackend server;
  late RecordingAnalytics analytics;
  late CapturedLog log;
  late ProviderContainer container;
  late PendingUploads left;
  late int backups;
  late int wipes;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester tester) async {
    server = FakeBackend()
      ..confirmedEmail = email
      ..accounts[email] = FakeBackend.guestId;
    analytics = RecordingAnalytics();
    log = CapturedLog();
    left = (rooms: 0, other: 0);
    backups = 0;
    wipes = 0;
    container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(keyedEnv),
        backendProvider.overrideWithValue(server),
        analyticsProvider.overrideWithValue(analytics),
        logProvider.overrideWithValue(log.log),
        accountDevicePrepProvider.overrideWithValue(() async => false),
        signOutBackupProvider.overrideWithValue(() async {
          backups++;
          return left;
        }),
        playerDataWipeProvider.overrideWithValue(() async => wipes++),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionProvider.notifier)
        .signedIn(
          const GuestSession(userId: FakeBackend.guestId, email: email),
        );
    await pumpKit(
      tester,
      UncontrolledProviderScope(
        container: container,
        // A navigator, for the confirm sheet.
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: DaylightPanel(child: SaveProgressCard()),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  SaveProgressFace face(WidgetTester tester) => SaveProgressFace.values
      .singleWhere((f) => find.byKey(ValueKey(f)).evaluate().isNotEmpty);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  /// Opens the sheet and confirms with its "Sign out".
  Future<void> signOut(WidgetTester tester) async {
    await tapText(tester, SaveProgressCard.signOut);
    expect(find.byType(ChoiceSheet), findsOneWidget);
    await tapText(tester, SaveProgressCard.signOut);
  }

  void expectNoEmailLeaked() {
    for (final record in log.records) {
      expect('${record.message} ${record.fields}', isNot(contains('@')));
    }
  }

  testWidgets('a saved account offers "Sign out" and "Use a different email"', (
    tester,
  ) async {
    await pump(tester);
    expect(face(tester), SaveProgressFace.linked);
    expect(find.text(SaveProgressCard.signOut), findsOneWidget);
    expect(find.text(SaveProgressCard.switchEmail), findsOneWidget);
  });

  testWidgets(
    'the sheet names the email and how to come back; Cancel does nothing',
    (tester) async {
      await pump(tester);
      await tapText(tester, SaveProgressCard.signOut);
      expect(find.text(SaveProgressCard.signOutTitle(email)), findsOneWidget);
      expect(find.text(SaveProgressCard.signOutLine), findsOneWidget);
      await tapText(tester, SaveProgressCard.cancel);
      expect(find.byType(ChoiceSheet), findsNothing);
      expect(backups, 0);
      expect(server.signOuts, 0);
      expect(wipes, 0);
      expect(face(tester), SaveProgressFace.linked);
      expect(
        analytics.events,
        isNot(contains(AnalyticsEvent.accountSignedOut)),
      );
    },
  );

  testWidgets(
    '"Use a different email" explains: sign out, then sign in with it',
    (tester) async {
      await pump(tester);
      await tapText(tester, SaveProgressCard.switchEmail);
      expect(find.text(SaveProgressCard.switchTitle), findsOneWidget);
      expect(find.text(SaveProgressCard.switchLine(email)), findsOneWidget);
      await tapText(tester, SaveProgressCard.cancel);
      expect(server.signOuts, 0);
    },
  );

  testWidgets('rooms not backed up yet block the sign-out, nothing is lost', (
    tester,
  ) async {
    await pump(tester);
    left = (rooms: 3, other: 0);
    await signOut(tester);
    expect(backups, 1);
    expect(
      find.text(SaveProgressCard.unsyncedLine((rooms: 3, other: 0))),
      findsOneWidget,
    );
    expect(
      SaveProgressCard.unsyncedLine((rooms: 3, other: 0)),
      '3 rooms haven’t backed up yet. Connect to the internet, then sign out.',
    );
    expect(server.signOuts, 0);
    expect(wipes, 0);
    expect(face(tester), SaveProgressFace.linked);
    expect(
      container.read(sessionProvider),
      const GuestSession(userId: FakeBackend.guestId, email: email),
    );
    expect(analytics.events, isNot(contains(AnalyticsEvent.accountSignedOut)));
    expect(log.records.map((r) => r.message), contains('sign out blocked'));
    expectNoEmailLeaked();

    // Back online: the second try goes through.
    left = (rooms: 0, other: 0);
    await signOut(tester);
    expect(server.signOuts, 1);
  });

  testWidgets('only the profile waiting still blocks it', (tester) async {
    await pump(tester);
    left = (rooms: 0, other: 1);
    await signOut(tester);
    expect(
      find.text(SaveProgressCard.unsyncedLine((rooms: 0, other: 1))),
      findsOneWidget,
    );
    expect(server.signOuts, 0);
  });

  testWidgets(
    'signed out: data cleared, a new guest, the event, back to saving',
    (tester) async {
      await pump(tester);
      await signOut(tester);
      expect(backups, 1);
      expect(server.signOuts, 1);
      expect(wipes, 1);
      // A new anonymous guest, a different user, with nothing linked.
      expect(
        container.read(sessionProvider),
        const GuestSession(userId: FakeBackend.nextGuestId),
      );
      expect(server.signInCalls, 1);
      expect(analytics.events, contains(AnalyticsEvent.accountSignedOut));
      expect(analytics.events, contains(AnalyticsEvent.guestStarted));
      // The card is a guest's again, with the way back in.
      expect(face(tester), SaveProgressFace.enterEmail);
      expect(find.text(SaveProgressCard.toSignIn), findsOneWidget);
      expect(container.read(saveProgressProvider).signedOutHere, isFalse);
      expectNoEmailLeaked();
    },
  );

  testWidgets('a sign-out the server refuses keeps the account, and says so', (
    tester,
  ) async {
    await pump(tester);
    server.nextAuthFailure = AccountFailure.unavailable;
    await signOut(tester);
    expect(wipes, 0);
    expect(face(tester), SaveProgressFace.linked);
    expect(find.text(SaveProgressCard.signOutFailed), findsOneWidget);
    expect(analytics.events, isNot(contains(AnalyticsEvent.accountSignedOut)));
  });

  testWidgets('2x text: the saved card and its sheet fit', (tester) async {
    await pump(tester);
    tester.view.physicalSize =
        const Size(360, 780) * tester.view.devicePixelRatio;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 780),
          textScaler: TextScaler.linear(2),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: UncontrolledProviderScope(
            container: container,
            child: Navigator(
              onGenerateRoute: (_) => PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: DaylightPanel(child: SaveProgressCard()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    await tapText(tester, SaveProgressCard.signOut);
    expect(tester.takeException(), isNull);
  });
}
