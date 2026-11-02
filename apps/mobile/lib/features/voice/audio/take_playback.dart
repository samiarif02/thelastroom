import 'dart:typed_data';

/// Plays a take back, so the player can listen before ticking the self-check (brief 35).
/// `SoloudTakePlayback` in the app (the game's own sound engine), [SilentTakePlayback] in tests.
abstract interface class TakePlayback {
  /// Plays [wav] from the start, stopping anything already playing. Never throws: a device that
  /// can't play it stays quiet (the player can still tick from memory).
  Future<void> play(Uint8List wav);

  Future<void> stop();
}

/// Plays nothing; records what it was asked, for tests.
class SilentTakePlayback implements TakePlayback {
  final List<int> played = [];

  @override
  Future<void> play(Uint8List wav) async => played.add(wav.length);

  @override
  Future<void> stop() async {}
}
