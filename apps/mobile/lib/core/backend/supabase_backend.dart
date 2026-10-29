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
  Future<GoTrueClient>? _auth;
  StreamSubscription<AuthState>? _authEvents;

  @override
  Future<BackendSession> restoreSession() async {
    final user = (await _client()).currentUser;
    return user == null ? const NoSession() : GuestSession(userId: user.id);
  }

  @override
  Future<GuestSession> signInAnonymously() async {
    final response = await (await _client()).signInAnonymously();
    final user = response.user;
    if (user == null) {
      throw const BackendException('anonymous sign-in returned no user');
    }
    return GuestSession(userId: user.id);
  }

  Future<void> dispose() async => _authEvents?.cancel();

  Future<GoTrueClient> _client() => _auth ??= _initialise();

  Future<GoTrueClient> _initialise() async {
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
      _auth = null;
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
    return auth;
  }
}
