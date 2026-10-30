import 'dart:math';

import 'package:content/content.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/audio/audio_game_sounds.dart';
import 'package:the_last_room/core/audio/audio_service.dart';
import 'package:the_last_room/core/audio/cue.dart';
import 'package:the_last_room/core/audio/game_sounds.dart';
import 'package:the_last_room/core/audio/typing_voice.dart';
import 'package:the_last_room/core/logging/log.dart';

import 'fake_audio_engine.dart';

void main() {
  late FakeAudioEngine engine;
  late AudioService audio;
  late AudioGameSounds sounds;
  var now = Duration.zero;

  setUp(() async {
    now = Duration.zero;
    engine = FakeAudioEngine();
    audio = AudioService(
      engine: engine,
      log: Log(sink: (_) {}),
    );
    await audio.preload();
    sounds = AudioGameSounds(
      audio: audio,
      ticker: TypingTicker(random: Random(4), now: () => now),
    );
  });

  void typeLine(GameSounds s, String interviewerId, String line) {
    for (final ch in line.split('')) {
      s.subtitleCharacter(interviewerId, ch);
      now += const Duration(milliseconds: 35);
    }
  }

  test('subtitles tick in the interviewer\'s own voice', () {
    typeLine(sounds, 'marcus', 'Walk me through the numbers');
    expect(engine.cues.toSet(), {Cue.typeMarcus});
  });

  test('tap to complete stops the typing at once', () {
    // Short enough that every tick is still tracked (real ticks end on their own).
    typeLine(sounds, 'priya', 'Tell me so');
    expect(engine.live, isNotEmpty);
    sounds.subtitleCompleted();
    expect(engine.live, isEmpty);
  });

  test(
    'the question lands and ducks the room; locking the answer lifts it',
    () {
      sounds
        ..ambience(1)
        ..questionLands();
      expect(engine.cues, contains(Cue.questionLands));
      expect(audio.isDucked, isTrue);
      sounds.answerLocked();
      expect(engine.cues.last, Cue.answerLocked);
      expect(audio.isDucked, isFalse);
    },
  );

  test('Lena\'s follow-up is the sharper one', () {
    sounds
      ..followUpChallenge(priyaId)
      ..followUpChallenge(lenaId);
    expect(engine.cues, [Cue.followUp, Cue.followUpSharp]);
  });

  test('each call maps to its cue; results never use a fail sound', () {
    sounds
      ..choiceTapped()
      ..trustChanged(rising: true)
      ..trustChanged(rising: false)
      ..dossierSlides()
      ..result(strong: true)
      ..result(strong: false)
      ..chapterCard(1);
    expect(engine.cues, [
      Cue.choiceTap,
      Cue.trustUp,
      Cue.trustDown,
      Cue.dossierSlide,
      Cue.resultStrong,
      Cue.resultWeak,
      Cue.chapterCard,
    ]);
  });

  test('a stamp is followed by a short, fading count-up', () {
    fakeAsync((async) {
      sounds.scoreStamped();
      expect(engine.cues, [Cue.stamp]);
      async.elapse(const Duration(seconds: 1));
      final ticks = engine.played.where((p) => p.cue == Cue.countTick);
      expect(ticks, hasLength(AudioGameSounds.countUpTicks));
      expect(ticks.first.volume, greaterThan(ticks.last.volume));
    });
  });

  test('stopAll cancels a pending count-up', () {
    fakeAsync((async) {
      sounds
        ..scoreStamped()
        ..stopAll();
      async.elapse(const Duration(seconds: 1));
      expect(engine.cues, [Cue.stamp]);
    });
  });

  group('title, intro and tower', () {
    test('the title sting plays alone, then the lobby fades in under it', () {
      fakeAsync((async) {
        sounds.titleOpened();
        expect(engine.cues, [Cue.titleOpen]);
        async.elapse(AudioGameSounds.titleRoomToneDelay);
        expect(audio.currentLoop, Cue.ambienceLobby);
      });
    });

    test('the title never takes over a room a scene already chose', () {
      fakeAsync((async) {
        sounds
          ..titleOpened()
          ..ambience(2);
        async.elapse(AudioGameSounds.titleRoomToneDelay);
        expect(audio.currentLoop, Cue.ambienceCorridor);
      });
    });

    test('each one-shot hook maps to its cue', () {
      sounds
        ..uiTap()
        ..pageTurn()
        ..roomEntered()
        ..lockedRoomTapped();
      expect(engine.cues, [
        Cue.choiceTap,
        Cue.pageTurn,
        Cue.roomEnter,
        Cue.lockedFloor,
      ]);
    });

    test('the tower brings in the lobby\'s room tone', () {
      sounds.towerOpened();
      expect(engine.live.single.cue, Cue.ambienceLobby);
    });

    test('the elevator plays its whole sequence, in order', () {
      fakeAsync((async) {
        sounds.elevator();
        async.elapse(AudioGameSounds.elevatorSequence.last.$1);
        expect(engine.cues, [
          for (final (_, cue) in AudioGameSounds.elevatorSequence) cue,
        ]);
      });
    });

    test('stopAll cuts the title\'s pending room tone', () {
      fakeAsync((async) {
        sounds
          ..titleOpened()
          ..stopAll();
        async.elapse(const Duration(seconds: 10));
        expect(engine.cues, [Cue.titleOpen]);
        expect(audio.currentLoop, isNull);
      });
    });

    test('stopAll cuts an elevator mid-ride', () {
      fakeAsync((async) {
        sounds.elevator();
        async.elapse(const Duration(seconds: 1));
        sounds.stopAll();
        async.elapse(const Duration(seconds: 10));
        expect(engine.cues, [Cue.elevatorDoorsClose, Cue.elevatorRide]);
      });
    });
  });

  test('chapter ambience goes through the service', () {
    sounds.ambience(2);
    expect(engine.live.single.cue, Cue.ambienceCorridor);
  });

  test('no Cue plays in an untimed mission\'s timer', () {
    // Mission 1 as the player runs it: every call the contract has, except timerPulse, which
    // the player never makes for an untimed mission.
    const mission = missionTheOpportunity;
    expect(mission.timed, isFalse);
    fakeAsync((async) {
      sounds
        ..chapterCard(1)
        ..ambience(1);
      typeLine(sounds, mission.question.speakerId, mission.question.text);
      for (final _ in mission.beats) {
        sounds
          ..subtitleCompleted()
          ..questionLands()
          ..choiceTapped()
          ..answerLocked()
          ..trustChanged(rising: true);
      }
      sounds
        ..followUpChallenge(priyaId)
        ..dossierSlides()
        ..scoreStamped()
        ..result(strong: true);
      async.elapse(const Duration(seconds: 5));
      sounds.stopAll();
    });
    expect(engine.cues, isNot(contains(Cue.timerPulse)));
    expect(engine.cues, isNot(contains(Cue.timerTick)));
  });

  test('a timed mission\'s timer pulses, then ticks in the last seconds', () {
    sounds
      ..timerPulse(finalSeconds: false)
      ..timerPulse(finalSeconds: true);
    expect(engine.cues, [Cue.timerPulse, Cue.timerTick]);
  });

  test('with sound unavailable every call is a silent no-op', () async {
    final broken = FakeAudioEngine(failStart: true);
    final silent = AudioService(
      engine: broken,
      log: Log(sink: (_) {}),
    );
    await silent.preload();
    final s = AudioGameSounds(
      audio: silent,
      ticker: TypingTicker(random: Random(1), now: () => now),
    );
    typeLine(s, lenaId, 'Specifically.');
    s
      ..questionLands()
      ..answerLocked()
      ..result(strong: false)
      ..ambience(3)
      ..stopAll();
    expect(broken.played, isEmpty);
  });
}
