import 'dart:async';

import 'package:content/content.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/logging/log.dart';
import 'interviewer_voice.dart';

/// [InterviewerVoice] on `flutter_tts`: the device's speech engine on Android and iOS, the
/// browser's speech synthesis on the web. The only file that imports it.
///
/// Every call is guarded: a missing engine, a refused language or a plugin error is a `warn`
/// log and silence. A line that never reports its end is let go after [_capFor], so the scene
/// can't hang on a speech engine.
class TtsInterviewerVoice implements InterviewerVoice {
  TtsInterviewerVoice({required this._log, FlutterTts? tts})
    : _tts = tts ?? FlutterTts();

  final Log _log;
  final FlutterTts _tts;
  Future<void>? _ready;

  /// English, like the content.
  static const String _language = 'en-US';

  /// Slightly slower than the engine's default: an interviewer, not a narrator.
  static const double _rate = 0.48;

  /// A line is given up on after this, plus [_perCharacter] for each character.
  static const Duration _capBase = Duration(seconds: 2);
  static const Duration _perCharacter = Duration(milliseconds: 90);

  static Duration _capFor(String text) =>
      _capBase + _perCharacter * text.length;

  Future<void> _setUp() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_rate);
  }

  @override
  Future<void> say(SceneLine line) async {
    try {
      await (_ready ??= _setUp());
      await _tts.setPitch(InterviewerPitch.of(line.speakerId));
      await _tts.speak(line.text).timeout(_capFor(line.text));
    } on TimeoutException {
      // The engine never said it finished: the scene moves on regardless.
    } on Object catch (error) {
      _ready = null;
      _log.warn('text to speech failed', {'error': '${error.runtimeType}'});
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object catch (error) {
      _log.warn('text to speech stop failed', {
        'error': '${error.runtimeType}',
      });
    }
  }
}
