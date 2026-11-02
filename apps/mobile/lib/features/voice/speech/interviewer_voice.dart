import 'package:content/content.dart';

/// The interviewers' spoken voice on a voice mission (brief 35): each line is read aloud as its
/// subtitle types. Subtitles are always on, so a device without text to speech simply plays
/// silent, never an error. `TtsInterviewerVoice` in the app, [SilentInterviewerVoice] in tests
/// and when muted.
abstract interface class InterviewerVoice {
  /// Says [line] in its speaker's voice. Completes when it's finished (or failed); never throws.
  Future<void> say(SceneLine line);

  /// Stops whatever is being said.
  Future<void> stop();
}

/// Says nothing, at once: the muted voice, and the voice in tests.
class SilentInterviewerVoice implements InterviewerVoice {
  const SilentInterviewerVoice();

  @override
  Future<void> say(SceneLine line) async {}

  @override
  Future<void> stop() async {}
}

/// How each interviewer sounds: a pitch around the engine's default (1), so the panel aren't
/// one voice. Unknown speakers keep the default.
abstract final class InterviewerPitch {
  static const double neutral = 1;

  static const Map<String, double> bySpeaker = {
    priyaId: 1.08,
    marcusId: 0.86,
    lenaId: 1.02,
    samId: 0.94,
  };

  static double of(String speakerId) => bySpeaker[speakerId] ?? neutral;
}
