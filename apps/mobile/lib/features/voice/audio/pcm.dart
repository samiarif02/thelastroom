import 'dart:math' as math;
import 'dart:typed_data';

/// The recorder's format on every platform: 16 kHz mono 16-bit PCM, little-endian. Speech
/// recognition needs no more, and 90 seconds stays under 3 MB, small enough to send for scoring.
abstract final class VoicePcm {
  static const int sampleRate = 16000;
  static const int channels = 1;
  static const int bytesPerSample = 2;
  static const int bitsPerSample = bytesPerSample * 8;

  /// Bytes per second of audio.
  static const int byteRate = sampleRate * channels * bytesPerSample;

  /// The level of digital silence (no samples, or all zeros), below any threshold.
  static const double floorDbfs = -100;

  /// The level a full-scale square wave reaches.
  static const double fullScale = 32768;

  /// How long [bytes] of PCM play for.
  static Duration durationOf(int bytes) => Duration(
    microseconds: bytes * Duration.microsecondsPerSecond ~/ byteRate,
  );

  /// How many bytes play for [duration], rounded down to a whole sample.
  static int bytesFor(Duration duration) {
    final bytes =
        duration.inMicroseconds * byteRate ~/ Duration.microsecondsPerSecond;
    return bytes - bytes % bytesPerSample;
  }

  /// The RMS level of [pcm] in dBFS (0 is full scale, about -20 is speech near the phone,
  /// -50 a quiet room). An odd trailing byte is ignored.
  static double levelDbfs(Uint8List pcm) {
    final samples = pcm.length ~/ bytesPerSample;
    if (samples == 0) return floorDbfs;
    final data = ByteData.sublistView(pcm);
    var sum = 0.0;
    for (var i = 0; i < samples; i++) {
      final s = data.getInt16(i * bytesPerSample, Endian.little);
      sum += s * s;
    }
    final rms = math.sqrt(sum / samples);
    if (rms == 0) return floorDbfs;
    final db = 20 * math.log(rms / fullScale) / math.ln10;
    return math.max(db, floorDbfs);
  }

  static const int _wavHeader = 44;
  static const int _fmtChunk = 16;
  static const int _pcmFormat = 1;

  /// [pcm] as a WAV file: the 44-byte RIFF header, then the samples. Gemini reads `audio/wav`
  /// directly, and so does the take player.
  static Uint8List wav(Uint8List pcm) {
    final out = Uint8List(_wavHeader + pcm.length);
    final h = ByteData.sublistView(out);
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        h.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    h.setUint32(4, _wavHeader - 8 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    h.setUint32(16, _fmtChunk, Endian.little);
    h.setUint16(20, _pcmFormat, Endian.little);
    h.setUint16(22, channels, Endian.little);
    h.setUint32(24, sampleRate, Endian.little);
    h.setUint32(28, byteRate, Endian.little);
    h.setUint16(32, channels * bytesPerSample, Endian.little);
    h.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);
    out.setRange(_wavHeader, out.length, pcm);
    return out;
  }
}
