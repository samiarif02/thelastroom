import 'package:flutter/foundation.dart';

/// Which volume a cue follows: the Effects slider, or the Ambience/Music one.
enum CueBus { effects, ambience }

/// Every sound the game has (the cue sheet in `docs/sound-design.md`). Widgets and screens name
/// a [Cue], never a file: the file is [asset] in the platform's [CueFormat].
///
/// [asset] must match a recipe in `tools/audio/cues.py` and a row in `docs/audio-credits.md`
/// (tested in `cue_assets_test.dart`).
enum Cue {
  // Subtitle typing: one muted key per interviewer (see TypingVoice).
  typePriya('type_priya'),
  typeMarcus('type_marcus'),
  typeLena('type_lena'),
  typeSam('type_sam'),

  // Title, chapters, cliffhanger: music-like, so they follow the Ambience/Music volume.
  titleOpen('title_open', bus: CueBus.ambience),
  chapterCard('chapter_card', bus: CueBus.ambience),
  cliffhanger('cliffhanger', bus: CueBus.ambience),

  // The elevator between missions, in the order it plays.
  elevatorDoorsClose('elevator_doors_close'),
  elevatorRide('elevator_ride'),
  elevatorFloorTick('elevator_floor_tick'),
  elevatorChime('elevator_chime'),
  elevatorDoorsOpen('elevator_doors_open'),

  // Room tone, one loop per chapter, and the Recall Room's pad.
  ambienceLobby('ambience_lobby', bus: CueBus.ambience, loops: true),
  ambienceCorridor('ambience_corridor', bus: CueBus.ambience, loops: true),
  ambienceBoardroom('ambience_boardroom', bus: CueBus.ambience, loops: true),
  recallPad('recall_pad', bus: CueBus.ambience, loops: true),

  /// A locked floor tapped on the tower: the next chapter's room, through the door.
  lockedFloor('locked_floor', bus: CueBus.ambience),

  // The interview.
  questionLands('question_lands'),

  /// Timed missions only: never part of Mission 1, which is untimed.
  timerPulse('timer_pulse'),

  /// Timed missions only, in the last 10 seconds.
  timerTick('timer_tick'),
  choiceTap('choice_tap'),
  answerLocked('answer_locked'),
  followUp('follow_up'),

  /// Lena's follow-up: the same pulse, sharper.
  followUpSharp('follow_up_sharp'),
  trustUp('trust_up'),
  trustDown('trust_down'),

  // The debrief.
  dossierSlide('dossier_slide'),
  stamp('stamp'),
  countTick('count_tick'),
  resultStrong('result_strong'),

  /// "Try again" energy, never a fail buzzer.
  resultWeak('result_weak'),
  skillUnlocked('unlock_shimmer');

  const Cue(this.asset, {this.bus = CueBus.effects, this.loops = false});

  /// The file's base name, shared by every format.
  final String asset;
  final CueBus bus;

  /// Room tone: plays until stopped, cross-fading into the next one.
  final bool loops;

  /// The bundled file for this cue in [format].
  String assetPath(CueFormat format) =>
      'assets/audio/${format.name}/$asset.${format.name}';
}

/// The two encodings the library ships: OGG Vorbis (Android, web, desktop) and M4A AAC (Apple,
/// decoded natively by AudioToolbox).
enum CueFormat {
  ogg,
  m4a;

  static CueFormat forPlatform({
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    if (isWeb) return ogg;
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => m4a,
      _ => ogg,
    };
  }
}
