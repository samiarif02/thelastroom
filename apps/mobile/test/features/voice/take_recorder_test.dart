import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/voice/audio/pcm.dart';
import 'package:the_last_room/features/voice/recorder/take_recorder.dart';

import 'voice_fixture.dart';

Future<TakeRecorder> recorderWith(
  FakeMicrophone mic, {
  Duration max = const Duration(seconds: 30),
}) async {
  final r = TakeRecorder(microphone: mic, maxLength: max);
  addTearDown(r.dispose);
  await r.start();
  return r;
}

/// The PCM samples of [take] (its WAV minus the 44-byte header).
Uint8List samplesOf(Take take) => take.wav.sublist(44);

void main() {
  group('permission', () {
    test('already allowed: straight to an empty recorder', () async {
      final r = await recorderWith(FakeMicrophone());
      expect(r.phase, RecorderPhase.empty);
    });

    test(
      'not yet allowed: the explainer, then the OS dialog, then the recorder',
      () async {
        final mic = FakeMicrophone(alreadyAllowed: false);
        final r = await recorderWith(mic);
        expect(r.phase, RecorderPhase.explain);
        expect(mic.asked, 0, reason: 'never asked before the explainer');
        final asking = r.allow();
        expect(r.phase, RecorderPhase.asking);
        await asking;
        expect(r.phase, RecorderPhase.empty);
        expect(mic.asked, 1);
      },
    );

    test('refused: the designed refused state', () async {
      final r = await recorderWith(
        FakeMicrophone(alreadyAllowed: false, granted: false),
      );
      await r.allow();
      expect(r.phase, RecorderPhase.denied);
    });

    test(
      'a microphone that fails to open is the refused state, never an error',
      () async {
        final mic = FakeMicrophone()..failOpen = true;
        final r = await recorderWith(mic);
        await r.toggle();
        expect(r.phase, RecorderPhase.denied);
      },
    );
  });

  group('recording', () {
    test('the elapsed time and the level come from the audio', () async {
      final mic = FakeMicrophone();
      final r = await recorderWith(mic);
      await r.toggle();
      expect(r.phase, RecorderPhase.recording);
      mic.speak(const Duration(seconds: 2));
      expect(r.elapsed, const Duration(seconds: 2));
      expect(r.level, greaterThan(0.9));
      mic.hush(const Duration(milliseconds: 100));
      expect(r.level, 0);
    });

    test('5 s of quiet pauses the take by itself, and says why', () async {
      final mic = FakeMicrophone();
      final r = await recorderWith(mic);
      await r.toggle();
      mic.speak(const Duration(seconds: 3));
      mic.hush(const Duration(milliseconds: 4900));
      expect(r.phase, RecorderPhase.recording);
      mic.hush(const Duration(milliseconds: 100));
      expect(r.phase, RecorderPhase.paused);
      expect(r.pauseReason, PauseReason.silence);
      expect(r.pausedCount, 1);
      await pumpEventQueue();
      expect(
        mic.isOpen,
        isFalse,
        reason: 'the microphone is closed while paused',
      );
    });

    test('Continue appends to the same take, from where it paused', () async {
      final mic = FakeMicrophone();
      final r = await recorderWith(mic);
      await r.toggle();
      mic.speak(const Duration(seconds: 2));
      mic.hush(const Duration(seconds: 5));
      expect(r.phase, RecorderPhase.paused);
      await r.resume();
      expect(r.phase, RecorderPhase.recording);
      expect(mic.opened, 2);
      mic.speak(const Duration(seconds: 1));
      expect(r.elapsed, const Duration(seconds: 8));
      final take = (await r.submit())!;
      expect(take.length, const Duration(seconds: 8));
      expect(samplesOf(take), hasLength(VoicePcm.bytesFor(take.length)));
      // The second stretch follows the first: the last second is speech.
      expect(
        VoicePcm.levelDbfs(
          Uint8List.sublistView(
            samplesOf(take),
            VoicePcm.bytesFor(const Duration(seconds: 7)),
          ),
        ),
        greaterThan(-20),
      );
    });

    test(
      'the record button pauses a take, and the next tap continues it',
      () async {
        final mic = FakeMicrophone();
        final r = await recorderWith(mic);
        await r.toggle();
        mic.speak(const Duration(seconds: 1));
        await r.toggle();
        expect(r.phase, RecorderPhase.paused);
        expect(r.pauseReason, PauseReason.player);
        await r.toggle();
        expect(r.phase, RecorderPhase.recording);
        mic.speak(const Duration(seconds: 1));
        expect(r.elapsed, const Duration(seconds: 2));
        expect(r.pausedCount, 1);
      },
    );

    test('the cap stops the take at exactly maxSeconds', () async {
      final mic = FakeMicrophone();
      final r = await recorderWith(mic, max: const Duration(seconds: 10));
      await r.toggle();
      mic.speak(const Duration(seconds: 12));
      expect(r.phase, RecorderPhase.full);
      expect(r.elapsed, const Duration(seconds: 10));
      await r.resume();
      expect(
        r.phase,
        RecorderPhase.full,
        reason: 'a full take can only be sent or deleted',
      );
      final take = (await r.submit())!;
      expect(take.seconds, 10);
    });

    test('a take under a second cannot be submitted', () async {
      final mic = FakeMicrophone();
      final r = await recorderWith(mic);
      await r.toggle();
      mic.speak(const Duration(milliseconds: 500));
      expect(r.canSubmit, isFalse);
      expect(await r.submit(), isNull);
      mic.speak(const Duration(milliseconds: 500));
      expect(r.canSubmit, isTrue);
    });
  });

  group('delete', () {
    test('asks first; Keep it leaves the take alone', () async {
      final mic = FakeMicrophone();
      final r = await recorderWith(mic);
      await r.toggle();
      mic.speak(const Duration(seconds: 2));
      await r.askDelete();
      expect(r.confirmingDelete, isTrue);
      expect(
        r.phase,
        RecorderPhase.paused,
        reason: 'recording pauses while you decide',
      );
      r.cancelDelete();
      expect(r.confirmingDelete, isFalse);
      expect(r.elapsed, const Duration(seconds: 2));
    });

    test(
      'confirmed, the take is thrown away and the recorder is empty again',
      () async {
        final mic = FakeMicrophone();
        final r = await recorderWith(mic);
        await r.toggle();
        mic.speak(const Duration(seconds: 2));
        await r.askDelete();
        await r.confirmDelete();
        expect(r.phase, RecorderPhase.empty);
        expect(r.elapsed, Duration.zero);
        expect(r.hasTake, isFalse);
        expect(r.retakes, 1);
        await r.toggle();
        mic.speak(const Duration(seconds: 1));
        final take = (await r.submit())!;
        expect(
          take.length,
          const Duration(seconds: 1),
          reason: 'the new take starts from zero',
        );
        expect(take.retakes, 1);
      },
    );

    test('nothing to delete on an empty recorder', () async {
      final r = await recorderWith(FakeMicrophone());
      await r.askDelete();
      expect(r.confirmingDelete, isFalse);
    });
  });

  test('disposing closes and releases the microphone', () async {
    final mic = FakeMicrophone();
    final r = TakeRecorder(
      microphone: mic,
      maxLength: const Duration(seconds: 5),
    );
    await r.start();
    await r.toggle();
    r.dispose();
    await pumpEventQueue();
    expect(mic.isOpen, isFalse);
    expect(mic.disposed, isTrue);
  });
}
