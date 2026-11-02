import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/voice/audio/pcm.dart';
import 'package:the_last_room/features/voice/audio/silence_detector.dart';

import 'voice_fixture.dart';

/// A fake amplitude stream: [seconds] of samples at [dbfs], 100 ms each.
Iterable<LevelSample> levels(double dbfs, double seconds) sync* {
  for (var t = 0.0; t < seconds - 1e-9; t += 0.1) {
    yield LevelSample(dbfs: dbfs, length: chunk);
  }
}

const double loud = -15;
const double hush = -60;

void main() {
  group('SilenceDetector', () {
    test(
      '5 s below the threshold fires once, on the sample that reaches 5 s',
      () {
        final d = SilenceDetector();
        final fired = [for (final s in levels(hush, 7)) d.add(s)];
        expect(fired.where((f) => f), hasLength(1));
        expect(
          fired.indexOf(true),
          49,
          reason: 'the 50th 100 ms sample is 5.0 s',
        );
        expect(d.quiet, const Duration(seconds: 7));
      },
    );

    test('4.9 s of quiet does not pause', () {
      final d = SilenceDetector();
      expect([
        for (final s in levels(hush, 4.9)) d.add(s),
      ], everyElement(isFalse));
    });

    test('speech in between starts the count again', () {
      final d = SilenceDetector();
      final fired = [
        for (final s in [
          ...levels(hush, 4),
          ...levels(loud, 0.1),
          ...levels(hush, 4),
          ...levels(loud, 1),
          ...levels(hush, 5),
        ])
          d.add(s),
      ];
      expect(fired.where((f) => f), hasLength(1));
      expect(fired.last, isTrue, reason: 'only the last full 5 s pauses');
    });

    test('a level exactly at the threshold counts as sound', () {
      final d = SilenceDetector();
      expect([
        for (final s in levels(SilenceDetector.defaultThreshold, 6)) d.add(s),
      ], everyElement(isFalse));
    });

    test('after firing it fires again only after sound and another 5 s', () {
      final d = SilenceDetector();
      final fired = [
        for (final s in [
          ...levels(hush, 10),
          ...levels(loud, 0.5),
          ...levels(hush, 5),
        ])
          d.add(s),
      ];
      expect(fired.where((f) => f), hasLength(2));
    });

    test('reset forgets the quiet so far (a take resumed)', () {
      final d = SilenceDetector();
      for (final s in levels(hush, 4)) {
        d.add(s);
      }
      d.reset();
      expect([
        for (final s in levels(hush, 4)) d.add(s),
      ], everyElement(isFalse));
    });

    test(
      'it counts audio time, not samples: long samples reach 5 s sooner',
      () {
        final d = SilenceDetector();
        const long = LevelSample(dbfs: hush, length: Duration(seconds: 2));
        expect([d.add(long), d.add(long), d.add(long)], [false, false, true]);
      },
    );

    test(
      'watch turns a fake amplitude stream into one event per silence',
      () async {
        final d = SilenceDetector();
        final events = await d
            .watch(
              Stream.fromIterable([
                ...levels(loud, 2),
                ...levels(hush, 6),
                ...levels(loud, 1),
                ...levels(hush, 3),
              ]),
            )
            .length;
        expect(events, 1);
      },
    );

    test('a custom window and threshold', () {
      final d = SilenceDetector(
        threshold: -30,
        window: const Duration(seconds: 1),
      );
      expect([for (final s in levels(-35, 1)) d.add(s)].last, isTrue);
    });
  });

  group('VoicePcm', () {
    test(
      'a square wave of amplitude A has an RMS level of 20·log10(A / 32768)',
      () {
        expect(VoicePcm.levelDbfs(pcmChunk(speech)), closeTo(-12.25, 0.01));
        expect(VoicePcm.levelDbfs(pcmChunk(quiet)), closeTo(-64.3, 0.1));
      },
    );

    test('digital silence and an empty chunk sit at the floor', () {
      expect(VoicePcm.levelDbfs(pcmChunk(0)), VoicePcm.floorDbfs);
      expect(VoicePcm.levelDbfs(Uint8List(0)), VoicePcm.floorDbfs);
    });

    test('durations and byte counts agree at 16 kHz mono 16-bit', () {
      expect(VoicePcm.byteRate, 32000);
      expect(VoicePcm.durationOf(32000), const Duration(seconds: 1));
      expect(VoicePcm.bytesFor(const Duration(milliseconds: 100)), 3200);
      expect(VoicePcm.bytesFor(const Duration(microseconds: 31)), 0);
    });

    test('wav wraps PCM in a 44-byte RIFF header Gemini reads', () {
      final pcm = pcmChunk(speech);
      final wav = VoicePcm.wav(pcm);
      final h = ByteData.sublistView(wav);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
      expect(h.getUint32(4, Endian.little), 36 + pcm.length);
      expect(h.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(h.getUint32(24, Endian.little), 16000);
      expect(h.getUint32(28, Endian.little), 32000);
      expect(h.getUint32(40, Endian.little), pcm.length);
      expect(wav.sublist(44), pcm);
    });
  });
}
