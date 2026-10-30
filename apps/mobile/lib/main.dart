import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/audio/audio_providers.dart';
import 'core/audio/game_sounds.dart';
import 'core/db/app_database.dart';
import 'core/env/env.dart';
import 'core/logging/log.dart';
import 'core/profile/drift_profile_repository.dart';
import 'core/profile/profile_repository.dart';
import 'core/progress/drift_progress_repository.dart';
import 'core/progress/progress_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final env = Env.fromDefines();
  final log = Log(minLevel: env.isProd ? LogLevel.info : LogLevel.debug);

  // Unexpected errors go to the log now and to Sentry once it's wired (docs/rules/error-handling.md).
  FlutterError.onError = (details) {
    log.error(
      'flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.error('uncaught error', error: error, stackTrace: stack);
    return true;
  };

  log.info('app started', {'env': env.appEnv, 'supabase': env.hasSupabase});

  // Progress and the profile live on the device first (ADR 0002), with or without a backend.
  final db = AppDatabase.onDevice();
  final container = ProviderContainer(
    overrides: [
      envProvider.overrideWithValue(env),
      logProvider.overrideWithValue(log),
      databaseProvider.overrideWithValue(db),
      progressRepositoryProvider.overrideWith(
        (ref) => DriftProgressRepository(
          db,
          log: log,
          signal: ref.watch(outboxSignalProvider),
        ),
      ),
      profileRepositoryProvider.overrideWith(
        (ref) => DriftProfileRepository(
          db,
          legacy: LocalProfileRepository(),
          signal: ref.watch(outboxSignalProvider),
        ),
      ),
      gameSoundsProvider.overrideWith(
        (ref) => ref.watch(audioGameSoundsProvider),
      ),
    ],
  );
  startBackendAfterFirstFrame(container);
  startSync(container);
  startAudio(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TheLastRoomApp(),
    ),
  );
}

/// The backend is optional (ADR 0005): the guest sign-in starts only once the first frame is on
/// screen, runs in the background, and is never awaited. With no keys it does nothing.
void startBackendAfterFirstFrame(ProviderContainer container) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(container.read(sessionProvider.notifier).start());
  });
}

/// Keeps the sync worker alive: it exists only once a guest is signed in (never with no keys),
/// and sends again whenever the app comes back to the foreground (the usual "reconnected").
void startSync(ProviderContainer container) {
  container.listen(syncWorkerProvider, (_, _) {});
  AppLifecycleListener(
    onResume: () => unawaited(container.read(syncWorkerProvider)?.flush()),
  );
}
