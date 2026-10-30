import 'cue.dart';

/// One playing instance of a cue.
extension type const AudioVoice(int id) {}

/// What [AudioService] needs from a sound engine: flutter_soloud in the app
/// (`SoloudAudioEngine`), a recording fake in tests. Volumes are 0..1 gains.
abstract interface class AudioEngine {
  /// Starts the output device. Throws if there's no device or the platform refuses.
  Future<void> start();

  /// Decodes [cue]'s file so [play] can start it with no delay. Throws if the file can't load.
  Future<void> load(Cue cue);

  /// Starts [cue], or returns null if it isn't loaded. [speed] shifts the pitch too (1 = as
  /// recorded).
  AudioVoice? play(
    Cue cue, {
    required double volume,
    double speed = 1,
    bool loop = false,
  });

  /// Glides [voice] to [volume] over [over] (immediately when zero).
  void fadeVolume(AudioVoice voice, double volume, Duration over);

  /// Stops [voice], fading it out over [fadeOut] first.
  void stop(AudioVoice voice, {Duration fadeOut = Duration.zero});

  /// Stops every playing voice.
  void stopAll();
}
