import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';
import '../logging/log.dart';
import 'backend.dart';

/// [Backend] on Supabase. The only file in the app that imports `supabase_flutter`.
///
/// Constructing it does nothing: the client is initialised on the first call, so an app without
/// keys never initialises Supabase (the caller checks [Env.hasSupabase] before calling).
class SupabaseBackend implements Backend {
  SupabaseBackend(this._env, this._log);

  final Env _env;
  final Log _log;
  Future<SupabaseClient>? _supabase;
  StreamSubscription<AuthState>? _authEvents;

  static const String _attempts = 'mission_attempts';
  static const String _profiles = 'profiles';
  static const String _scoreFunction = 'score';
  static const String _scoreVoiceFunction = 'score-voice';
  static const String _aiScores = 'ai_scores';
  static const String _leaderboardFunction = 'leaderboard';

  /// Where "Save your progress"'s confirmation link lands: the landing site's "You're verified"
  /// page (web/src/app/verified). It must be in the project's Redirect URLs (status 67).
  static const String verifiedPage =
      'https://thelastroom-ten.vercel.app/verified';

  /// Where a sign-in link lands: back in the app (AndroidManifest intent filter, iOS URL type).
  static const String appCallback = 'thelastroom://auth-callback';

  /// Auth errors on the state stream that are a session's, not a sign-in link's.
  static const Set<String> _sessionErrors = {
    'session_missing',
    'session_expired',
  };

  final StreamController<AccountLinkEvent> _links =
      StreamController<AccountLinkEvent>.broadcast();

  /// The user the last auth event was about: a sign-in to someone else is a sign-in link.
  String? _lastUserId;

  @override
  Future<BackendSession> restoreSession() async {
    final user = (await _client()).auth.currentUser;
    return user == null ? const NoSession() : _session(user);
  }

  /// The app's view of [user]: a guest, or a guest with its linked email (FR-3).
  static GuestSession _session(User user) =>
      GuestSession(userId: user.id, email: linkedEmail(user));

  /// The address [user] has saved to, or null. While the link waits to be tapped the address
  /// sits in `new_email` and `email` is empty; tapping it moves it to `email`, sets
  /// `email_confirmed_at`, and ends the anonymous status (gotrue's email-change verify).
  static String? linkedEmail(User user) {
    final email = user.email;
    if (email == null || email.isEmpty) return null;
    if (!user.isAnonymous) return email;
    final pending = (user.newEmail ?? '').isNotEmpty;
    return user.emailConfirmedAt != null && !pending ? email : null;
  }

  @override
  Future<GuestSession> signInAnonymously() async {
    final response = await (await _client()).auth.signInAnonymously();
    final user = response.user;
    if (user == null) {
      throw const BackendException('anonymous sign-in returned no user');
    }
    return GuestSession(userId: user.id);
  }

  @override
  Future<void> insertAttempts(List<RemoteAttempt> attempts) async {
    if (attempts.isEmpty) return;
    await (await _client())
        .from(_attempts)
        .upsert(
          [for (final a in attempts) a.toRow()],
          onConflict: 'attempt_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> upsertProfile(RemoteProfile profile) async {
    // user_id isn't sent: its default is auth.uid(), and the column grants don't let a client
    // write it (supabase/migrations).
    await (await _client())
        .from(_profiles)
        .upsert(profile.toRow(), onConflict: 'user_id');
  }

  @override
  Future<void> upsertLeaderboardReport(RemoteLeaderboardReport report) async {
    await (await _client())
        .from(_profiles)
        .upsert(report.toRow(), onConflict: 'user_id');
  }

  @override
  Future<List<RemoteLeaderboardRow>> fetchLeaderboard(
    LeaderboardScope scope, {
    int limit = leaderboardSize,
  }) async {
    final rows = await (await _client()).rpc<List<Object?>>(
      _leaderboardFunction,
      params: {'p_scope': scope.wireName, 'p_limit': limit},
    );
    return [for (final row in rows) ?RemoteLeaderboardRow.fromRow(row)];
  }

  @override
  Future<List<RemoteAttempt>> fetchAttempts() async {
    final rows = await (await _client())
        .from(_attempts)
        .select()
        .order('completed_at');
    // A row without its picks can't be rescored, so it isn't restored.
    return [for (final row in rows) ?RemoteAttempt.fromRow(row)];
  }

  @override
  Future<RemoteProfile?> fetchProfile() async {
    final row = await (await _client()).from(_profiles).select().maybeSingle();
    return row == null ? null : RemoteProfile.fromRow(row);
  }

  @override
  Future<Object?> scoreAnswer(Map<String, Object?> request) =>
      _invoke(_scoreFunction, request);

  @override
  Future<Object?> scoreVoiceAnswer(Map<String, Object?> request) =>
      _invoke(_scoreVoiceFunction, request);

  /// Calls the Edge Function [name]; an error status is a [ScoreRefused] with its code.
  Future<Object?> _invoke(String name, Map<String, Object?> request) async {
    // The session's JWT goes with the call (supabase-dart sets it); the function checks it.
    try {
      final response = await (await _client()).functions.invoke(
        name,
        body: request,
      );
      final Object? data = response.data;
      return data;
    } on FunctionException catch (error) {
      final Object? details = error.details;
      final code = details is Map<String, Object?> ? details['error'] : null;
      throw ScoreRefused(error.status, code is String ? code : null);
    }
  }

  @override
  Future<GuestSession?> sendLinkEmail(String email) => _account(() async {
    final auth = (await _client()).auth;
    final response = await auth.updateUser(
      UserAttributes(email: email),
      emailRedirectTo: verifiedPage,
    );
    final user = response.user;
    // With email confirmations off the server links at once; on, the link is on its way.
    return user != null && !user.isAnonymous && user.email == email
        ? _session(user)
        : null;
  });

  @override
  Future<GuestSession> refreshAccount() => _account(() async {
    final auth = (await _client()).auth;
    // The refresh gives a token minted after the link was tapped (its claims are the linked
    // user's); the user read is the server's word on the email.
    await auth.refreshSession();
    final user = (await auth.getUser()).user ?? auth.currentUser;
    if (user == null) {
      throw const AccountException(AccountFailure.unavailable, 'no_user');
    }
    return _session(user);
  });

  @override
  Future<void> sendSignInLink(String email) => _account(() async {
    // shouldCreateUser false: this path only finds a saved account, it never makes one. The
    // link comes back into the app (the intent filter / URL type for [appCallback]), where
    // supabase_flutter exchanges its PKCE code for the account's session.
    await (await _client()).auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: appCallback,
    );
  });

  @override
  Future<void> signOut() async {
    try {
      // gotrue drops the local session (and the PKCE verifier) first, then tells the server.
      await (await _client()).auth.signOut();
    } on AuthException catch (error) {
      // Offline, or the server refused the logout: this device is signed out all the same, and
      // the old refresh token simply expires.
      _log.warn('sign out not confirmed by the server', {
        'reason': error.code ?? error.statusCode,
      });
    }
  }

  @override
  Stream<AccountLinkEvent> get accountLinks => _links.stream;

  /// Runs an auth call, turning what the server says into an [AccountFailure].
  static Future<T> _account<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AuthRetryableFetchException catch (error) {
      // No network, or a 5xx gotrue retries itself: both read as "can't reach us" to a player.
      throw AccountException(AccountFailure.offline, error.statusCode);
    } on AuthException catch (error) {
      throw AccountException(_failure(error), error.code ?? error.statusCode);
    } on TimeoutException {
      throw const AccountException(AccountFailure.offline, 'timeout');
    }
  }

  /// The gotrue error codes probed against the local stack (status 60).
  static AccountFailure _failure(AuthException error) => switch (error.code) {
    'otp_expired' ||
    'flow_state_expired' ||
    'flow_state_not_found' => AccountFailure.linkExpired,
    'over_email_send_rate_limit' ||
    'over_request_rate_limit' => AccountFailure.rateLimited,
    'email_exists' || 'user_already_exists' => AccountFailure.emailTaken,
    'otp_disabled' ||
    'user_not_found' ||
    'signup_disabled' => AccountFailure.noAccount,
    'email_address_invalid' ||
    'validation_failed' => AccountFailure.invalidEmail,
    _ => switch (error.statusCode) {
      '429' => AccountFailure.rateLimited,
      _ => AccountFailure.unavailable,
    },
  };

  @override
  Future<List<Object?>> fetchAiScores() async {
    final rows = await (await _client())
        .from(_aiScores)
        .select(
          'mission_id, model, relevance_score, specificity_score, structure_score, '
          'adaptability_score, overall_score, basis, created_at',
        )
        .order('created_at');
    return [for (final row in rows) row];
  }

  Future<void> dispose() async {
    await _authEvents?.cancel();
    await _links.close();
  }

  Future<SupabaseClient> _client() => _supabase ??= _initialise();

  Future<SupabaseClient> _initialise() async {
    final Supabase supabase;
    try {
      supabase = await Supabase.initialize(
        url: _env.supabaseUrl,
        publishableKey: _env.supabaseAnonKey,
        // The SDK's own debug output would bypass the log wrapper (docs/rules/logging.md).
        debug: false,
      );
    } on Object {
      // Let the next attempt initialise again rather than replaying this failure for ever.
      _supabase = null;
      rethrow;
    }
    final auth = supabase.client.auth;
    _lastUserId = auth.currentUser?.id;
    _authEvents = auth.onAuthStateChange.listen(
      _onAuthState,
      onError: _onAuthError,
    );
    return supabase.client;
  }

  /// A sign-in link exchanged by supabase_flutter (`detectSessionInUri`, on by default) arrives
  /// as `signedIn` for a saved, non-anonymous user other than the one before. The guest's own
  /// sign-in is anonymous, and a refresh or a link keeps the id, so neither counts.
  void _onAuthState(AuthState state) {
    final user = state.session?.user;
    final before = _lastUserId;
    _lastUserId = user?.id;
    if (state.event != AuthChangeEvent.signedIn ||
        user == null ||
        user.isAnonymous ||
        user.id == before) {
      return;
    }
    final session = _session(user);
    if (!session.isLinked || _links.isClosed) return;
    _log.info('account link opened');
    _links.add(AccountLinkSignedIn(session, previousUserId: before));
  }

  /// Token refreshes fail while offline and arrive here as stream errors: expected, retried by
  /// the SDK, so a warning. Any other auth error is a sign-in link the server refused (the
  /// `#error=…` of an expired or used link, or a PKCE code this device can't exchange).
  void _onAuthError(Object error) {
    final reason = linkRefusal(error);
    if (reason != null) {
      _log.warn('account link refused', {'reason': reason});
      if (!_links.isClosed) _links.add(AccountLinkRefused(reason));
      return;
    }
    _log.warn('backend auth refresh failed', {'error': '$error'});
  }

  /// The server's code when [error], on the auth state stream, is a refused sign-in link, or
  /// null when it's a session's own trouble (an offline refresh, an expired session). The code
  /// only: the description is the server's prose. Supabase's error redirect puts `otp_expired`
  /// in `error_code`, which gotrue reads as the status code.
  static String? linkRefusal(Object error) {
    if (error is! AuthException ||
        error is AuthRetryableFetchException ||
        _sessionErrors.contains(error.code)) {
      return null;
    }
    return error.statusCode ?? error.code ?? 'unknown';
  }
}
