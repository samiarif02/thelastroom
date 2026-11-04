import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/redact.dart';
import 'package:the_last_room/features/settings/account/save_progress_card.dart';
import 'package:the_last_room/features/settings/account/save_progress_controller.dart';
import 'package:the_last_room/ui/daylight/daylight_kit.dart';

import '../../core/backend/fakes.dart';
import '../../ui/harness.dart';

/// FR-3, "Save your progress": every face of the card against a fake auth server: no backend,
/// offline, the email step, sending, the code step, verifying, each failure, and linked. Linking
/// keeps the guest's user id; signing in on another device switches to the account's and
/// readies the merge. No email reaches an event or the log.
void main() {
  const email = 'player@example.com';
  late FakeBackend server;
  late RecordingAnalytics analytics;
  late CapturedLog log;
  late ProviderContainer container;
  late int preps;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    Env env = keyedEnv,
    BackendSession session = const GuestSession(userId: FakeBackend.guestId),
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    server = FakeBackend();
    analytics = RecordingAnalytics();
    log = CapturedLog();
    preps = 0;
    container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(env),
        backendProvider.overrideWithValue(server),
        analyticsProvider.overrideWithValue(analytics),
        logProvider.overrideWithValue(log.log),
        accountDevicePrepProvider.overrideWithValue(() async {
          preps++;
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    if (session is GuestSession) {
      container.read(sessionProvider.notifier).signedIn(session);
    }
    await pumpKit(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: DaylightPanel(child: SaveProgressCard()),
        ),
      ),
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    await settle(tester);
  }

  SaveProgressFace face(WidgetTester tester) => SaveProgressFace.values
      .singleWhere((f) => find.byKey(ValueKey(f)).evaluate().isNotEmpty);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await settle(tester);
  }

  Future<void> typeEmail(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(EditableText), value);
    await tester.pump();
  }

  Future<void> typeCode(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(EditableText), value);
    await tester.pump();
  }

  Future<void> toCodeStep(WidgetTester tester) async {
    await typeEmail(tester, '  Player@Example.com ');
    await tapText(tester, SaveProgressCard.sendCode);
  }

  /// Every log line and every event, as text: none may hold the email.
  void expectNoEmailLeaked() {
    for (final record in log.records) {
      expect('${record.message} ${record.fields}', isNot(contains('@')));
    }
    expect(
      analytics.events.map((e) => e.wireName).join(),
      isNot(contains('@')),
    );
  }

  testWidgets('no backend: a calm note, nothing to press', (tester) async {
    await pump(tester, env: emptyEnv, session: const NoSession());
    expect(face(tester), SaveProgressFace.noBackend);
    expect(find.text(SaveProgressCard.noBackendLine), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(find.byType(TactileButton), findsNothing);
    expect(server.authCalls, isEmpty);
  });

  testWidgets('offline since launch (no session yet): safe on this device', (
    tester,
  ) async {
    await pump(tester, session: const NoSession());
    expect(face(tester), SaveProgressFace.offline);
    expect(find.text(SaveProgressCard.offlineLine), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('idle guest: the email step, the button waits for an address', (
    tester,
  ) async {
    await pump(tester);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.linkLine), findsOneWidget);
    expect(find.text(SaveProgressCard.tagGuest), findsOneWidget);
    final send = tester.widget<TactileButton>(
      find.widgetWithText(TactileButton, SaveProgressCard.sendCode),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('a malformed address never reaches the server', (tester) async {
    await pump(tester);
    await typeEmail(tester, 'not-an-email');
    await tapText(tester, SaveProgressCard.sendCode);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.invalidEmail), findsOneWidget);
    expect(server.authCalls, isEmpty);
  });

  testWidgets('link: sending, code sent, verifying, linked with the same id', (
    tester,
  ) async {
    await pump(tester);
    server.authGate = Completer<void>();
    await typeEmail(tester, '  Player@Example.com ');
    await tester.tap(find.text(SaveProgressCard.sendCode));
    await tester.pump();
    expect(face(tester), SaveProgressFace.sending);
    expect(find.text(SaveProgressCard.sending), findsOneWidget);

    server.authGate!.complete();
    server.authGate = null;
    await settle(tester);
    expect(face(tester), SaveProgressFace.enterCode);
    expect(find.text(SaveProgressCard.codeSentLine(email)), findsOneWidget);
    final save = find.widgetWithText(
      TactileButton,
      SaveProgressCard.saveButton,
    );
    expect(tester.widget<TactileButton>(save).onPressed, isNull);

    server.authGate = Completer<void>();
    await typeCode(tester, FakeBackend.goodCode);
    await tester.tap(save);
    await tester.pump();
    expect(face(tester), SaveProgressFace.verifying);
    expect(find.text(SaveProgressCard.verifying), findsOneWidget);

    server.authGate!.complete();
    await settle(tester);
    expect(face(tester), SaveProgressFace.linked);
    expect(find.text(SaveProgressCard.linkedLine(email)), findsOneWidget);
    expect(find.text(SaveProgressCard.tagSaved), findsOneWidget);

    // The guest's id is kept: every synced row and the RLS policies stay valid.
    final session = container.read(sessionProvider) as GuestSession;
    expect(session.userId, FakeBackend.guestId);
    expect(session.email, email);
    expect(server.authCalls, ['sendLinkCode', 'confirmLinkCode']);
    expect(preps, 0);
    expect(analytics.events, [AnalyticsEvent.accountLinked]);
    expectNoEmailLeaked();
  });

  testWidgets('a server that links without a code goes straight to linked', (
    tester,
  ) async {
    await pump(tester);
    server.linksWithoutCode = true;
    await toCodeStep(tester);
    expect(face(tester), SaveProgressFace.linked);
    expect(
      (container.read(sessionProvider) as GuestSession).userId,
      FakeBackend.guestId,
    );
    expect(analytics.events, [AnalyticsEvent.accountLinked]);
  });

  testWidgets('a wrong or expired code: stays on the code step, says so', (
    tester,
  ) async {
    await pump(tester);
    await toCodeStep(tester);
    await typeCode(tester, '000000');
    await tapText(tester, SaveProgressCard.saveButton);
    expect(face(tester), SaveProgressFace.enterCode);
    expect(find.text(SaveProgressCard.wrongCode), findsOneWidget);
    expect(container.read(sessionProvider), isA<GuestSession>());
    expect((container.read(sessionProvider) as GuestSession).isLinked, false);
    expect(analytics.events, isEmpty);
    expectNoEmailLeaked();
  });

  testWidgets('a new code on request, then the latest code works', (
    tester,
  ) async {
    await pump(tester);
    await toCodeStep(tester);
    await tapText(tester, SaveProgressCard.resend);
    expect(face(tester), SaveProgressFace.enterCode);
    expect(find.text(SaveProgressCard.resentLine), findsOneWidget);
    await typeCode(tester, FakeBackend.goodCode);
    await tapText(tester, SaveProgressCard.saveButton);
    expect(face(tester), SaveProgressFace.linked);
  });

  testWidgets('rate-limited: wait a minute', (tester) async {
    await pump(tester);
    server.nextAuthFailure = AccountFailure.rateLimited;
    await toCodeStep(tester);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.rateLimited), findsOneWidget);
  });

  testWidgets('offline mid-flow: try again, progress is safe', (tester) async {
    await pump(tester);
    await toCodeStep(tester);
    server.nextAuthFailure = AccountFailure.offline;
    await typeCode(tester, FakeBackend.goodCode);
    await tapText(tester, SaveProgressCard.saveButton);
    expect(face(tester), SaveProgressFace.enterCode);
    expect(find.text(SaveProgressCard.offline), findsOneWidget);
  });

  testWidgets('the server answering oddly is its own state', (tester) async {
    await pump(tester);
    server.nextAuthFailure = AccountFailure.unavailable;
    await toCodeStep(tester);
    expect(find.text(SaveProgressCard.unavailable), findsOneWidget);
  });

  testWidgets('an email another account holds points to "Sign in"', (
    tester,
  ) async {
    await pump(tester);
    server.accounts[email] = FakeBackend.accountId;
    await toCodeStep(tester);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.emailTaken), findsOneWidget);
    expect(find.text(SaveProgressCard.toSignIn), findsOneWidget);
  });

  testWidgets('"Use a different email" goes back with the address kept', (
    tester,
  ) async {
    await pump(tester);
    await toCodeStep(tester);
    await tapText(tester, SaveProgressCard.otherEmail);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(email), findsOneWidget);
  });

  group('sign in on another device', () {
    Future<void> toSignIn(WidgetTester tester) async {
      await pump(tester);
      server.accounts[email] = FakeBackend.accountId;
      await tapText(tester, SaveProgressCard.toSignIn);
      expect(find.text(SaveProgressCard.signInHeading), findsOneWidget);
      expect(find.text(SaveProgressCard.signInLine), findsOneWidget);
    }

    testWidgets('the account id takes over and the merge is readied first', (
      tester,
    ) async {
      await toSignIn(tester);
      await toCodeStep(tester);
      expect(face(tester), SaveProgressFace.enterCode);
      await typeCode(tester, FakeBackend.goodCode);
      await tapText(tester, SaveProgressCard.signInButton);
      expect(face(tester), SaveProgressFace.linked);
      expect(find.text(SaveProgressCard.signedInLine), findsOneWidget);
      final session = container.read(sessionProvider) as GuestSession;
      expect(session.userId, FakeBackend.accountId);
      expect(session.email, email);
      expect(preps, 1);
      expect(server.authCalls, ['sendSignInCode', 'confirmSignInCode']);
      expect(analytics.events, [AnalyticsEvent.accountSignedIn]);
      expectNoEmailLeaked();
    });

    testWidgets('an address nobody saved to: save this device instead', (
      tester,
    ) async {
      await toSignIn(tester);
      server.accounts.clear();
      await toCodeStep(tester);
      expect(face(tester), SaveProgressFace.enterEmail);
      expect(find.text(SaveProgressCard.noAccount), findsOneWidget);
      await tapText(tester, SaveProgressCard.toLink);
      expect(find.text(SaveProgressCard.linkLine), findsOneWidget);
      expect(preps, 0);
    });

    testWidgets('a wrong code leaves this device as it was', (tester) async {
      await toSignIn(tester);
      await toCodeStep(tester);
      await typeCode(tester, '999999');
      await tapText(tester, SaveProgressCard.signInButton);
      expect(find.text(SaveProgressCard.wrongCode), findsOneWidget);
      expect(
        (container.read(sessionProvider) as GuestSession).userId,
        FakeBackend.guestId,
      );
      expect(preps, 0);
    });
  });

  testWidgets('an already linked player sees the email and how to sign in', (
    tester,
  ) async {
    await pump(
      tester,
      session: const GuestSession(userId: FakeBackend.guestId, email: email),
    );
    expect(face(tester), SaveProgressFace.linked);
    expect(find.text(SaveProgressCard.linkedLine(email)), findsOneWidget);
    expect(find.text(SaveProgressCard.linkedHow), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('2x text and reduced motion: the code step still fits', (
    tester,
  ) async {
    await pump(tester, textScale: 2, reduceMotion: true);
    await toCodeStep(tester);
    expect(face(tester), SaveProgressFace.enterCode);
    expect(tester.takeException(), isNull);
  });

  test('the logger redacts an email, by key and by value', () {
    final fields = redactFields({
      'email': email,
      'note': 'sent to $email',
      'failure': 'wrongCode',
    });
    expect(fields['email'], redacted);
    expect(fields['note'], 'sent to $redacted');
    expect(fields['failure'], 'wrongCode');
  });
}
