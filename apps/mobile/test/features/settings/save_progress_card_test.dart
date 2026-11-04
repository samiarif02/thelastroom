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
/// offline, the email step, sending, link sent (resume, poll, resend), each failure, and linked.
/// Linking keeps the guest's user id; a sign-in link opened in the app switches to the account's
/// and readies the merge. No email reaches an event or the log.
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

  Future<void> toLinkSent(WidgetTester tester) async {
    await typeEmail(tester, '  Player@Example.com ');
    await tapText(tester, SaveProgressCard.sendLink);
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
      find.widgetWithText(TactileButton, SaveProgressCard.sendLink),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('a malformed address never reaches the server', (tester) async {
    await pump(tester);
    await typeEmail(tester, 'not-an-email');
    await tapText(tester, SaveProgressCard.sendLink);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.invalidEmail), findsOneWidget);
    expect(server.authCalls, isEmpty);
  });

  /// Leaves the link-sent step's timers (the resend cooldown, the poll window) to run out.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(linkPollWindow + resendCooldown);
    await settle(tester);
  }

  /// The player switches to their mail app and back (the app goes inactive, then resumes).
  Future<void> leaveAndReturn(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
  }

  int refreshes() =>
      server.authCalls.where((c) => c == 'refreshAccount').length;

  testWidgets('link: sending, link sent, tap it, come back: linked, same id', (
    tester,
  ) async {
    await pump(tester);
    server.authGate = Completer<void>();
    await typeEmail(tester, '  Player@Example.com ');
    await tester.tap(find.text(SaveProgressCard.sendLink));
    await tester.pump();
    expect(face(tester), SaveProgressFace.sending);
    expect(find.text(SaveProgressCard.sending), findsOneWidget);

    server.authGate!.complete();
    server.authGate = null;
    await settle(tester);
    expect(face(tester), SaveProgressFace.linkSent);
    expect(find.text(SaveProgressCard.linkSentLine(email)), findsOneWidget);
    expect(find.text(SaveProgressCard.resendSoon), findsOneWidget);
    expect(server.pendingEmail, email);

    // Coming back before tapping it: checked, still waiting.
    await leaveAndReturn(tester);
    expect(face(tester), SaveProgressFace.linkSent);
    expect(refreshes(), 1);

    server.tapLink();
    await leaveAndReturn(tester);
    expect(face(tester), SaveProgressFace.linked);
    expect(find.text(SaveProgressCard.linkedLine(email)), findsOneWidget);
    expect(find.text(SaveProgressCard.tagSaved), findsOneWidget);

    // The guest's id is kept: every synced row and the RLS policies stay valid.
    final session = container.read(sessionProvider) as GuestSession;
    expect(session.userId, FakeBackend.guestId);
    expect(session.email, email);
    expect(server.authCalls, [
      'sendLinkEmail',
      'refreshAccount',
      'refreshAccount',
    ]);
    expect(preps, 0);
    expect(analytics.events, [AnalyticsEvent.accountLinked]);
    expect(container.read(saveProgressProvider.notifier).polling, isFalse);
    expectNoEmailLeaked();
  });

  testWidgets('link: the gentle poll notices the tap without leaving the app', (
    tester,
  ) async {
    await pump(tester);
    await toLinkSent(tester);
    await tester.pump(linkPollInterval);
    await settle(tester);
    expect(face(tester), SaveProgressFace.linkSent);
    server.tapLink();
    await tester.pump(linkPollInterval);
    await settle(tester);
    expect(face(tester), SaveProgressFace.linked);
    expect(
      (container.read(sessionProvider) as GuestSession).userId,
      FakeBackend.guestId,
    );
    expect(analytics.events, [AnalyticsEvent.accountLinked]);
    await drain(tester);
    expect(analytics.events, [AnalyticsEvent.accountLinked]);
  });

  testWidgets(
    'link: the poll stops after its window; coming back checks again',
    (tester) async {
      await pump(tester);
      await toLinkSent(tester);
      final controller = container.read(saveProgressProvider.notifier);
      expect(controller.polling, isTrue);
      await tester.pump(linkPollWindow);
      await settle(tester);
      expect(controller.polling, isFalse);
      final asked = refreshes();
      expect(
        asked,
        linkPollWindow.inMilliseconds ~/ linkPollInterval.inMilliseconds,
      );
      await tester.pump(const Duration(minutes: 5));
      expect(refreshes(), asked);

      server.tapLink();
      await leaveAndReturn(tester);
      expect(face(tester), SaveProgressFace.linked);
    },
  );

  testWidgets('"I’ve tapped it" checks at once', (tester) async {
    await pump(tester);
    await toLinkSent(tester);
    server.tapLink();
    await tapText(tester, SaveProgressCard.checkNow);
    expect(face(tester), SaveProgressFace.linked);
  });

  testWidgets('offline while waiting: quiet, and the next check links', (
    tester,
  ) async {
    await pump(tester);
    await toLinkSent(tester);
    server.tapLink();
    server.nextAuthFailure = AccountFailure.offline;
    await tester.pump(linkPollInterval);
    await settle(tester);
    expect(face(tester), SaveProgressFace.linkSent);
    expect(find.text(SaveProgressCard.offline), findsNothing);
    await tester.pump(linkPollInterval);
    await settle(tester);
    expect(face(tester), SaveProgressFace.linked);
  });

  testWidgets('a server that links at once goes straight to linked', (
    tester,
  ) async {
    await pump(tester);
    server.linksAtOnce = true;
    await toLinkSent(tester);
    expect(face(tester), SaveProgressFace.linked);
    expect(
      (container.read(sessionProvider) as GuestSession).userId,
      FakeBackend.guestId,
    );
    expect(analytics.events, [AnalyticsEvent.accountLinked]);
  });

  testWidgets('resend opens after a minute, then a new link is on its way', (
    tester,
  ) async {
    await pump(tester);
    await toLinkSent(tester);
    final soon = tester.widget<TactileButton>(
      find.widgetWithText(TactileButton, SaveProgressCard.resendSoon),
    );
    expect(soon.onPressed, isNull);
    await tester.pump(resendCooldown);
    await settle(tester);
    await tapText(tester, SaveProgressCard.resend);
    expect(face(tester), SaveProgressFace.linkSent);
    expect(find.text(SaveProgressCard.resentLine), findsOneWidget);
    expect(find.text(SaveProgressCard.resendSoon), findsOneWidget);
    expect(server.authCalls.where((c) => c == 'sendLinkEmail').length, 2);
    await drain(tester);
  });

  testWidgets('rate-limited: wait a minute', (tester) async {
    await pump(tester);
    server.nextAuthFailure = AccountFailure.rateLimited;
    await toLinkSent(tester);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.rateLimited), findsOneWidget);
  });

  testWidgets('a rate-limited resend keeps waiting for the first link', (
    tester,
  ) async {
    await pump(tester);
    await toLinkSent(tester);
    await tester.pump(resendCooldown);
    server.nextAuthFailure = AccountFailure.rateLimited;
    await tapText(tester, SaveProgressCard.resend);
    expect(face(tester), SaveProgressFace.linkSent);
    expect(find.text(SaveProgressCard.rateLimited), findsOneWidget);
    server.tapLink();
    await leaveAndReturn(tester);
    expect(face(tester), SaveProgressFace.linked);
  });

  testWidgets('offline when sending: try again, progress is safe', (
    tester,
  ) async {
    await pump(tester);
    server.nextAuthFailure = AccountFailure.offline;
    await toLinkSent(tester);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.offline), findsOneWidget);
  });

  testWidgets('the server answering oddly is its own state', (tester) async {
    await pump(tester);
    server.nextAuthFailure = AccountFailure.unavailable;
    await toLinkSent(tester);
    expect(find.text(SaveProgressCard.unavailable), findsOneWidget);
  });

  testWidgets('an email another account holds points to "Sign in"', (
    tester,
  ) async {
    await pump(tester);
    server.accounts[email] = FakeBackend.accountId;
    await toLinkSent(tester);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(SaveProgressCard.emailTaken), findsOneWidget);
    expect(find.text(SaveProgressCard.toSignIn), findsOneWidget);
  });

  testWidgets('"Use a different email" goes back with the address kept', (
    tester,
  ) async {
    await pump(tester);
    await toLinkSent(tester);
    await tapText(tester, SaveProgressCard.otherEmail);
    expect(face(tester), SaveProgressFace.enterEmail);
    expect(find.text(email), findsOneWidget);
    expect(container.read(saveProgressProvider.notifier).polling, isFalse);
    await drain(tester);
  });

  group('sign in on another device', () {
    Future<void> toSignIn(WidgetTester tester) async {
      await pump(tester);
      server.accounts[email] = FakeBackend.accountId;
      await tapText(tester, SaveProgressCard.toSignIn);
      expect(find.text(SaveProgressCard.signInHeading), findsOneWidget);
      expect(find.text(SaveProgressCard.signInLine), findsOneWidget);
    }

    testWidgets('the link opens the app: the account takes over, merge first', (
      tester,
    ) async {
      await toSignIn(tester);
      await toLinkSent(tester);
      expect(face(tester), SaveProgressFace.linkSent);
      expect(find.text(SaveProgressCard.signInSentLine(email)), findsOneWidget);
      expect(find.text(SaveProgressCard.checkNow), findsNothing);
      // Nothing to poll: the link itself brings the session.
      expect(container.read(saveProgressProvider.notifier).polling, isFalse);

      server.openSignInLink(email);
      await settle(tester);
      expect(face(tester), SaveProgressFace.linked);
      expect(find.text(SaveProgressCard.signedInLine), findsOneWidget);
      final session = container.read(sessionProvider) as GuestSession;
      expect(session.userId, FakeBackend.accountId);
      expect(session.email, email);
      expect(preps, 1);
      expect(server.authCalls, ['sendSignInLink']);
      expect(analytics.events, [AnalyticsEvent.accountSignedIn]);
      expectNoEmailLeaked();
    });

    testWidgets('a link that cold-starts the app still merges', (tester) async {
      await pump(tester);
      server.accounts[email] = FakeBackend.accountId;
      server.openSignInLink(email);
      await settle(tester);
      expect(face(tester), SaveProgressFace.linked);
      expect(
        (container.read(sessionProvider) as GuestSession).userId,
        FakeBackend.accountId,
      );
      expect(preps, 1);
      expect(analytics.events, [AnalyticsEvent.accountSignedIn]);
    });

    testWidgets('an expired or used link: calm, and a new one is a tap away', (
      tester,
    ) async {
      await toSignIn(tester);
      await toLinkSent(tester);
      server.openRefusedLink();
      await settle(tester);
      expect(face(tester), SaveProgressFace.linkSent);
      expect(find.text(SaveProgressCard.linkExpired), findsOneWidget);
      expect(
        (container.read(sessionProvider) as GuestSession).userId,
        FakeBackend.guestId,
      );
      expect(preps, 0);
      expect(analytics.events, isEmpty);
      expectNoEmailLeaked();
      await drain(tester);
      await tapText(tester, SaveProgressCard.resend);
      expect(find.text(SaveProgressCard.resentLine), findsOneWidget);
      await drain(tester);
    });

    testWidgets('an expired link on a cold start lands on the sign-in step', (
      tester,
    ) async {
      await pump(tester);
      server.openRefusedLink();
      await settle(tester);
      expect(face(tester), SaveProgressFace.enterEmail);
      expect(find.text(SaveProgressCard.signInHeading), findsOneWidget);
      expect(find.text(SaveProgressCard.linkExpired), findsOneWidget);
    });

    testWidgets('an address nobody saved to: save this device instead', (
      tester,
    ) async {
      await toSignIn(tester);
      server.accounts.clear();
      await toLinkSent(tester);
      expect(face(tester), SaveProgressFace.enterEmail);
      expect(find.text(SaveProgressCard.noAccount), findsOneWidget);
      await tapText(tester, SaveProgressCard.toLink);
      expect(find.text(SaveProgressCard.linkLine), findsOneWidget);
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

  testWidgets('2x text and reduced motion: the link-sent step still fits', (
    tester,
  ) async {
    await pump(tester, textScale: 2, reduceMotion: true);
    await toLinkSent(tester);
    expect(face(tester), SaveProgressFace.linkSent);
    expect(tester.takeException(), isNull);
    await drain(tester);
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
