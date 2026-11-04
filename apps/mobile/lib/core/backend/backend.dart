/// The app's view of the optional backend (ADR 0005). Feature code depends on these types,
/// never on `supabase_flutter`: only [SupabaseBackend](supabase_backend.dart) imports it, so tests
/// swap in a fake and the game never needs the backend to run.
library;

import 'remote_rows.dart';

export 'remote_rows.dart';

/// Who the player is to the backend. Every player starts as a silent guest (FR-2); "Save your
/// progress" (FR-3) links an email to that same guest, so the id never changes.
sealed class BackendSession {
  const BackendSession();
}

/// No backend session: no keys, not signed in yet, or offline since first launch.
class NoSession extends BackendSession {
  const NoSession();
}

/// A signed-in Supabase user: anonymous from the first launch, and with [email] once the player
/// has saved their progress (FR-3). Linking keeps [userId], so every synced row and the
/// owner-only RLS policies stay valid with no data migration.
class GuestSession extends BackendSession {
  const GuestSession({required this.userId, this.email});

  /// The `auth.users` id the owner-only RLS policies check. Never logged or tracked.
  final String userId;

  /// The linked address, or null for an anonymous guest. Shown to the player in Settings, and
  /// never logged or tracked (the logger redacts it as well).
  final String? email;

  /// The player has saved their progress to an email.
  bool get isLinked => email != null;

  @override
  bool operator ==(Object other) =>
      other is GuestSession && other.userId == userId && other.email == email;

  @override
  int get hashCode => Object.hash(userId, email);
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

  /// Asks the `score-voice` function (brief 35) to transcribe and grade a spoken answer, as the
  /// signed-in player. [request] carries the recordings (base64 WAV), which the function sends
  /// to the model and never stores. Throws [ScoreRefused] like [scoreAnswer].
  Future<Object?> scoreVoiceAnswer(Map<String, Object?> request);

  /// "Save your progress" (FR-3): asks the server to link [email] to the signed-in guest, which
  /// mails a confirmation link to it (Supabase's default email). Returns null when the link is
  /// on its way, or the linked session when the server links at once (a project with email
  /// confirmations off). Throws [AccountException].
  Future<GuestSession?> sendLinkEmail(String email);

  /// Re-reads the signed-in user from the server (a token refresh, then the user): the same id,
  /// with its email once the player has tapped the link ([GuestSession.isLinked]). Throws
  /// [AccountException].
  Future<GuestSession> refreshAccount();

  /// "Sign in on another device": mails a sign-in link to an address that's already saved. The
  /// link opens the app ([accountLinks] then reports the sign-in). Never creates an account
  /// ([AccountFailure.noAccount]). Throws [AccountException].
  Future<void> sendSignInLink(String email);

  /// What the sign-in links opened on this device did: the account signed in, or the link was
  /// refused (expired or already used). Broadcast; nothing is replayed.
  Stream<AccountLinkEvent> get accountLinks;

  /// The signed-in player's AI verdicts (`ai_scores` rows, oldest first), for "Your file" on a
  /// fresh install. Raw rows: the caller parses them.
  Future<List<Object?>> fetchAiScores();
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

/// Why an account step didn't work. Every one has its own designed state on the card.
enum AccountFailure {
  /// Not an email address (checked on the device, before anything is sent).
  invalidEmail,

  /// The emailed link has expired or was already used (or was opened on another device).
  linkExpired,

  /// Too many emails asked for in a short time: wait a minute.
  rateLimited,

  /// "Save your progress" with an address another account already holds.
  emailTaken,

  /// "Sign in on another device" with an address nobody has saved to.
  noAccount,

  /// No network, or the server didn't answer in time.
  offline,

  /// The server answered with something else (a 5xx, an unexpected refusal).
  unavailable,
}

/// An account step (FR-3) failed in a way the card shows. The server's own message is never
/// shown to the player, and [reason] carries no email.
class AccountException implements Exception {
  const AccountException(this.failure, [this.reason]);

  final AccountFailure failure;

  /// The server's error code, for the log (e.g. `otp_expired`).
  final String? reason;

  @override
  String toString() => 'AccountException(${failure.name}, $reason)';
}

/// A sign-in link (FR-3) opened in the app.
sealed class AccountLinkEvent {
  const AccountLinkEvent();
}

/// The link signed this device in to [session], a saved account. [previousUserId] is the guest
/// this device was before (null on a device that had none), so the caller readies the merge.
class AccountLinkSignedIn extends AccountLinkEvent {
  const AccountLinkSignedIn(this.session, {this.previousUserId});

  final GuestSession session;
  final String? previousUserId;
}

/// The link didn't sign in: it expired, was used already, or was asked for on another device.
/// [reason] is the server's error code, for the log; it never holds an email.
class AccountLinkRefused extends AccountLinkEvent {
  const AccountLinkRefused([this.reason]);

  final String? reason;
}
