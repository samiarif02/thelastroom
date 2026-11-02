import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every sound moment the game has, as calls a screen makes: a screen says *what happened*,
/// never which file to play.
///
/// The contract between brief 10 (the mission player, which calls these) and brief 09 (sound,
/// which implements them on `AudioService`). It's written once by the lead and committed
/// identically on both branches; change a signature only through the lead. Adding a method is
/// fine, with a no-op in [SilentGameSounds].
///
/// Every method returns immediately and never throws: sound is optional (ADR 0005).
abstract interface class GameSounds {
  /// One character of an interviewer's subtitle appeared. The implementation decides which
  /// characters tick (throttling, silence on spaces and punctuation).
  void subtitleCharacter(String interviewerId, String character);

  /// The player tapped to complete the line: stop any typing sound now.
  void subtitleCompleted();

  /// The question lands on the camera cut (suspense; ambience ducks).
  void questionLands();

  /// The player focused or picked an answer card.
  void choiceTapped();

  /// An answer is locked in.
  void answerLocked();

  /// The interviewer's follow-up challenge lands.
  void followUpChallenge(String interviewerId);

  /// The trust meter moved after a pick.
  void trustChanged({required bool rising});

  /// The timer's last stretch, for timed missions only (never called when a mission is untimed).
  void timerPulse({required bool finalSeconds});

  /// The debrief dossier slides in.
  void dossierSlides();

  /// One score is stamped on the dossier.
  void scoreStamped();

  /// The mission result: strong or weak (never a fail sound).
  void result({required bool strong});

  /// A chapter title card is shown (1-based chapter number).
  void chapterCard(int chapter);

  /// The room tone for a chapter starts, cross-fading from the previous one.
  void ambience(int chapter);

  /// The app opened on the title: the title sting, then the lobby's room tone.
  void titleOpened();

  /// A button or "continue" was tapped outside the interview.
  void uiTap();

  /// An intro or character card turned.
  void pageTurn();

  /// The tower (chapter map) opened: the lobby's room tone comes in.
  void towerOpened();

  /// The player walked into a mission room.
  void roomEntered();

  /// The elevator ride between floors.
  void elevator();

  /// The player tapped a locked room: its sound, heard through the door.
  void lockedRoomTapped();

  /// A skill unlocked (brief 32): a glassy rising shimmer and a soft bell.
  void skillUnlocked();

  /// Every sound stops (leaving the scene, app paused).
  void stopAll();
}

/// The default until brief 09 overrides [gameSoundsProvider]: the game plays in silence.
class SilentGameSounds implements GameSounds {
  const SilentGameSounds();

  @override
  void subtitleCharacter(String interviewerId, String character) {}

  @override
  void subtitleCompleted() {}

  @override
  void questionLands() {}

  @override
  void choiceTapped() {}

  @override
  void answerLocked() {}

  @override
  void followUpChallenge(String interviewerId) {}

  @override
  void trustChanged({required bool rising}) {}

  @override
  void timerPulse({required bool finalSeconds}) {}

  @override
  void dossierSlides() {}

  @override
  void scoreStamped() {}

  @override
  void result({required bool strong}) {}

  @override
  void chapterCard(int chapter) {}

  @override
  void ambience(int chapter) {}

  @override
  void titleOpened() {}

  @override
  void uiTap() {}

  @override
  void pageTurn() {}

  @override
  void towerOpened() {}

  @override
  void roomEntered() {}

  @override
  void elevator() {}

  @override
  void lockedRoomTapped() {}

  @override
  void skillUnlocked() {}

  @override
  void stopAll() {}
}

/// The game's sounds. Brief 09 overrides this with its `AudioService`-backed implementation.
final gameSoundsProvider = Provider<GameSounds>(
  (ref) => const SilentGameSounds(),
);
