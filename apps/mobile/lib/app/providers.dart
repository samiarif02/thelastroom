import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics.dart';
import '../core/backend/backend.dart';
import '../core/backend/guest_sign_in.dart';
import '../core/backend/supabase_backend.dart';
import '../core/env/env.dart';
import '../core/logging/log.dart';

/// App-wide services. Overridden in `main.dart` (real values) and in tests (fakes), so nothing
/// below the root constructs its own.
final envProvider = Provider<Env>((ref) => Env.fromDefines());

final logProvider = Provider<Log>((ref) => Log());

final analyticsProvider = Provider<Analytics>(
  (ref) => LogAnalytics(ref.watch(logProvider)),
);

/// The optional backend (ADR 0005). Only [sessionProvider] reads it, and only when
/// [Env.hasSupabase]; constructing it initialises nothing.
final backendProvider = Provider<Backend>((ref) {
  final backend = SupabaseBackend(
    ref.watch(envProvider),
    ref.watch(logProvider),
  );
  ref.onDispose(() => unawaited(backend.dispose()));
  return backend;
});

/// The player's backend session: [NoSession] until the background guest sign-in succeeds, and
/// for ever when the backend is off. Account linking and sync (brief 08) read it.
final sessionProvider = NotifierProvider<SessionNotifier, BackendSession>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<BackendSession> {
  GuestSignIn? _signIn;

  @override
  BackendSession build() {
    ref.onDispose(() => _signIn?.cancel());
    return const NoSession();
  }

  /// Starts the background guest sign-in. Called once after the first frame (`main.dart`);
  /// never awaited by the UI. Calling it again is a no-op.
  Future<void> start() {
    final signIn = _signIn ??= GuestSignIn(
      env: ref.read(envProvider),
      backend: () => ref.read(backendProvider),
      analytics: ref.read(analyticsProvider),
      log: ref.read(logProvider),
      onSession: (session) => state = session,
    );
    return signIn.run();
  }
}
