import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'audio_engine.dart';
import 'audio_focus.dart';
import 'audio_game_sounds.dart';
import 'audio_service.dart';
import 'audio_settings.dart';
import 'game_sounds.dart';
import 'soloud_audio_engine.dart';
import 'typing_voice.dart';

final audioEngineProvider = Provider<AudioEngine>((ref) => SoloudAudioEngine());

/// The game's sound. Follows [audioSettingsProvider]; silent until [startAudio] runs.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(
    engine: ref.watch(audioEngineProvider),
    log: ref.watch(logProvider),
  );
  ref
    ..listen(
      audioSettingsProvider,
      (_, next) => service.applySettings(next),
      fireImmediately: true,
    )
    ..onDispose(service.stopAll);
  return service;
});

/// The real [GameSounds]. `main.dart` points [gameSoundsProvider] at it; tests keep the silent
/// default.
final audioGameSoundsProvider = Provider<GameSounds>((ref) {
  final clock = Stopwatch()..start();
  return AudioGameSounds(
    audio: ref.watch(audioServiceProvider),
    ticker: TypingTicker(random: Random(), now: () => clock.elapsed),
  );
});

/// Starts sound without holding up the first frame, and follows the app's lifecycle. On the
/// web the browser refuses audio until the player interacts, so it waits for the first tap
/// (until then the game is silent, with no error and no network request).
void startAudio(ProviderContainer container, {bool waitForTap = kIsWeb}) {
  final audio = container.read(audioServiceProvider);
  final log = container.read(logProvider);
  // The session is set before the engine opens the device (iOS needs its category first).
  // The web has no session to configure.
  Future<void> start() async {
    if (!kIsWeb) await followAudioFocus(audio, log);
    await audio.preload();
  }

  void preload() => unawaited(start());
  if (waitForTap) {
    _onFirstPointerDown(preload);
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) => preload());
  }
  // Lives as long as the app; a hidden app (background, another app on top) goes quiet.
  AppLifecycleListener(onHide: audio.suspend, onShow: audio.resume);
}

void _onFirstPointerDown(VoidCallback callback) {
  final router = GestureBinding.instance.pointerRouter;
  void route(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    router.removeGlobalRoute(route);
    callback();
  }

  router.addGlobalRoute(route);
}
