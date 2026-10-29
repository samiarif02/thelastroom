import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/log.dart';

/// An env with the backend switched on. The URL is never contacted: tests use [FakeBackend].
const Env keyedEnv = Env(
  appEnv: 'dev',
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseAnonKey: 'test-anon-key',
  sentryDsn: '',
  posthogApiKey: '',
  posthogHost: '',
);

/// Every value blank: the zero-setup env (ADR 0005).
const Env emptyEnv = Env(
  appEnv: 'dev',
  supabaseUrl: '',
  supabaseAnonKey: '',
  sentryDsn: '',
  posthogApiKey: '',
  posthogHost: '',
);

/// A [Backend] whose answers each test scripts. The defaults are a first launch that works.
class FakeBackend implements Backend {
  FakeBackend({
    Future<BackendSession> Function()? restore,
    Future<GuestSession> Function()? signIn,
  }) : _restore = restore ?? (() async => const NoSession()),
       _signIn = signIn ?? (() async => const GuestSession(userId: guestId));

  static const String guestId = '00000000-0000-4000-8000-000000000001';

  final Future<BackendSession> Function() _restore;
  final Future<GuestSession> Function() _signIn;
  int restoreCalls = 0;
  int signInCalls = 0;

  int get calls => restoreCalls + signInCalls;

  @override
  Future<BackendSession> restoreSession() {
    restoreCalls++;
    return _restore();
  }

  @override
  Future<GuestSession> signInAnonymously() {
    signInCalls++;
    return _signIn();
  }
}

class RecordingAnalytics implements Analytics {
  final List<AnalyticsEvent> events = [];

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) =>
      events.add(event);
}

/// A [Log] that keeps its records, at every level.
class CapturedLog {
  final List<LogRecord> records = [];
  late final Log log = Log(minLevel: LogLevel.debug, sink: records.add);

  List<LogRecord> at(LogLevel level) =>
      records.where((r) => r.level == level).toList();
}
