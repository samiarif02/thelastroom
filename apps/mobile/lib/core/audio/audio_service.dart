import 'package:flutter/foundation.dart';

import '../logging/log.dart';
import 'audio_engine.dart';
import 'audio_settings.dart';
import 'cue.dart';

/// Where the sound system is: [ready] plays, everything else is silent.
enum AudioStatus {
  /// Not started yet (on the web: waiting for the first tap).
  idle,
  starting,
  ready,

  /// Couldn't start (no device, a platform error, a missing file): the game plays in silence.
  silent,
}

/// The game's sound: named cues on top of an [AudioEngine], following the player's
/// [AudioSettings]. Sound is optional (ADR 0005): nothing here throws, blocks a frame or shows
/// an error; if the engine can't start the game is silent and one `warn` is logged.
class AudioService {
  AudioService({required this._engine, required this._log});

  final AudioEngine _engine;
  final Log _log;

  /// The room tone cross-fades over this long when the scene changes (spec).
  static const Duration ambienceCrossfade = Duration(milliseconds: 1500);

  /// When the question lands the room tone drops by 40% (spec), and comes back after.
  static const double duckedLevel = 0.6;
  static const Duration duckFade = Duration(milliseconds: 250);
  static const Duration unduckFade = Duration(milliseconds: 900);

  /// Settings changes and master on/off glide rather than jump.
  static const Duration settingsFade = Duration(milliseconds: 200);

  final ValueNotifier<AudioStatus> _status = ValueNotifier(AudioStatus.idle);
  AudioStatus get status => _status.value;

  /// For the dev board's status line.
  ValueListenable<AudioStatus> get statusListenable => _status;

  AudioSettings _settings = const AudioSettings();
  AudioSettings get settings => _settings;

  bool _ducked = false;
  bool get isDucked => _ducked;

  bool _suspended = false;

  // The loop the scene wants, kept even while muted or not started, so it can come back.
  Cue? _loop;
  AudioVoice? _loopVoice;

  /// The room tone the scene asked for (null when none).
  Cue? get currentLoop => _loop;

  /// Starts the engine and decodes every cue, so the first play has no delay. Never throws;
  /// on failure the service goes [AudioStatus.silent]. Safe to call more than once.
  Future<void> preload() async {
    if (_status.value != AudioStatus.idle) return;
    _status.value = AudioStatus.starting;
    try {
      await _engine.start();
      await Future.wait(Cue.values.map(_engine.load));
      _status.value = AudioStatus.ready;
      _log.info('audio ready', {'cues': Cue.values.length});
      _restartLoop(fadeIn: ambienceCrossfade);
    } on Object catch (e) {
      _status.value = AudioStatus.silent;
      _log.warn('audio unavailable, playing silently', {
        'error': e.runtimeType.toString(),
      });
    }
  }

  bool get _canPlay => _status.value == AudioStatus.ready && !_suspended;

  /// Plays a one-shot [cue] at its bus volume times [gain], at [speed] (pitch follows). Returns
  /// the voice, or null when nothing plays (sound off, not started, silent).
  AudioVoice? play(Cue cue, {double gain = 1, double speed = 1}) {
    if (!_canPlay) return null;
    final volume = _settings.volumeFor(cue.bus) * gain;
    if (volume <= 0) return null;
    return _engine.play(cue, volume: volume, speed: speed);
  }

  /// Stops one voice [play] returned.
  void stop(AudioVoice voice) => _engine.stop(voice);

  /// The room tone for a chapter (1-based), cross-fading from whatever was playing. Chapters
  /// with no room of their own fall back to the last one.
  void startAmbience(int chapter) => startLoop(ambienceForChapter(chapter));

  static Cue ambienceForChapter(int chapter) => switch (chapter) {
    <= 1 => Cue.ambienceLobby,
    2 => Cue.ambienceCorridor,
    _ => Cue.ambienceBoardroom,
  };

  /// Cross-fades to the looping [cue] (a chapter's room or the Recall Room's pad). The same
  /// loop again is a no-op, so screens can call it on every build of a scene.
  void startLoop(Cue cue) {
    assert(cue.loops, '$cue is not a loop');
    if (cue == _loop && _loopVoice != null) return;
    _loop = cue;
    _restartLoop(fadeIn: ambienceCrossfade);
  }

  /// Fades the room tone out.
  void stopAmbience() {
    _loop = null;
    _fadeOutLoop();
  }

  /// The question lands: the room tone drops to [duckedLevel].
  void duck() {
    if (_ducked) return;
    _ducked = true;
    _applyLoopVolume(duckFade);
  }

  void unduck() {
    if (!_ducked) return;
    _ducked = false;
    _applyLoopVolume(unduckFade);
  }

  /// Everything stops, the room tone included (leaving the scene).
  void stopAll() {
    _loop = null;
    _loopVoice = null;
    _ducked = false;
    if (_status.value == AudioStatus.ready) _engine.stopAll();
  }

  /// The app went to the background or lost the screen: fade to silence, but remember the
  /// room so [resume] brings it back.
  void suspend() {
    if (_suspended) return;
    _suspended = true;
    _fadeOutLoop();
  }

  void resume() {
    if (!_suspended) return;
    _suspended = false;
    _restartLoop(fadeIn: ambienceCrossfade);
  }

  /// Follows the player's settings: volumes glide, master off fades everything out.
  void applySettings(AudioSettings next) {
    final wasEnabled = _settings.enabled;
    _settings = next;
    if (!next.enabled) {
      _fadeOutLoop();
      if (wasEnabled && _status.value == AudioStatus.ready) _engine.stopAll();
      return;
    }
    if (_loopVoice == null) {
      _restartLoop(fadeIn: ambienceCrossfade);
    } else {
      _applyLoopVolume(settingsFade);
    }
  }

  double get _loopVolume =>
      _settings.volumeFor(CueBus.ambience) * (_ducked ? duckedLevel : 1);

  void _restartLoop({required Duration fadeIn}) {
    _fadeOutLoop();
    final cue = _loop;
    if (cue == null || !_canPlay || _loopVolume <= 0) return;
    final voice = _engine.play(cue, volume: 0, loop: true);
    if (voice == null) return;
    _engine.fadeVolume(voice, _loopVolume, fadeIn);
    _loopVoice = voice;
  }

  void _fadeOutLoop() {
    final voice = _loopVoice;
    _loopVoice = null;
    if (voice != null) _engine.stop(voice, fadeOut: ambienceCrossfade);
  }

  void _applyLoopVolume(Duration over) {
    final voice = _loopVoice;
    if (voice != null) _engine.fadeVolume(voice, _loopVolume, over);
  }
}
