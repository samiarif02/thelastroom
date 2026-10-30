import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/backend/guest_sign_in.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/features/title/title_screen.dart';
import 'package:the_last_room/main.dart';

import 'fakes.dart';

void main() {
  late CapturedLog log;
  late RecordingAnalytics analytics;

  setUp(() {
    log = CapturedLog();
    analytics = RecordingAnalytics();
  });

  ProviderContainer containerWith(Env env, Backend Function() backend) {
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(env),
        logProvider.overrideWithValue(log.log),
        analyticsProvider.overrideWithValue(analytics),
        backendProvider.overrideWith((ref) => backend()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // Boots the app the way main() does: sign-in scheduled for after the first frame.
  Future<void> boot(WidgetTester tester, ProviderContainer container) async {
    startBackendAfterFirstFrame(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TheLastRoomApp(),
      ),
    );
  }

  testWidgets(
    'zero setup: an empty Env boots to the title and never builds the backend',
    (tester) async {
      final container = containerWith(
        emptyEnv,
        () => throw StateError('the backend was touched with no keys'),
      );
      await boot(tester, container);
      // The scene never settles (grain, lamp flicker and breathing run on an ambient clock),
      // so pump through the title card instead of pumpAndSettle.
      await tester.pump(BrandMotion.titleCard);

      expect(find.byType(TitleScreen), findsOneWidget);
      expect(container.read(sessionProvider), isA<NoSession>());
      expect(tester.takeException(), isNull);
      expect(log.at(LogLevel.warn), isEmpty);
    },
  );

  testWidgets('a backend that never answers does not delay the first frame', (
    tester,
  ) async {
    final backend = FakeBackend(
      restore: () => Completer<BackendSession>().future,
    );
    final container = containerWith(keyedEnv, () => backend);
    await boot(tester, container);

    expect(find.byType(TitleScreen), findsOneWidget);
    expect(
      backend.restoreCalls,
      1,
      reason: 'sign-in started after the first frame',
    );
    expect(container.read(sessionProvider), isA<NoSession>());

    // Let the hung attempt time out; no error reaches the player or the error log.
    await tester.pump(signInAttemptTimeout);
    expect(log.at(LogLevel.warn), hasLength(1));
    expect(log.at(LogLevel.error), isEmpty);
    expect(find.byType(TitleScreen), findsOneWidget);
    container.dispose();
    await tester.pump(maxSignInRetryDelay);
  });

  testWidgets(
    'a backend that throws does not delay the first frame or show an error',
    (tester) async {
      final backend = FakeBackend(
        restore: () async => throw const BackendException('down'),
      );
      final container = containerWith(keyedEnv, () => backend);
      await boot(tester, container);

      expect(find.byType(TitleScreen), findsOneWidget);
      await tester.pump();
      expect(log.at(LogLevel.warn), hasLength(1));
      expect(tester.takeException(), isNull);
      container.dispose();
      await tester.pump(maxSignInRetryDelay);
    },
  );

  testWidgets(
    'with keys, the guest session reaches the provider and guest_started fires once',
    (tester) async {
      final container = containerWith(keyedEnv, FakeBackend.new);
      await boot(tester, container);
      await tester.pump();
      await container.read(sessionProvider.notifier).start();

      expect(
        container.read(sessionProvider),
        const GuestSession(userId: FakeBackend.guestId),
      );
      expect(analytics.events, hasLength(1));
    },
  );
}
