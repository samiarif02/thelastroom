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

  @override
  Future<BackendSession> restoreSession() async {
    final user = (await _client()).auth.currentUser;
    return user == null ? const NoSession() : GuestSession(userId: user.id);
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
