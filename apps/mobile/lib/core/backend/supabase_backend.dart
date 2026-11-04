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

  @override
  Future<BackendSession> restoreSession() async {
    final user = (await _client()).auth.currentUser;
    return user == null ? const NoSession() : _session(user);
  }

  /// The app's view of [user]: a guest, or a guest with its linked email (FR-3).
  static GuestSession _session(User user) {
    final email = user.email;
    final linked = !user.isAnonymous && email != null && email.isNotEmpty;
    return GuestSession(userId: user.id, email: linked ? email : null);
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
  Future<GuestSession?> sendLinkCode(String email) => _account(() async {
    final auth = (await _client()).auth;
    final response = await auth.updateUser(UserAttributes(email: email));
    final user = response.user;
    // With email confirmations off the server links at once; on, the code is on its way.
    return user != null && !user.isAnonymous && user.email == email
        ? _session(user)
        : null;
  });

  @override
  Future<GuestSession> confirmLinkCode({
    required String email,
    required String code,
  }) => _verify(email, code, OtpType.emailChange);

  @override
  Future<void> sendSignInCode(String email) => _account(() async {
    // shouldCreateUser false: this path only finds a saved account, it never makes one.
    await (await _client()).auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  });

  @override
  Future<GuestSession> confirmSignInCode({
    required String email,
    required String code,
  }) => _verify(email, code, OtpType.email);

  Future<GuestSession> _verify(String email, String code, OtpType type) =>
      _account(() async {
        final auth = (await _client()).auth;
        final response = await auth.verifyOTP(
          email: email,
          token: code,
          type: type,
        );
        final user = response.user ?? auth.currentUser;
        if (user == null) {
          throw const AccountException(AccountFailure.unavailable, 'no_user');
        }
        return _session(user);
      });

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
    'otp_expired' || 'invalid_credentials' => AccountFailure.wrongCode,
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
      '403' => AccountFailure.wrongCode,
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

  Future<void> dispose() async => _authEvents?.cancel();

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
    // Token refreshes fail while offline and arrive here as stream errors. They are expected
    // and retried by the SDK, so they are a warning, not an uncaught error.
    _authEvents = auth.onAuthStateChange.listen(
      (_) {},
      onError: (Object error) =>
          _log.warn('backend auth refresh failed', {'error': '$error'}),
    );
    return supabase.client;
  }
}
