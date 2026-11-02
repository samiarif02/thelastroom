import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'audio/microphone.dart';
import 'audio/record_microphone.dart';
import 'audio/soloud_take_playback.dart';
import 'audio/take_playback.dart';
import 'speech/interviewer_voice.dart';
import 'speech/tts_interviewer_voice.dart';

/// A new microphone for each recorder (each take is its own recorder, disposed with it). Tests
/// override it with a fake that plays an amplitude script.
final microphoneFactoryProvider = Provider<Microphone Function()>(
  (ref) => RecordMicrophone.new,
);

/// The interviewers' spoken voice. Tests override it with [SilentInterviewerVoice].
final interviewerVoiceProvider = Provider<InterviewerVoice>((ref) {
  final voice = TtsInterviewerVoice(log: ref.watch(logProvider));
  ref.onDispose(() => unawaited(voice.stop()));
  return voice;
});

/// Listening back to a take on the self-check. Tests override it with [SilentTakePlayback].
final takePlaybackProvider = Provider<TakePlayback>((ref) {
  final playback = SoloudTakePlayback(log: ref.watch(logProvider));
  ref.onDispose(() => unawaited(playback.stop()));
  return playback;
});

/// The mute toggle on a voice mission: the lines are still subtitled, just not spoken. Kept for
/// the session.
final interviewerMutedProvider = NotifierProvider<InterviewerMuted, bool>(
  InterviewerMuted.new,
);

class InterviewerMuted extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
