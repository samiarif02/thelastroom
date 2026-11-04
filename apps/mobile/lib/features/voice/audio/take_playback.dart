import 'dart:typed_data';

/// Plays a take back, so the player can listen before ticking the self-check (brief 35).
/// `SoloudTakePlayback` in the app (the game's own sound engine), [SilentTakePlayback] in tests.
/// One clip at a time: [play] stops whatever was playing. `ListenBack` drives it.
abstract interface class TakePlayback {
  /// Plays [wav] from the start, stopping anything already playing. Never throws: a device that
  /// can't play it stays quiet (the player can still tick from memory).
  Future<void> play(Uint8List wav);

  /// Holds the clip where it is; [resume] carries on from there.
  Future<void> pause();

  Future<void> resume();

  /// Stops and frees the clip.
  Future<void> stop();

  /// How far into the clip playback is; null when nothing is loaded (never played, stopped,
  /// failed, or it played to the end).
  Duration? get position;
}

/// Plays nothing; records what it was asked, for tests. [position] stays where a test puts it
/// ([at]), so a test walks a clip through its length; null once it's stopped or [finish]ed.
class SilentTakePlayback implements TakePlayback {
  final List<int> played = [];
  int pauses = 0;
  int resumes = 0;
  int stops = 0;

  /// Where the loaded clip is; null when nothing is loaded.
  Duration? at;

  bool paused = false;

  @override
  Future<void> play(Uint8List wav) async {
    played.add(wav.length);
    at = Duration.zero;
    paused = false;
  }

  @override
  Future<void> pause() async {
    pauses++;
    paused = true;
  }

  @override
  Future<void> resume() async {
    resumes++;
    paused = false;
  }

  @override
  Future<void> stop() async {
    stops++;
    at = null;
    paused = false;
  }

  /// The clip plays out by itself.
  void finish() => at = null;

  @override
  Duration? get position => at;
}
