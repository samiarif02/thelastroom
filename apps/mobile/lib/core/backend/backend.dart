/// The app's view of the optional backend (ADR 0005). Feature code depends on these types,
/// never on `supabase_flutter`: only [SupabaseBackend](supabase_backend.dart) imports it, so tests
/// swap in a fake and the game never needs the backend to run.
library;

import 'remote_rows.dart';

export 'remote_rows.dart';

/// Who the player is to the backend. There's no sign-up in v1 (owner, 2026-10-30): the silent
/// guest is the only account.
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

  /// Sends [attempts]; one already on the server (same `attempt_id`) is skipped, never updated
  /// (insert on conflict do nothing), so a retried batch is safe.
  Future<void> insertAttempts(List<RemoteAttempt> attempts);

  /// Creates or replaces the signed-in player's profile row.
  Future<void> upsertProfile(RemoteProfile profile);

  /// Every attempt of the signed-in player, oldest first (the restore on a fresh install).
  Future<List<RemoteAttempt>> fetchAttempts();

  /// The signed-in player's profile, or null if they've never synced one.
  Future<RemoteProfile?> fetchProfile();

  /// Asks the `score` Edge Function (brief 22) to grade an answer, as the signed-in player.
  /// [request] is the function's JSON body; the result is its decoded JSON, which the caller
  /// parses. Throws [ScoreRefused] when the function answers with an error status.
  Future<Object?> scoreAnswer(Map<String, Object?> request);
}

/// The `score` function answered with an error status ([status]) and code ([code]): a spent daily
/// quota (429), a missing key (503), an upstream failure (502/504). The caller falls back.
class ScoreRefused implements Exception {
  const ScoreRefused(this.status, [this.code]);

  final int status;
  final String? code;

  @override
  String toString() => 'ScoreRefused($status, $code)';
}

/// The backend answered, but not with what the app needs.
class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => 'BackendException: $message';
}
