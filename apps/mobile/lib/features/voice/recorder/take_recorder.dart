import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/logging/log.dart';
import '../audio/microphone.dart';
import '../audio/pcm.dart';
import '../audio/silence_detector.dart';

/// Where the recorder is. Every one is a designed state (brief 35's acceptance).
enum RecorderPhase {
  /// Checking whether the microphone is already allowed.
  checking,

  /// Not yet allowed: the one-line explainer and "Allow the microphone".
  explain,

  /// The OS permission dialog is up.
  asking,

  /// Refused, or no microphone: the self-check is offered instead.
  denied,

  /// Allowed, nothing recorded yet.
  empty,

  /// Recording.
  recording,

  /// Paused, by the player or by [PauseReason.silence]; Continue appends.
  paused,

  /// The take reached the mission's limit; it can be submitted or thrown away.
  full,
}

/// Why a take paused.
enum PauseReason {
  /// The player tapped the record button.
  player,

  /// [SilenceDetector.defaultWindow] of quiet: "Paused: you went quiet."
  silence,
}

/// A finished take: the audio as WAV and what `voice_answer_recorded` reports about it. Held in
/// memory only, and dropped after the debrief.
class Take {
  const Take({
    required this.wav,
    required this.length,
    required this.pausedCount,
    required this.retakes,
  });

  final Uint8List wav;
  final Duration length;
  final int pausedCount;
  final int retakes;

  /// Whole seconds, rounded to the nearest (for the event and the stored answer).
  int get seconds =>
      (length.inMilliseconds + Duration.millisecondsPerSecond ~/ 2) ~/
      Duration.millisecondsPerSecond;
}

/// The recorder (brief 35): a take that pauses by itself after [silence] of quiet, resumes
/// where it stopped, can be thrown away (after a confirm), and stops at [maxLength].
///
/// The PCM it receives is appended to one buffer, so Continue really is the same take. The
/// level and the elapsed time are measured from the audio itself, never the clock, so a test
/// drives it with a fake [Microphone] and gets the same states every time.
class TakeRecorder extends ChangeNotifier {
  TakeRecorder({
    required Microphone microphone,
    required this.maxLength,
    this._log,
    SilenceDetector? silence,
  }) : _mic = microphone,
       _silence = silence ?? SilenceDetector();

  final Microphone _mic;
  final Log? _log;
  final SilenceDetector _silence;

  /// The longest a take may run (the mission's `maxSeconds`).
  final Duration maxLength;

  /// A take shorter than this can't be submitted: a tap, not an answer.
  static const Duration minLength = Duration(seconds: 1);

  /// The level meter's range: at or below [quietDbfs] it's empty, at [loudDbfs] it's full.
  static const double quietDbfs = -60;
  static const double loudDbfs = -10;

  RecorderPhase _phase = RecorderPhase.checking;
  PauseReason? _pauseReason;
  final BytesBuilder _pcm = BytesBuilder(copy: false);
  double _level = 0;
  int _pausedCount = 0;
  int _retakes = 0;
  bool _confirmingDelete = false;
  StreamSubscription<Uint8List>? _stream;
  bool _disposed = false;

  RecorderPhase get phase => _phase;
  PauseReason? get pauseReason =>
      _phase == RecorderPhase.paused ? _pauseReason : null;

  /// The live level, 0–1, for the meter (0 when not recording).
  double get level => _phase == RecorderPhase.recording ? _level : 0;

  /// How long the take runs so far.
  Duration get elapsed => VoicePcm.durationOf(_pcm.length);

  /// How long is left before the cap.
  Duration get remaining => maxLength - elapsed;

  int get pausedCount => _pausedCount;
  int get retakes => _retakes;

  /// "Delete this take?" is up.
  bool get confirmingDelete => _confirmingDelete;

  /// There's something to submit or throw away.
  bool get hasTake => _pcm.length > 0;

  /// Done is offered: a take of at least [minLength].
  bool get canSubmit =>
      elapsed >= minLength &&
      (_phase == RecorderPhase.recording ||
          _phase == RecorderPhase.paused ||
          _phase == RecorderPhase.full);

  void _set(RecorderPhase phase, {PauseReason? reason}) {
    if (_disposed) return;
    _phase = phase;
    _pauseReason = reason;
    notifyListeners();
  }

  /// Checks the permission without asking: straight to the recorder when it's already granted.
  Future<void> start() async {
    try {
      _set(
        await _mic.hasAccess() ? RecorderPhase.empty : RecorderPhase.explain,
      );
    } on Object catch (error) {
      _log?.warn('microphone check failed', {'error': '${error.runtimeType}'});
      _set(RecorderPhase.explain);
    }
  }

  /// "Allow the microphone": the OS dialog, after the explainer.
  Future<void> allow() async {
    if (_phase != RecorderPhase.explain) return;
    _set(RecorderPhase.asking);
    try {
      final access = await _mic.ask();
      _set(
        access == MicAccess.granted
            ? RecorderPhase.empty
            : RecorderPhase.denied,
      );
    } on Object catch (error) {
      _log?.warn('microphone request failed', {
        'error': '${error.runtimeType}',
      });
      _set(RecorderPhase.denied);
    }
  }

  /// The record button: starts an empty take, pauses a running one, continues a paused one.
  Future<void> toggle() => switch (_phase) {
    RecorderPhase.empty || RecorderPhase.paused => _open(),
    RecorderPhase.recording => pause(PauseReason.player),
    _ => Future.value(),
  };

  /// Continue: the same take, appended from where it paused.
  Future<void> resume() =>
      _phase == RecorderPhase.paused ? _open() : Future.value();

  Future<void> _open() async {
    if (elapsed >= maxLength) {
      _set(RecorderPhase.full);
      return;
    }
    _silence.reset();
    _set(RecorderPhase.recording);
    try {
      if (_closing case final closing?) await closing;
      final stream = await _mic.open();
      if (_disposed || _phase != RecorderPhase.recording) {
        await _mic.close();
        return;
      }
      _stream = stream.listen(_heard, onError: _failed);
    } on Object catch (error) {
      _failed(error);
    }
  }

  void _failed(Object error) {
    _log?.warn('microphone failed', {'error': '${error.runtimeType}'});
    unawaited(_close());
    _set(RecorderPhase.denied);
  }

  /// One chunk of audio: kept, measured, and checked against the cap and the silence.
  void _heard(Uint8List chunk) {
    if (_phase != RecorderPhase.recording || chunk.isEmpty) return;
    final room = VoicePcm.bytesFor(maxLength) - _pcm.length;
    final kept = chunk.length <= room
        ? chunk
        : Uint8List.sublistView(chunk, 0, room);
    _pcm.add(kept);
    final dbfs = VoicePcm.levelDbfs(kept);
    _level = ((dbfs - quietDbfs) / (loudDbfs - quietDbfs)).clamp(0.0, 1.0);
    if (chunk.length >= room) {
      unawaited(_close());
      _set(RecorderPhase.full);
      return;
    }
    if (_silence.add(
      LevelSample(dbfs: dbfs, length: VoicePcm.durationOf(kept.length)),
    )) {
      unawaited(pause(PauseReason.silence));
      return;
    }
    notifyListeners();
  }

  /// Pauses the take (the player's tap, or the silence).
  Future<void> pause(PauseReason reason) async {
    if (_phase != RecorderPhase.recording) return;
    _pausedCount++;
    _set(RecorderPhase.paused, reason: reason);
    await _close();
  }

  /// The close in flight, if any: [_open] waits for it, so a quick Continue after the silence
  /// pause can't have its new stream closed by the old one's close.
  Future<void>? _closing;

  Future<void> _close() =>
      _closing ??= _closeNow().whenComplete(() => _closing = null);

  Future<void> _closeNow() async {
    // Not awaited: nothing more is read once the field is cleared, and the microphone is
    // stopped next, which is what ends the platform stream.
    unawaited(_stream?.cancel());
    _stream = null;
    try {
      await _mic.close();
    } on Object catch (error) {
      _log?.warn('microphone close failed', {'error': '${error.runtimeType}'});
    }
  }

  /// "Delete": asks first. Recording pauses while the player decides.
  Future<void> askDelete() async {
    if (!hasTake) return;
    // Stopped while the player decides; not a pause they chose, so it isn't counted.
    if (_phase == RecorderPhase.recording) {
      _set(RecorderPhase.paused, reason: PauseReason.player);
      await _close();
    }
    _confirmingDelete = true;
    notifyListeners();
  }

  void cancelDelete() {
    _confirmingDelete = false;
    notifyListeners();
  }

  /// "Delete" confirmed: the take is thrown away and the recorder is empty again.
  Future<void> confirmDelete() async {
    if (!_confirmingDelete) return;
    _confirmingDelete = false;
    await _close();
    _pcm.clear();
    _level = 0;
    _retakes++;
    _silence.reset();
    _set(RecorderPhase.empty);
  }

  /// "Done": stops recording and hands the take over, or null when there's nothing to submit.
  Future<Take?> submit() async {
    if (!canSubmit) return null;
    await _close();
    final take = Take(
      wav: VoicePcm.wav(_pcm.toBytes()),
      length: elapsed,
      pausedCount: _pausedCount,
      retakes: _retakes,
    );
    return take;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_close().then((_) => _mic.dispose()));
    _pcm.clear();
    super.dispose();
  }
}
