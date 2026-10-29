/// The app's view of the optional backend (ADR 0005). Feature code depends on these types,
/// never on `supabase_flutter`: only [SupabaseBackend](supabase_backend.dart) imports it, so tests
/// swap in a fake and the game never needs the backend to run.
library;

/// Who the player is to the backend. Linking email or Google (brief 08) adds a linked state.
sealed class BackendSession {
  const BackendSession();
}

/// No backend session: no keys, not signed in yet, or offline since first launch.
class NoSession extends BackendSession {
  const NoSession();
}

/// An anonymous Supabase user: a real user id from the first launch, before any account link.
class GuestSession extends BackendSession {
  const GuestSession({required this.userId});

  /// The `auth.users` id the owner-only RLS policies check. Never logged or tracked.
  final String userId;

  @override
  bool operator ==(Object other) =>
      other is GuestSession && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}

/// The backend calls the app makes. Every call may fail or hang (offline, backend down); callers
/// run them in the background and never await them from the UI.
abstract interface class Backend {
  /// The session saved on this device, if any. Never creates one.
  Future<BackendSession> restoreSession();

  /// Creates a new anonymous user and signs in as them.
  Future<GuestSession> signInAnonymously();
}

/// The backend answered, but not with what the app needs.
class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => 'BackendException: $message';
}
