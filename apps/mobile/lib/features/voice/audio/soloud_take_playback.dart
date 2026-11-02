import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../../../core/logging/log.dart';
import 'take_playback.dart';

/// [TakePlayback] on flutter_soloud, the engine the game's sounds already use
/// (`SoloudAudioEngine`), so listening back adds no package. The WAV is loaded from memory:
/// nothing is written to disk, and the source is freed when playback stops.
class SoloudTakePlayback implements TakePlayback {
  SoloudTakePlayback({required this._log, SoLoud? soloud})
    : _soloud = soloud ?? SoLoud.instance;

  final Log _log;
  final SoLoud _soloud;
  AudioSource? _source;
  int _loads = 0;

  @override
  Future<void> play(Uint8List wav) async {
    try {
      await stop();
      // Started by the game already; on a silent start (sound off, web before a tap) start here.
      if (!_soloud.isInitialized) await _soloud.init();
      // A fresh name per load: SoLoud keys sources by name and hash.
      final source = await _soloud.loadMem('take-${_loads++}.wav', wav);
      _source = source;
      _soloud.play(source);
    } on Object catch (error) {
      _log.warn('take playback failed', {'error': '${error.runtimeType}'});
    }
  }

  @override
  Future<void> stop() async {
    final source = _source;
    _source = null;
    if (source == null) return;
    try {
      await _soloud.disposeSource(source);
    } on Object catch (error) {
      _log.warn('take playback stop failed', {'error': '${error.runtimeType}'});
    }
  }
}
