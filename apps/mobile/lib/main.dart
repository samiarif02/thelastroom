import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
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

  runApp(
    ProviderScope(
      overrides: [
        envProvider.overrideWithValue(env),
        logProvider.overrideWithValue(log),
      ],
      child: const TheLastRoomApp(),
    ),
  );
}
