import 'dart:typed_data';

import 'package:record/record.dart';

import 'microphone.dart';
import 'pcm.dart';

/// [Microphone] on the `record` package. The only file that imports it.
///
/// It streams raw PCM rather than writing a file, on every platform (web included): the take
/// lives in memory, is never written to disk, and is gone once the debrief is over (brief 35's
/// privacy rule). Continue opens a new stream and the recorder appends to the same take.
class RecordMicrophone implements Microphone {
  RecordMicrophone([AudioRecorder? recorder])
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: VoicePcm.sampleRate,
    numChannels: VoicePcm.channels,
    // The phone's own noise suppression helps the transcript; the level check is ours.
    noiseSuppress: true,
    echoCancel: true,
  );

  @override
  Future<bool> hasAccess() => _recorder.hasPermission(request: false);

  @override
  Future<MicAccess> ask() async =>
      await _recorder.hasPermission() ? MicAccess.granted : MicAccess.denied;

  @override
  Future<Stream<Uint8List>> open() => _recorder.startStream(_config);

  @override
  Future<void> close() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
