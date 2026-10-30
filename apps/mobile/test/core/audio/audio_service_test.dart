import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/audio/audio_service.dart';
import 'package:the_last_room/core/audio/audio_settings.dart';
import 'package:the_last_room/core/audio/cue.dart';
import 'package:the_last_room/core/logging/log.dart';

import 'fake_audio_engine.dart';

void main() {
  late FakeAudioEngine engine;
  late List<LogRecord> records;
  late AudioService audio;

  AudioService serviceOn(FakeAudioEngine e) => AudioService(
    engine: e,
    log: Log(sink: records.add),
  );

  setUp(() async {
    records = [];
    engine = FakeAudioEngine();
    audio = serviceOn(engine);
    await audio.preload();
  });

  test('preload starts the engine and decodes every cue', () {
    expect(engine.started, isTrue);
    expect(engine.loaded, Cue.values.toSet());
    expect(audio.status, AudioStatus.ready);
  });

  group('init failure falls back to silent', () {
    for (final (name, broken) in [
      ('no device', FakeAudioEngine(failStart: true)),
      ('a file will not load', FakeAudioEngine(failLoad: true)),
    ]) {
      test(name, () async {
        final silent = serviceOn(broken);
        await expectLater(silent.preload(), completes);
        expect(silent.status, AudioStatus.silent);
        expect(silent.play(Cue.stamp), isNull);
        silent
          ..startAmbience(1)
          ..duck()
          ..stopAll();
        expect(broken.played, isEmpty);
        expect(records.where((r) => r.level == LogLevel.warn), hasLength(1));
      });
    }
  });

  test('nothing plays before preload (the web before the first tap)', () {
    final idle = serviceOn(FakeAudioEngine());
    expect(idle.play(Cue.stamp), isNull);
    expect(idle.status, AudioStatus.idle);
  });

  test(
    'a room asked for before sound starts begins once it is ready',
    () async {
      final e = FakeAudioEngine();
      final late = serviceOn(e)..startAmbience(1);
      expect(e.played, isEmpty);
      await late.preload();
      expect(e.live.single.cue, Cue.ambienceLobby);
    },
  );

  test('cues play at their bus volume times the gain', () {
    audio.applySettings(
      const AudioSettings(ambienceVolume: 0.3, effectsVolume: 0.5),
    );
    audio
      ..play(Cue.stamp, gain: 0.5, speed: 1.05)
      ..play(Cue.titleOpen);
    expect(engine.played[0].volume, closeTo(0.25, 1e-9));
    expect(engine.played[0].speed, 1.05);
    expect(engine.played[1].volume, closeTo(0.3, 1e-9));
  });

  test('defaults: effects at 80%, ambience at 50%', () {
    audio
      ..applySettings(const AudioSettings())
      ..play(Cue.choiceTap)
      ..startAmbience(1);
    expect(engine.played[0].volume, 0.8);
    expect(engine.live.last.volume, 0.5);
  });

  group('ambience', () {
    test('each chapter has its own room; the same room twice is a no-op', () {
      expect(AudioService.ambienceForChapter(1), Cue.ambienceLobby);
      expect(AudioService.ambienceForChapter(2), Cue.ambienceCorridor);
      expect(AudioService.ambienceForChapter(3), Cue.ambienceBoardroom);
      audio
        ..startAmbience(1)
        ..startAmbience(1);
      expect(engine.played, hasLength(1));
      expect(engine.played.single.loop, isTrue);
    });

    test(
      'switching rooms cross-fades: the old loop stops, the new one starts',
      () {
        audio
          ..startAmbience(1)
          ..startAmbience(2);
        expect(engine.live.map((p) => p.cue), [Cue.ambienceCorridor]);
        expect(audio.currentLoop, Cue.ambienceCorridor);
      },
    );

    test('duck drops the room to 60% and unduck brings it back', () {
      audio
        ..startAmbience(3)
        ..duck();
      expect(engine.live.single.volume, closeTo(0.5 * 0.6, 1e-9));
      audio.unduck();
      expect(engine.live.single.volume, closeTo(0.5, 1e-9));
    });

    test(
      'an interruption that ducks lowers everything, its end restores it',
      () {
        audio
          ..startAmbience(1)
          ..interruptionBegan(duck: true);
        expect(engine.masterVolume, AudioService.interruptionDuckLevel);
        expect(engine.live.single.cue, Cue.ambienceLobby);
        audio.interruptionEnded();
        expect(engine.masterVolume, 1);
      },
    );

    test('an interruption that pauses silences the game until it ends', () {
      audio
        ..startAmbience(1)
        ..interruptionBegan(duck: false);
      expect(engine.live, isEmpty);
      expect(audio.play(Cue.stamp), isNull);
      audio.interruptionEnded();
      expect(engine.live.single.cue, Cue.ambienceLobby);
    });

    test('the end of an interruption doesn\'t wake a hidden app', () {
      audio
        ..startAmbience(1)
        ..suspend()
        ..interruptionBegan(duck: false)
        ..interruptionEnded();
      expect(engine.live, isEmpty);
      audio.resume();
      expect(engine.live.single.cue, Cue.ambienceLobby);
    });

    test('suspend fades the room out, resume brings it back', () {
      audio
        ..startAmbience(1)
        ..suspend();
      expect(engine.live, isEmpty);
      expect(audio.play(Cue.stamp), isNull);
      audio.resume();
      expect(engine.live.single.cue, Cue.ambienceLobby);
    });
  });

  group('master off mutes everything', () {
    test('stops what is playing and plays nothing new', () {
      audio
        ..startAmbience(1)
        ..play(Cue.titleOpen)
        ..applySettings(const AudioSettings(enabled: false));
      expect(engine.live, isEmpty);
      final before = engine.played.length;
      audio
        ..play(Cue.stamp)
        ..startAmbience(2)
        ..duck();
      for (final cue in Cue.values) {
        if (!cue.loops) audio.play(cue);
      }
      expect(engine.played, hasLength(before));
    });

    test('turning it back on restores the room the scene wants', () {
      audio
        ..startAmbience(2)
        ..applySettings(const AudioSettings(enabled: false))
        ..applySettings(const AudioSettings());
      expect(engine.live.single.cue, Cue.ambienceCorridor);
    });
  });

  test('stopAll stops every voice and forgets the room', () {
    audio
      ..startAmbience(1)
      ..play(Cue.stamp)
      ..stopAll();
    expect(engine.live, isEmpty);
    expect(audio.currentLoop, isNull);
  });
}
