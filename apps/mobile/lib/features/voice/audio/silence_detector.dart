/// One reading of the microphone's level: [dbfs] over the [length] of audio it measured.
class LevelSample {
  const LevelSample({required this.dbfs, required this.length});

  final double dbfs;
  final Duration length;
}

/// Hears the player go quiet (brief 35): [window] of audio below [threshold], in a row, while
/// recording. The recorder then pauses by itself and says so.
///
/// It counts *audio* time from each sample's [LevelSample.length], never the wall clock, so a
/// test feeds it a fake amplitude stream and gets the same answer every time, and a stalled
/// stream can't pause a take.
class SilenceDetector {
  SilenceDetector({
    this.threshold = defaultThreshold,
    this.window = defaultWindow,
  });

  /// Below this the room counts as quiet. Speech near a phone sits around -30 to -15 dBFS, a
  /// quiet room around -60 to -50; -45 leaves room for a soft voice and a noisy fan.
  static const double defaultThreshold = -45;

  /// The reviewer asked for 5–6 seconds; the brief fixed it at 5.
  static const Duration defaultWindow = Duration(seconds: 5);

  final double threshold;
  final Duration window;

  Duration _quiet = Duration.zero;
  bool _fired = false;

  /// How long it has been quiet, in a row.
  Duration get quiet => _quiet;

  /// Takes one sample. True exactly once per silence: on the sample that makes the quiet reach
  /// [window]. A loud sample starts the count again.
  bool add(LevelSample sample) {
    if (sample.dbfs >= threshold) {
      _quiet = Duration.zero;
      _fired = false;
      return false;
    }
    _quiet += sample.length;
    if (_fired || _quiet < window) return false;
    _fired = true;
    return true;
  }

  /// Forgets the quiet so far (a take resumed, or thrown away).
  void reset() {
    _quiet = Duration.zero;
    _fired = false;
  }

  /// An event each time [levels] goes quiet for [window].
  Stream<void> watch(Stream<LevelSample> levels) =>
      levels.where(add).map((_) {});
}
