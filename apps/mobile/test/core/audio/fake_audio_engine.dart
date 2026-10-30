import 'package:the_last_room/core/audio/audio_engine.dart';
import 'package:the_last_room/core/audio/cue.dart';

/// One call to [FakeAudioEngine.play].
class Played {
  Played(this.voice, this.cue, this.volume, this.speed, this.loop);

  final AudioVoice voice;
  final Cue cue;
  double volume;
  final double speed;
  final bool loop;
  bool stopped = false;

  @override
  String toString() => 'Played($cue, volume: $volume, speed: $speed)';
}

/// An [AudioEngine] that records what it's asked to do. Fades apply instantly.
class FakeAudioEngine implements AudioEngine {
  FakeAudioEngine({this.failStart = false, this.failLoad = false});

  final bool failStart;
  final bool failLoad;

  bool started = false;
  final Set<Cue> loaded = {};
  final List<Played> played = [];
  int stopAllCalls = 0;
  int _next = 1;

  /// What's sounding now.
  List<Played> get live => played.where((p) => !p.stopped).toList();

  List<Cue> get cues => played.map((p) => p.cue).toList();

  @override
  Future<void> start() async {
    if (failStart) throw StateError('no audio device');
    started = true;
  }

  @override
  Future<void> load(Cue cue) async {
    if (failLoad) throw StateError('missing ${cue.asset}');
    loaded.add(cue);
  }

  @override
  AudioVoice? play(
    Cue cue, {
    required double volume,
    double speed = 1,
    bool loop = false,
  }) {
    if (!loaded.contains(cue)) return null;
    final voice = AudioVoice(_next++);
    played.add(Played(voice, cue, volume, speed, loop));
    return voice;
  }

  Played _find(AudioVoice voice) => played.firstWhere((p) => p.voice == voice);

  @override
  void fadeVolume(AudioVoice voice, double volume, Duration over) =>
      _find(voice).volume = volume;

  @override
  void stop(AudioVoice voice, {Duration fadeOut = Duration.zero}) =>
      _find(voice).stopped = true;

  @override
  void stopAll() {
    stopAllCalls++;
    for (final p in played) {
      p.stopped = true;
    }
  }
}
