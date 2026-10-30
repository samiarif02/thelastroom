import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/audio/audio_game_sounds.dart';
import 'package:the_last_room/core/audio/audio_service.dart';
import 'package:the_last_room/core/audio/cue.dart';
import 'package:the_last_room/core/audio/soloud_audio_engine.dart';
import 'package:the_last_room/core/audio/typing_voice.dart';
import 'package:the_last_room/core/logging/log.dart';

import 'fake_audio_engine.dart';

// Tests run from apps/mobile, so the repo root is two levels up.
const String _credits = '../../docs/audio-credits.md';

/// What the lead measured on the realme 8 as "audible" (scrcpy capture of the app's own mix,
/// per channel, before the device volume): typing ticks and UI cues peak around -10 to -6 dBFS,
/// room tone clearly audible underneath (around -30 dB). The defaults must reach these floors.
const double _tickPeakFloorDb = -10;
const double _roomToneFloorDb = -32;

/// Below this a cue is clipping in the mix.
const double _clipDb = 0;

double _db(double gain) => 20 * log(gain) / ln10;

/// A file's (loudness LUFS, true peak dBTP), from the credits table the build writes.
(double, double) _fileLevel(Cue cue) {
  final row = File(_credits)
      .readAsLinesSync()
      .singleWhere((l) => l.startsWith('| `${cue.asset}.ogg`'));
  final lufs = RegExp(r'(-?[\d.]+) LUFS').firstMatch(row)!.group(1)!;
  final peak = RegExp(r'peak (-?[\d.]+) dBTP').firstMatch(row)!.group(1)!;
  return (double.parse(lufs), double.parse(peak));
}

/// Everything SoLoud adds after the per-voice volume we hand it.
final double _engineDb = _db(
  SoloudAudioEngine.masterGain * SoloudAudioEngine.monoToStereoGain,
);

void main() {
  late FakeAudioEngine engine;
  late AudioGameSounds sounds;
  var now = Duration.zero;

  setUp(() async {
    engine = FakeAudioEngine();
    final audio = AudioService(
      engine: engine,
      log: Log(sink: (_) {}),
    );
    await audio.preload();
    sounds = AudioGameSounds(
      audio: audio,
      ticker: TypingTicker(random: Random(9), now: () => now),
    );
  });

  // The default settings, through the real call path (GameSounds → AudioService → engine), so
  // a change to any stage (file, bus default, per-call gain, engine) moves the result.
  for (final voice in TypingVoice.values) {
    test('${voice.name}\'s typing ticks peak in the audible band', () {
      for (final ch in 'Tell me about a time'.split('')) {
        sounds.subtitleCharacter(voice.name, ch);
        now += const Duration(milliseconds: 60);
      }
      final tick = engine.played.firstWhere((p) => p.cue == voice.cue);
      final peak = _fileLevel(voice.cue).$2 + _db(tick.volume) + _engineDb;
      expect(peak, greaterThanOrEqualTo(_tickPeakFloorDb), reason: '$peak dB');
      expect(peak, lessThan(_clipDb));
    });
  }

  test('UI taps and page turns peak in the audible band', () {
    sounds
      ..uiTap()
      ..pageTurn()
      ..choiceTapped();
    for (final played in engine.played) {
      final peak = _fileLevel(played.cue).$2 + _db(played.volume) + _engineDb;
      expect(
        peak,
        greaterThanOrEqualTo(_tickPeakFloorDb),
        reason: '${played.cue}: $peak dB',
      );
    }
  });

  for (final chapter in [1, 2, 3]) {
    test('chapter $chapter\'s room tone is clearly audible underneath', () {
      sounds.ambience(chapter);
      final room = engine.live.single;
      final level = _fileLevel(room.cue).$1 + _db(room.volume) + _engineDb;
      expect(level, greaterThanOrEqualTo(_roomToneFloorDb), reason: '$level');
    });
  }
}
