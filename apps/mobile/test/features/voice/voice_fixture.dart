import 'dart:async';
import 'dart:typed_data';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:the_last_room/features/voice/audio/microphone.dart';
import 'package:the_last_room/features/voice/audio/pcm.dart';
import 'package:the_last_room/features/voice/speech/interviewer_voice.dart';

/// A small voice mission, until brief 37's Chapter 2 lands: three points for the question, one
/// for the follow-up, a real lesson and real interviewers. It passes `validateContent`.
const Mission voiceFixture = Mission(
  id: 'm08_voice_fixture',
  chapter: 2,
  number: 8,
  title: 'The Plan That Changed',
  practises: 'Telling a story about change out loud, with your own part in it',
  scene: [
    SceneLine(
      speakerId: marcusId,
      text: 'Jordan, thanks for coming back for round two.',
    ),
  ],
  question: SceneLine(
    speakerId: marcusId,
    text: 'Tell me about a time a plan changed under you.',
  ),
  beats: [],
  followUps: [],
  hinted: true,
  answerMode: AnswerMode.voice,
  voice: VoicePrompt(
    listenFor: [
      ListenFor(
        id: 'm08_names_change',
        text: 'Names what changed and when',
        dimension: Dimension.relevance,
      ),
      ListenFor(
        id: 'm08_own_part',
        text: 'Says what you did, not what the team did',
        dimension: Dimension.specificity,
      ),
      ListenFor(
        id: 'm08_result',
        text: 'Lands on a result, with a number',
        dimension: Dimension.structure,
      ),
    ],
    followUp: SceneLine(
      speakerId: marcusId,
      text: 'And what would you do differently?',
    ),
    followUpListenFor: [
      ListenFor(
        id: 'm08_owns_it',
        text: 'Names one thing you would change',
        dimension: Dimension.adaptability,
      ),
    ],
    lessonId: 'lesson_answer_the_question',
    maxSeconds: 30,
  ),
);

/// Every point id, the question's then the follow-up's.
const List<String> fixturePoints = [
  'm08_names_change',
  'm08_own_part',
  'm08_result',
  'm08_owns_it',
];

/// How long each fake chunk of audio runs: 100 ms, like a phone's stream.
const Duration chunk = Duration(milliseconds: 100);

/// 100 ms of PCM at a steady [amplitude] (0 is digital silence; 8000 is a clear voice, about
/// -12 dBFS).
Uint8List pcmChunk(int amplitude) {
  final bytes = Uint8List(VoicePcm.bytesFor(chunk));
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < bytes.length ~/ VoicePcm.bytesPerSample; i++) {
    // A square wave: its RMS is exactly [amplitude].
    data.setInt16(
      i * VoicePcm.bytesPerSample,
      i.isEven ? amplitude : -amplitude,
      Endian.little,
    );
  }
  return bytes;
}

const int speech = 8000;
const int quiet = 20;

/// A microphone whose audio each test feeds by hand: [speak] and [hush] push chunks into the
/// open stream. [access] is what the platform answers.
class FakeMicrophone implements Microphone {
  FakeMicrophone({this.granted = true, this.alreadyAllowed = true});

  bool granted;
  bool alreadyAllowed;
  bool failOpen = false;
  StreamController<Uint8List>? _open;
  int opened = 0;
  int closed = 0;
  bool disposed = false;
  int asked = 0;

  bool get isOpen => _open != null;

  @override
  Future<bool> hasAccess() async => alreadyAllowed;

  @override
  Future<MicAccess> ask() async {
    asked++;
    return granted ? MicAccess.granted : MicAccess.denied;
  }

  @override
  Future<Stream<Uint8List>> open() async {
    if (failOpen) throw StateError('no input device');
    opened++;
    // Closed in [close], as the real microphone's stream is when it stops.
    _open = StreamController<Uint8List>(sync: true);
    return _open!.stream;
  }

  @override
  Future<void> close() async {
    if (_open == null) return;
    closed++;
    // Not awaited: a cancelled stream's close completes on its own schedule, and the real
    // recorder doesn't wait for it either.
    unawaited(_open?.close());
    _open = null;
  }

  @override
  Future<void> dispose() async => disposed = true;

  /// Feeds [length] of a clear voice.
  void speak(Duration length) => _feed(speech, length);

  /// Feeds [length] of a quiet room.
  void hush(Duration length) => _feed(quiet, length);

  void _feed(int amplitude, Duration length) {
    for (var t = Duration.zero; t < length; t += chunk) {
      final c = _open;
      if (c == null) return;
      c.add(pcmChunk(amplitude));
    }
  }
}

/// Records every line it was asked to say; says it at once.
class RecordingVoice implements InterviewerVoice {
  final List<String> said = [];
  int stops = 0;

  @override
  Future<void> say(SceneLine line) async => said.add(line.text);

  @override
  Future<void> stop() async => stops++;
}
