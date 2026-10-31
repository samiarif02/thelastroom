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
/// Its tables behave like the server's: attempts are insert-or-skip on `attempt_id`, the
/// profile is one row. [online] false makes every data call fail, like a dropped network.
class FakeBackend implements Backend {
  FakeBackend({
    Future<BackendSession> Function()? restore,
    Future<GuestSession> Function()? signIn,
  }) : _restore = restore ?? (() async => const NoSession()),
       _signIn = signIn ?? (() async => const GuestSession(userId: guestId));

  /// The server's `mission_attempts`, by `attempt_id`.
  final Map<String, RemoteAttempt> attempts = {};
  RemoteProfile? profile;
  bool online = true;

  /// Each `insertAttempts` call's batch size.
  final List<int> attemptBatches = [];
  int profileUpserts = 0;
  int fetches = 0;

  void _network() {
    if (!online) throw const BackendException('offline');
  }

  @override
  Future<void> insertAttempts(List<RemoteAttempt> batch) async {
    _network();
    attemptBatches.add(batch.length);
    for (final a in batch) {
      attempts.putIfAbsent(a.attemptId, () => a);
    }
  }

  @override
  Future<void> upsertProfile(RemoteProfile p) async {
    _network();
    profileUpserts++;
    profile = p;
  }

  @override
  Future<List<RemoteAttempt>> fetchAttempts() async {
    _network();
    fetches++;
    return attempts.values.toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }

  @override
  Future<RemoteProfile?> fetchProfile() async {
    _network();
    return profile;
  }

  /// What the `score` function answers; null means it's never been set up (503).
  Future<Object?> Function(Map<String, Object?> request)? scorer;

  /// Every request the app sent to `score`.
  final List<Map<String, Object?>> scoreRequests = [];

  @override
  Future<Object?> scoreAnswer(Map<String, Object?> request) async {
    _network();
    scoreRequests.add(request);
    final scorer = this.scorer;
    if (scorer == null) throw const ScoreRefused(503, 'not_configured');
    return scorer(request);
  }

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
