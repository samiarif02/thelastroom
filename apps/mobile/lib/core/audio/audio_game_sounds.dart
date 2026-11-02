import 'dart:async';

import 'audio_engine.dart';
import 'audio_service.dart';
import 'cue.dart';
import 'game_sounds.dart';
import 'typing_voice.dart';

/// [GameSounds] on [AudioService]: what each moment of the mission player sounds like.
class AudioGameSounds implements GameSounds {
  AudioGameSounds({required this._audio, required this._ticker});

  final AudioService _audio;
  final TypingTicker _ticker;

  // Typing ticks still sounding, so a tap-to-complete can cut them off at once.
  final List<AudioVoice> _typing = [];
  static const int _typingVoicesKept = 4;

  // Sounds scheduled for later (the count-up, the elevator, the title's room tone), so
  // stopAll() and a repeat of the same moment can cancel them.
  final List<Timer> _countUp = [];
  final List<Timer> _scheduled = [];

  // The stamp is followed by a short count-up of ticks as the score's number rolls.
  static const Duration countUpDelay = Duration(milliseconds: 140);
  static const Duration countUpStep = Duration(milliseconds: 55);
  static const int countUpTicks = 5;
  static const double countUpGainFloor = 0.55;

  /// The title sting plays alone for this long before the lobby's room tone fades in under it.
  static const Duration titleRoomToneDelay = Duration(milliseconds: 4500);

  /// The ride between floors: (time from the start, cue).
  static const List<(Duration, Cue)> elevatorSequence = [
    (Duration.zero, Cue.elevatorDoorsClose),
    (Duration(milliseconds: 900), Cue.elevatorRide),
    (Duration(milliseconds: 1600), Cue.elevatorFloorTick),
    (Duration(milliseconds: 2200), Cue.elevatorFloorTick),
    (Duration(milliseconds: 2800), Cue.elevatorFloorTick),
    (Duration(milliseconds: 3900), Cue.elevatorChime),
    (Duration(milliseconds: 4600), Cue.elevatorDoorsOpen),
  ];

  /// The lobby: the room tone of the title, the tower and Chapter 1.
  static const int _lobbyChapter = 1;

  @override
  void subtitleCharacter(String interviewerId, String character) {
    final tick = _ticker.onCharacter(
      TypingVoice.forInterviewer(interviewerId),
      character,
    );
    if (tick == null) return;
    final voice = _audio.play(tick.cue, gain: tick.gain, speed: tick.speed);
    if (voice == null) return;
    _typing.add(voice);
    if (_typing.length > _typingVoicesKept) _typing.removeAt(0);
  }

  @override
  void subtitleCompleted() {
    _ticker.reset();
    _typing
      ..forEach(_audio.stop)
      ..clear();
  }

  @override
  void questionLands() {
    _audio
      ..play(Cue.questionLands)
      ..duck();
  }

  @override
  void choiceTapped() => _audio.play(Cue.choiceTap);

  /// The commitment: the card thud, then the room comes back up for the reaction.
  @override
  void answerLocked() {
    _audio
      ..play(Cue.answerLocked)
      ..unduck();
  }

  /// A follow-up is a new question: the room ducks again.
  @override
  void followUpChallenge(String interviewerId) {
    final sharp = TypingVoice.forInterviewer(interviewerId) == TypingVoice.lena;
    _audio
      ..play(sharp ? Cue.followUpSharp : Cue.followUp)
      ..duck();
  }

  @override
  void trustChanged({required bool rising}) =>
      _audio.play(rising ? Cue.trustUp : Cue.trustDown);

  /// Only ever called by timed missions (the contract), so Mission 1 never hears it.
  @override
  void timerPulse({required bool finalSeconds}) =>
      _audio.play(finalSeconds ? Cue.timerTick : Cue.timerPulse);

  @override
  void dossierSlides() {
    _audio
      ..unduck()
      ..play(Cue.dossierSlide);
  }

  @override
  void scoreStamped() {
    _audio.play(Cue.stamp);
    _cancelCountUp();
    for (var i = 0; i < countUpTicks; i++) {
      final gain = 1 - (1 - countUpGainFloor) * i / (countUpTicks - 1);
      _countUp.add(
        Timer(
          countUpDelay + countUpStep * i,
          () => _audio.play(Cue.countTick, gain: gain),
        ),
      );
    }
  }

  @override
  void result({required bool strong}) {
    _audio
      ..unduck()
      ..play(strong ? Cue.resultStrong : Cue.resultWeak);
  }

  @override
  void chapterCard(int chapter) => _audio.play(Cue.chapterCard);

  @override
  void ambience(int chapter) => _audio.startAmbience(chapter);

  /// The sting first; the lobby comes in under its tail, unless a scene has already asked for a
  /// room of its own by then.
  @override
  void titleOpened() {
    _cancelScheduled();
    _audio.play(Cue.titleOpen);
    _scheduled.add(
      Timer(titleRoomToneDelay, () {
        if (_audio.currentLoop == null) _audio.startAmbience(_lobbyChapter);
      }),
    );
  }

  @override
  void uiTap() => _audio.play(Cue.choiceTap);

  @override
  void pageTurn() => _audio.play(Cue.pageTurn);

  @override
  void towerOpened() => _audio.startAmbience(_lobbyChapter);

  @override
  void roomEntered() => _audio.play(Cue.roomEnter);

  @override
  void elevator() {
    _cancelScheduled();
    for (final (at, cue) in elevatorSequence) {
      _scheduled.add(Timer(at, () => _audio.play(cue)));
    }
  }

  @override
  void lockedRoomTapped() => _audio.play(Cue.lockedFloor);

  @override
  void skillUnlocked() => _audio.play(Cue.skillUnlocked);

  @override
  void stopAll() {
    _ticker.reset();
    _typing.clear();
    _cancelCountUp();
    _cancelScheduled();
    _audio.stopAll();
  }

  void _cancelScheduled() {
    for (final timer in _scheduled) {
      timer.cancel();
    }
    _scheduled.clear();
  }

  void _cancelCountUp() {
    for (final timer in _countUp) {
      timer.cancel();
    }
    _countUp.clear();
  }
}
