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
/// - **iOS:** SoLoud leaves `AVAudioSession` to the app; `audio_focus.dart` sets it to
///   `ambient` (respects the silent switch, mixes with the player's music).
///
/// Gain staging: a cue plays at its bus volume (`AudioSettings`) x the per-call gain, then SoLoud
/// adds two fixed stages: [masterGain] (pinned at start) and [monoToStereoGain] (every cue is
/// mono and the output is stereo). `gain_staging_test.dart` multiplies them out.
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

  /// SoLoud's global volume, set explicitly at start so nothing upstream leaves it lower.
  static const double masterGain = 1;

  /// SoLoud pans a mono voice into stereo with a constant-power law: each channel gets
  /// cos(pi / 4) at the centre, about -3 dB (`Soloud::setVoicePan_internal`).
  static const double monoToStereoGain = 0.7071067811865476;

  @override
  Future<void> start() async {
    // init() on a running engine re-initialises it and unloads everything: start once.
    if (_soloud.isInitialized) return;
    await _soloud.init(
      lowLatency: defaultTargetPlatform != TargetPlatform.android || kIsWeb,
    );
    _soloud
      ..setMaxActiveVoiceCount(_maxVoices)
      ..setGlobalVolume(masterGain);
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
  void fadeMasterVolume(double volume, Duration over) {
    if (!_soloud.isInitialized) return;
    if (over == Duration.zero) {
      _soloud.setGlobalVolume(volume);
    } else {
      _soloud.fadeGlobalVolume(volume, over);
    }
  }

  @override
  void stopAll() {
    for (final source in _sources.values) {
      _soloud.stopAudioSource(source);
    }
  }
}
