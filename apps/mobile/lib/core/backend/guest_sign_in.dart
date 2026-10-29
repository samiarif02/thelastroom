import 'dart:async';
import 'dart:math' as math;

import '../analytics/analytics.dart';
import '../analytics/analytics_event.dart';
import '../env/env.dart';
import '../logging/log.dart';
import 'backend.dart';

/// How long one sign-in attempt may take before it counts as failed and is retried.
const Duration signInAttemptTimeout = Duration(seconds: 15);

/// The wait before the first retry; it doubles each time, up to [maxSignInRetryDelay].
const Duration firstSignInRetryDelay = Duration(seconds: 2);

/// The longest wait between retries. With Supabase's 30 anonymous sign-ins per hour per IP,
/// a device stuck retrying stays well inside the limit.
const Duration maxSignInRetryDelay = Duration(minutes: 5);

/// Exponential backoff: 2 s, 4 s, 8 s … capped at [maxSignInRetryDelay].
Duration signInRetryDelay(int failedAttempts) {
  final seconds =
      firstSignInRetryDelay.inSeconds * math.pow(2, failedAttempts - 1);
  return Duration(
    seconds: math.min(seconds, maxSignInRetryDelay.inSeconds).toInt(),
  );
}

/// Signs the player in as a guest in the background (FR-2), when the backend is configured.
///
/// The backend is optional (ADR 0005): with no keys nothing happens at all; with keys but no
/// network every failure is a `warn` and a retry with backoff. Nothing here is ever awaited by
/// the UI, and nothing is shown to the player.
class GuestSignIn {
  GuestSignIn({
    required this._env,
    required this._backend,
    required this._analytics,
    required this._log,
    required this._onSession,
    this._attemptTimeout = signInAttemptTimeout,
    this._retryDelay = signInRetryDelay,
  });

  final Env _env;
  final Backend Function() _backend;
  final Analytics _analytics;
  final Log _log;
  final void Function(BackendSession session) _onSession;
  final Duration _attemptTimeout;
  final Duration Function(int failedAttempts) _retryDelay;

  Future<void>? _run;
  bool _cancelled = false;

  /// Starts signing in. Calling it again returns the same run, so the guest starts once.
  Future<void> run() => _run ??= _signIn();

  /// Stops retrying. An attempt already in flight finishes, but its result is dropped.
  void cancel() => _cancelled = true;

  Future<void> _signIn() async {
    if (!_env.hasSupabase) return;
    final backend = _backend();
    for (var failed = 0; !_cancelled; failed++) {
      try {
        final restored = await backend.restoreSession().timeout(
          _attemptTimeout,
        );
        if (_cancelled) return;
        if (restored is GuestSession) {
          _onSession(restored);
          _log.info('guest session restored');
          return;
        }
        final guest = await backend.signInAnonymously().timeout(
          _attemptTimeout,
        );
        if (_cancelled) return;
        _onSession(guest);
        _analytics.track(AnalyticsEvent.guestStarted);
        _log.info('guest started');
        return;
      } on Object catch (error) {
        // A background guard: whatever the backend throws (offline, a timeout, a 5xx, a plugin
        // error), the game carries on and the next attempt tries again.
        if (_cancelled) return;
        final delay = _retryDelay(failed + 1);
        _log.warn('backend sign-in failed', {
          'attempt': failed + 1,
          'retry_in_s': delay.inSeconds,
          'error': '$error',
        });
        await Future<void>.delayed(delay);
      }
    }
  }
}
