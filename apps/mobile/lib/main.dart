import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/audio/audio_providers.dart';
import 'core/audio/game_sounds.dart';
import 'core/env/env.dart';
import 'core/logging/log.dart';

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

  final container = ProviderContainer(
    overrides: [
      envProvider.overrideWithValue(env),
      logProvider.overrideWithValue(log),
      gameSoundsProvider.overrideWith(
        (ref) => ref.watch(audioGameSoundsProvider),
      ),
    ],
  );
  startBackendAfterFirstFrame(container);
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
