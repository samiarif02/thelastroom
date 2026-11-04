import 'dart:async';

import 'package:flutter/foundation.dart';

import '../recorder/take_recorder.dart';
import 'take_playback.dart';

/// Where a take stands in the player.
enum ListenState { idle, playing, paused }

/// The self-check's player (owner, 4 Nov: "it should show pause or play so the user knows if
/// anything is playing"): one take at a time, play ↔ pause, resume where it paused, back to the
/// start at the end. Polls [TakePlayback.position] every [tick] while playing; a clip that plays
/// out (or never started) resets. Dispose stops the sound, so leaving the screen silences it.
class ListenBack extends ChangeNotifier {
  ListenBack(this._playback, {this.tick = defaultTick});

  static const Duration defaultTick = Duration(milliseconds: 100);

  final TakePlayback _playback;
  final Duration tick;

  Take? _take;
  ListenState _state = ListenState.idle;
  Duration _position = Duration.zero;
  Timer? _poll;
  bool _disposed = false;

  /// The take loaded in the player, playing or paused; null when idle.
  Take? get current => _take;

  ListenState stateOf(Take take) =>
      identical(take, _take) ? _state : ListenState.idle;

  /// How far into [take] the player is; zero unless it's the [current] one.
  Duration positionOf(Take take) =>
      identical(take, _take) ? _position : Duration.zero;

  /// The tile's tap: plays [take] from the start (stopping any other), pauses it, or carries on.
  Future<void> toggle(Take take) async {
    switch (stateOf(take)) {
      case ListenState.playing:
        _poll?.cancel();
        _state = ListenState.paused;
        _notify();
        await _playback.pause();
      case ListenState.paused:
        _state = ListenState.playing;
        _notify();
        await _playback.resume();
        _startPolling();
      case ListenState.idle:
        _poll?.cancel();
        _take = take;
        _state = ListenState.playing;
        _position = Duration.zero;
        _notify();
        await _playback.play(take.wav);
        if (_disposed || !identical(_take, take)) return;
        _startPolling();
    }
  }

  /// Stops whatever is playing and goes back to idle.
  Future<void> stop() async {
    final had = _take != null;
    _reset();
    if (had) await _playback.stop();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(tick, (_) => _read());
  }

  void _read() {
    final take = _take;
    if (take == null || _state != ListenState.playing) return;
    final at = _playback.position;
    if (at == null || at >= take.length) {
      unawaited(stop());
      return;
    }
    _position = at;
    _notify();
  }

  void _reset() {
    _poll?.cancel();
    _poll = null;
    _take = null;
    _state = ListenState.idle;
    _position = Duration.zero;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _poll?.cancel();
    final had = _take != null;
    _disposed = true;
    if (had) unawaited(_playback.stop());
    super.dispose();
  }
}
