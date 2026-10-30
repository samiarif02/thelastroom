import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_engine.dart';
import 'cue.dart';

/// [AudioEngine] on flutter_soloud. The only file that imports it.
///
/// - **Android:** `lowLatency: false` puts the game on the media stream (`mediaMusic`), so the
///   volume keys and screen recorders (scrcpy) treat it as media; the low-latency MMAP path is
///   invisible to recorders.
/// - **iOS:** SoLoud leaves `AVAudioSession` to the app. Its default category (`soloAmbient`)
///   already respects the silent switch.
/// - **Web:** the browser only lets audio start after a user gesture; `audio_providers.dart`
///   waits for the first tap before calling [start]. Assets load with [LoadMode.disk] there, as
///   flutter_soloud's docs ask.
class SoloudAudioEngine implements AudioEngine {
  SoloudAudioEngine({SoLoud? soloud, CueFormat? format})
    : _soloud = soloud ?? SoLoud.instance,
      _format = format ?? CueFormat.forPlatform();

  final SoLoud _soloud;
  final CueFormat _format;
  final Map<Cue, AudioSource> _sources = {};

  /// Typing ticks overlap each other and the room tone; the default cap (16) could steal them.
  static const int _maxVoices = 32;

  @override
  Future<void> start() async {
    // init() on a running engine re-initialises it and unloads everything: start once.
    if (_soloud.isInitialized) return;
    await _soloud.init(
      lowLatency: defaultTargetPlatform != TargetPlatform.android || kIsWeb,
    );
    _soloud.setMaxActiveVoiceCount(_maxVoices);
  }

  @override
  Future<void> load(Cue cue) async {
    if (_sources.containsKey(cue)) return;
    _sources[cue] = await _soloud.loadAsset(
      cue.assetPath(_format),
      mode: kIsWeb ? LoadMode.disk : LoadMode.memory,
    );
  }

  @override
  AudioVoice? play(
    Cue cue, {
    required double volume,
    double speed = 1,
    bool loop = false,
  }) {
    final source = _sources[cue];
    if (source == null) return null;
    final handle = _soloud.play(
      source,
      volume: volume,
      looping: loop,
      paused: speed != 1,
    );
    if (speed != 1) {
      // Set the speed before the first sample plays, so the tick never starts at the wrong pitch.
      _soloud
        ..setRelativePlaySpeed(handle, speed)
        ..setPause(handle, false);
    }
    return AudioVoice(handle.id);
  }

  @override
  void fadeVolume(AudioVoice voice, double volume, Duration over) {
    final handle = SoundHandle(voice.id);
    if (!_soloud.getIsValidVoiceHandle(handle)) return;
    if (over == Duration.zero) {
      _soloud.setVolume(handle, volume);
    } else {
      _soloud.fadeVolume(handle, volume, over);
    }
  }

  @override
  void stop(AudioVoice voice, {Duration fadeOut = Duration.zero}) {
    final handle = SoundHandle(voice.id);
    if (!_soloud.getIsValidVoiceHandle(handle)) return;
    if (fadeOut == Duration.zero) {
      unawaited(_soloud.stop(handle));
    } else {
      _soloud
        ..fadeVolume(handle, 0, fadeOut)
        ..scheduleStop(handle, fadeOut);
    }
  }

  @override
  void stopAll() {
    for (final source in _sources.values) {
      _soloud.stopAudioSource(source);
    }
  }
}
