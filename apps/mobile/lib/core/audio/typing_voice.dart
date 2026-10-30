import 'dart:math';

import 'cue.dart';

/// The typing sound of one interviewer's subtitles: their key [cue] at a base [speed] and [gain].
enum TypingVoice {
  /// Lighter.
  priya(Cue.typePriya),

  /// Woodier.
  marcus(Cue.typeMarcus),

  /// Drier.
  lena(Cue.typeLena),

  /// Deeper.
  sam(Cue.typeSam);

  const TypingVoice(this.cue);

  final Cue cue;

  /// The voice for an interviewer id from `package:content`; anyone else (the player, a
  /// narrator) types with Priya's light key.
  static TypingVoice forInterviewer(String interviewerId) {
    for (final voice in values) {
      if (voice.name == interviewerId) return voice;
    }
    return priya;
  }
}

/// One tick to play.
class TypingTick {
  const TypingTick(this.cue, {required this.speed, required this.gain});

  final Cue cue;

  /// Playback speed, which is also the pitch (1 = as recorded).
  final double speed;
  final double gain;

  @override
  String toString() => 'TypingTick($cue, speed: $speed, gain: $gain)';
}

/// Decides which subtitle characters tick (the cue sheet's rules):
///
/// - a tick on every 2nd–3rd letter or digit, chosen at random each time;
/// - pitch varies ±6% per tick;
/// - at most 18 ticks a second, however fast the text types;
/// - silent on spaces and punctuation, except a softer, lower "pause tick" on "…";
/// - [reset] when the line is completed by a tap, so the next line starts fresh.
///
/// [random] and [now] are injected so the rules are testable (a seed, a fake clock).
class TypingTicker {
  TypingTicker({required this._random, required this._now}) {
    _nextAt = _drawGap();
  }

  final Random _random;
  final Duration Function() _now;

  static const int minGap = 2;
  static const int maxGap = 3;
  static const double pitchSpread = 0.06;
  static const int maxPerSecond = 18;
  static const Duration minInterval = Duration(
    microseconds: Duration.microsecondsPerSecond ~/ maxPerSecond,
  );

  static const String ellipsis = '…';
  static const double pauseSpeed = 0.82;
  static const double pauseGain = 0.7;

  int _counted = 0;
  late int _nextAt;
  Duration? _lastTick;

  /// The tick for [character] typed by [voice], or null when it stays silent.
  TypingTick? onCharacter(TypingVoice voice, String character) {
    if (character == ellipsis) {
      return _tick(voice, speed: pauseSpeed, gain: pauseGain);
    }
    if (!isVoiced(character)) return null;
    _counted++;
    if (_counted < _nextAt) return null;
    final tick = _tick(
      voice,
      speed: 1 + (_random.nextDouble() * 2 - 1) * pitchSpread,
      gain: 1,
    );
    // A tick the rate limit swallowed doesn't restart the count: the next letter tries again.
    if (tick != null) {
      _counted = 0;
      _nextAt = _drawGap();
    }
    return tick;
  }

  /// The line was completed (or a new one starts): forget the count.
  void reset() {
    _counted = 0;
    _nextAt = _drawGap();
  }

  TypingTick? _tick(
    TypingVoice voice, {
    required double speed,
    required double gain,
  }) {
    final now = _now();
    final last = _lastTick;
    if (last != null && now - last < minInterval) return null;
    _lastTick = now;
    return TypingTick(voice.cue, speed: speed, gain: gain);
  }

  int _drawGap() => minGap + _random.nextInt(maxGap - minGap + 1);

  /// Letters and digits in any script tick; spaces, punctuation and symbols don't.
  static bool isVoiced(String character) =>
      character.isNotEmpty && _voiced.hasMatch(character);

  static final RegExp _voiced = RegExp(r'[\p{L}\p{N}]', unicode: true);
}
