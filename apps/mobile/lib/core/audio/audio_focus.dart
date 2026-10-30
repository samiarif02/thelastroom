import 'package:audio_session/audio_session.dart';

import '../logging/log.dart';
import 'audio_service.dart';

/// The platform audio session, set once before the engine starts. The only file that imports
/// `audio_session`.
///
/// - **iOS:** `ambient`: the silent switch mutes the game and the player's own music keeps
///   playing under it. SoLoud never touches `AVAudioSession`, so this is the whole setup.
/// - **Android:** the game holds audio focus (`gain`, the default) like any game (the player's music pauses), so it
///   hears when something else needs the speaker: a notification sound ducks it, a call or a
///   voice assistant silences it until focus comes back.
const AudioSessionConfiguration gameAudioSession = AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.ambient,
  avAudioSessionMode: AVAudioSessionMode.defaultMode,
  androidAudioAttributes: AndroidAudioAttributes(
    contentType: AndroidAudioContentType.sonification,
    usage: AndroidAudioUsage.game,
  ),
  androidWillPauseWhenDucked: false,
);

/// Configures and activates the session and forwards interruptions to [audio]. Never throws:
/// without a session the game still plays, it just won't duck for other apps.
Future<void> followAudioFocus(AudioService audio, Log log) async {
  try {
    final session = await AudioSession.instance;
    await session.configure(gameAudioSession);
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        audio.interruptionBegan(duck: event.type == AudioInterruptionType.duck);
      } else {
        audio.interruptionEnded();
      }
    });
    await session.setActive(true);
  } on Object catch (e) {
    log.warn('audio session not configured', {
      'error': e.runtimeType.toString(),
    });
  }
}
