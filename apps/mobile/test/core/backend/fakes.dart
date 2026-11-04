import 'dart:async';

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
  FakeBackend({Future<BackendSession> Function()? restore, this._signIn})
    : _restore = restore ?? (() async => const NoSession());

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

  /// The server's `ai_scores` rows.
  final List<Map<String, Object?>> aiScores = [];

  @override
  Future<List<Object?>> fetchAiScores() async {
    _network();
    return [...aiScores];
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

  /// What `score-voice` answers; null: the function isn't configured (503).
  Future<Object?> Function(Map<String, Object?> request)? voiceScorer;
  final List<Map<String, Object?>> voiceScoreRequests = [];

  @override
  Future<Object?> scoreVoiceAnswer(Map<String, Object?> request) async {
    _network();
    voiceScoreRequests.add(request);
    final scorer = voiceScorer;
    if (scorer == null) throw const ScoreRefused(503, 'not_configured');
    return scorer(request);
  }

  static const String guestId = '00000000-0000-4000-8000-000000000001';

  /// The saved account a "Sign in on another device" lands in (FR-3).
  static const String accountId = '00000000-0000-4000-8000-0000000000a1';

  /// The fake auth server: which addresses hold a saved account, and the user id behind each.
  final Map<String, String> accounts = {};

  /// The guest this fake device is signed in as; linking keeps this id.
  String currentUserId = guestId;

  /// The address a "Save your progress" link was mailed to, until [tapLink].
  String? pendingEmail;

  /// The address this device's user has confirmed (the server's `email`).
  String? confirmedEmail;

  /// A failure the next auth call throws (then it's cleared), to script every card state.
  AccountFailure? nextAuthFailure;

  /// Links at once, with no email (a server with email confirmations off).
  bool linksAtOnce = false;

  /// Every auth call, by name, for assertions.
  final List<String> authCalls = [];

  /// Holds each auth call until completed, to see the sending state.
  Completer<void>? authGate;

  Future<void> _auth(String call) async {
    authCalls.add(call);
    final gate = authGate;
    if (gate != null) await gate.future;
    final failure = nextAuthFailure;
    if (failure != null) {
      nextAuthFailure = null;
      throw AccountException(failure, 'scripted');
    }
  }

  @override
  Future<GuestSession?> sendLinkEmail(String email) async {
    await _auth('sendLinkEmail');
    if (accounts.containsKey(email)) {
      throw const AccountException(AccountFailure.emailTaken, 'email_exists');
    }
    if (linksAtOnce) {
      accounts[email] = currentUserId;
      confirmedEmail = email;
      return GuestSession(userId: currentUserId, email: email);
    }
    pendingEmail = email;
    return null;
  }

  /// The player taps the "Save your progress" link in their email (on any device).
  void tapLink() {
    final email = pendingEmail!;
    pendingEmail = null;
    accounts[email] = currentUserId;
    confirmedEmail = email;
  }

  @override
  Future<GuestSession> refreshAccount() async {
    await _auth('refreshAccount');
    return GuestSession(userId: currentUserId, email: confirmedEmail);
  }

  @override
  Future<void> sendSignInLink(String email) async {
    await _auth('sendSignInLink');
    if (!accounts.containsKey(email)) {
      throw const AccountException(AccountFailure.noAccount, 'otp_disabled');
    }
  }

  final StreamController<AccountLinkEvent> _links =
      StreamController<AccountLinkEvent>.broadcast(sync: true);

  @override
  Stream<AccountLinkEvent> get accountLinks => _links.stream;

  /// The sign-in link for [email] opens this app: the client is the account from now on.
  void openSignInLink(String email) {
    final before = currentUserId;
    currentUserId = accounts[email]!;
    confirmedEmail = email;
    _links.add(
      AccountLinkSignedIn(
        GuestSession(userId: currentUserId, email: email),
        previousUserId: before,
      ),
    );
  }

  /// The new guest a "Sign out" leaves this device as.
  static const String nextGuestId = '00000000-0000-4000-8000-000000000002';

  int signOuts = 0;

  @override
  Future<void> signOut() async {
    await _auth('signOut');
    signOuts++;
    currentUserId = nextGuestId;
    confirmedEmail = null;
  }

  /// An expired or already used sign-in link opens this app (`#error=access_denied…`).
  void openRefusedLink() => _links.add(const AccountLinkRefused('otp_expired'));

  final Future<BackendSession> Function() _restore;

  /// Null: a new anonymous user, the id this device is on now (a new one after [signOut]).
  final Future<GuestSession> Function()? _signIn;
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
    final signIn = _signIn;
    return signIn == null
        ? Future.value(GuestSession(userId: currentUserId))
        : signIn();
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
