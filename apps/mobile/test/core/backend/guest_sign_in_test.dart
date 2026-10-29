import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/backend/guest_sign_in.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/log.dart';

import 'fakes.dart';

void main() {
  late RecordingAnalytics analytics;
  late CapturedLog log;
  late List<BackendSession> sessions;

  setUp(() {
    analytics = RecordingAnalytics();
    log = CapturedLog();
    sessions = [];
  });

  GuestSignIn signIn(Env env, Backend Function() backend) => GuestSignIn(
    env: env,
    backend: backend,
    analytics: analytics,
    log: log.log,
    onSession: sessions.add,
  );

  test(
    'an empty Env never touches the backend, not even to construct it',
    () async {
      var constructed = false;
      await signIn(emptyEnv, () {
        constructed = true;
        return FakeBackend();
      }).run();

      expect(constructed, isFalse);
      expect(sessions, isEmpty);
      expect(analytics.events, isEmpty);
      expect(log.at(LogLevel.warn), isEmpty);
    },
  );

  test(
    'a first launch signs in as a guest and fires guest_started once',
    () async {
      final backend = FakeBackend();
      final run = signIn(keyedEnv, () => backend);
      await Future.wait([run.run(), run.run()]);
      await run.run();

      expect(sessions, [const GuestSession(userId: FakeBackend.guestId)]);
      expect(analytics.events, [AnalyticsEvent.guestStarted]);
      expect(backend.signInCalls, 1);
    },
  );

  test(
    'a restored session is not a new guest: no sign-in, no guest_started',
    () async {
      final backend = FakeBackend(
        restore: () async => const GuestSession(userId: FakeBackend.guestId),
      );
      await signIn(keyedEnv, () => backend).run();

      expect(sessions, [const GuestSession(userId: FakeBackend.guestId)]);
      expect(backend.signInCalls, 0);
      expect(analytics.events, isEmpty);
    },
  );

  test('offline: each failure is a warn and a retry with backoff, then success fires once', () {
    fakeAsync((async) {
      var failures = 2;
      final backend = FakeBackend(
        signIn: () async {
          if (failures-- > 0) throw const BackendException('offline');
          return const GuestSession(userId: FakeBackend.guestId);
        },
      );
      unawaited(signIn(keyedEnv, () => backend).run());

      async.flushMicrotasks();
      expect(log.at(LogLevel.warn), hasLength(1));
      expect(
        log.at(LogLevel.warn).single.fields,
        containsPair('retry_in_s', 2),
      );
      expect(sessions, isEmpty);

      async.elapse(const Duration(seconds: 2));
      expect(log.at(LogLevel.warn), hasLength(2));
      expect(log.at(LogLevel.warn).last.fields, containsPair('retry_in_s', 4));

      async.elapse(const Duration(seconds: 4));
      expect(sessions, [const GuestSession(userId: FakeBackend.guestId)]);
      expect(analytics.events, [AnalyticsEvent.guestStarted]);
      expect(log.at(LogLevel.error), isEmpty);
    });
  });

  test('a backend that never answers times out and is retried', () {
    fakeAsync((async) {
      final backend = FakeBackend(
        restore: () => Completer<BackendSession>().future,
      );
      unawaited(signIn(keyedEnv, () => backend).run());

      async.elapse(signInAttemptTimeout);
      expect(log.at(LogLevel.warn), hasLength(1));
      async.elapse(signInRetryDelay(1));
      expect(backend.restoreCalls, 2);
    });
  });

  test('cancel stops the retries and drops a late result', () {
    fakeAsync((async) {
      final answer = Completer<BackendSession>();
      final backend = FakeBackend(restore: () => answer.future);
      final run = signIn(keyedEnv, () => backend);
      unawaited(run.run());

      run.cancel();
      answer.complete(const GuestSession(userId: FakeBackend.guestId));
      async.elapse(maxSignInRetryDelay * 2);

      expect(sessions, isEmpty);
      expect(backend.restoreCalls, 1);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('backoff doubles from 2 s and stops growing at 5 minutes', () {
    expect(
      [for (var n = 1; n <= 10; n++) signInRetryDelay(n).inSeconds],
      [2, 4, 8, 16, 32, 64, 128, 256, 300, 300],
    );
  });
}
