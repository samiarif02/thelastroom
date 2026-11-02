import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/voice/audio/microphone.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/features/voice/recorder/take_recorder.dart';

import 'voice_fixture.dart';

/// The recorder as it sits in the lower third of a phone, with the delete sheet over it.
Future<void> pumpPanel(
  WidgetTester tester,
  TakeRecorder recorder, {
  double scale = 1,
  bool still = false,
  ValueChanged<Take>? onDone,
  VoidCallback? onWithoutMicrophone,
}) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(scale),
        disableAnimations: still,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: BrandType.body,
          child: ListenableBuilder(
            listenable: recorder,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: BrandVivid.night),
                Positioned(
                  left: BrandSpace.md,
                  right: BrandSpace.md,
                  bottom: BrandSpace.sm,
                  top: size.height / 3,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: RecorderPanel(
                      recorder: recorder,
                      onDone: onDone ?? (_) {},
                      onWithoutMicrophone: onWithoutMicrophone ?? () {},
                    ),
                  ),
                ),
                if (recorder.confirmingDelete)
                  DeleteTakeSheet(recorder: recorder),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A recorder brought to a state, by the same steps a player would take.
typedef Arrange = Future<void> Function(TakeRecorder r, FakeMicrophone mic);

final Map<String, (Arrange, FakeMicrophone Function(), String)> states = {
  'explain (permission not asked yet)': (
    (r, mic) async {},
    () => FakeMicrophone(alreadyAllowed: false),
    RecorderPanel.allow,
  ),
  'asking (the OS dialog is up)': (
    (r, mic) async {
      // The dialog never answers while the test looks at it.
      r.allow().ignore();
    },
    _NeverAnswers.new,
    RecorderPanel.asking,
  ),
  'denied (refused)': (
    (r, mic) => r.allow(),
    () => FakeMicrophone(alreadyAllowed: false, granted: false),
    RecorderPanel.deniedAction,
  ),
  'empty (ready to record)': (
    (r, mic) async {},
    FakeMicrophone.new,
    RecorderPanel.readyLine,
  ),
  'recording': (
    (r, mic) async {
      await r.toggle();
      mic.speak(const Duration(seconds: 4));
    },
    FakeMicrophone.new,
    RecorderPanel.recordingLine,
  ),
  'paused by silence': (
    (r, mic) async {
      await r.toggle();
      mic
        ..speak(const Duration(seconds: 3))
        ..hush(const Duration(seconds: 5));
    },
    FakeMicrophone.new,
    RecorderPanel.silenceLine,
  ),
  'paused by the player': (
    (r, mic) async {
      await r.toggle();
      mic.speak(const Duration(seconds: 2));
      await r.toggle();
    },
    FakeMicrophone.new,
    RecorderPanel.pausedLine,
  ),
  'full (the cap)': (
    (r, mic) async {
      await r.toggle();
      mic.speak(const Duration(seconds: 31));
    },
    FakeMicrophone.new,
    RecorderPanel.fullLine(const Duration(seconds: 30)),
  ),
  'confirm delete': (
    (r, mic) async {
      await r.toggle();
      mic.speak(const Duration(seconds: 2));
      await r.askDelete();
    },
    FakeMicrophone.new,
    DeleteTakeSheet.title,
  ),
};

class _NeverAnswers extends FakeMicrophone {
  _NeverAnswers() : super(alreadyAllowed: false);

  final Completer<MicAccess> _never = Completer();

  @override
  Future<MicAccess> ask() => _never.future;
}

void main() {
  for (final MapEntry(key: name, value: (arrange, mic, line))
      in states.entries) {
    for (final scale in [1.0, 2.0]) {
      for (final still in [false, true]) {
        testWidgets(
          'the recorder, $name, at ${scale}x${still ? ', reduced motion' : ''}',
          (tester) async {
            final m = mic();
            final r = TakeRecorder(
              microphone: m,
              maxLength: const Duration(seconds: 30),
            );
            addTearDown(r.dispose);
            await r.start();
            await arrange(r, m);
            await pumpPanel(tester, r, scale: scale, still: still);
            expect(find.text(line), findsOneWidget);
            expect(tester.takeException(), isNull);
            // Every tappable thing is a real target.
            for (final e in find.byType(RecordButton).evaluate()) {
              expect(
                tester.getSize(find.byWidget(e.widget)).shortestSide,
                greaterThanOrEqualTo(BrandSpace.minTarget),
              );
            }
          },
        );
      }
    }
  }

  testWidgets('the explainer says what the microphone is for, before asking', (
    tester,
  ) async {
    final mic = FakeMicrophone(alreadyAllowed: false);
    final r = TakeRecorder(
      microphone: mic,
      maxLength: const Duration(seconds: 30),
    );
    addTearDown(r.dispose);
    await r.start();
    await pumpPanel(tester, r);
    expect(find.text(RecorderPanel.explainLine), findsOneWidget);
    expect(mic.asked, 0);
    await tester.tap(find.text(RecorderPanel.allow));
    await tester.pump();
    expect(mic.asked, 1);
    expect(find.text(RecorderPanel.readyLine), findsOneWidget);
  });

  testWidgets('refused, the self-check is offered, and taking it says so', (
    tester,
  ) async {
    var without = 0;
    final r = TakeRecorder(
      microphone: FakeMicrophone(alreadyAllowed: false, granted: false),
      maxLength: const Duration(seconds: 30),
    );
    addTearDown(r.dispose);
    await r.start();
    await r.allow();
    await pumpPanel(tester, r, onWithoutMicrophone: () => without++);
    await tester.tap(find.text(RecorderPanel.deniedAction));
    expect(without, 1);
  });

  testWidgets(
    'record, pause, continue, delete with a confirm, record again, Done',
    (tester) async {
      final mic = FakeMicrophone();
      final done = <Take>[];
      final r = TakeRecorder(
        microphone: mic,
        maxLength: const Duration(seconds: 30),
      );
      addTearDown(r.dispose);
      await r.start();
      await pumpPanel(tester, r, onDone: done.add);

      await tester.tap(find.bySemanticsLabel(RecorderPanel.recordLabel));
      await tester.pump();
      expect(find.text(RecorderPanel.recordingLine), findsOneWidget);
      mic.speak(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('0:02 / 0:30'), findsOneWidget);

      // Quiet for 5 s: it pauses by itself and says so.
      mic.hush(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text(RecorderPanel.silenceLine), findsOneWidget);
      expect(find.text('0:07 / 0:30'), findsOneWidget);

      // Continue: the same take goes on from 0:07.
      await tester.tap(find.text(RecorderPanel.resume));
      await tester.pump();
      await tester.pump();
      mic.speak(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('0:08 / 0:30'), findsOneWidget);

      // Delete asks first; Keep it keeps it.
      await tester.tap(find.text(RecorderPanel.delete));
      await tester.pump();
      expect(find.text(DeleteTakeSheet.title), findsOneWidget);
      await tester.tap(find.text(DeleteTakeSheet.keep));
      await tester.pump();
      expect(find.text('0:08 / 0:30'), findsOneWidget);

      // Delete, confirmed: empty again.
      await tester.tap(find.text(RecorderPanel.delete));
      await tester.pump();
      await tester.tap(find.text(DeleteTakeSheet.delete).last);
      await tester.pump();
      expect(find.text(RecorderPanel.readyLine), findsOneWidget);
      expect(find.text('0:00 / 0:30'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RecorderPanel.recordLabel));
      await tester.pump();
      await tester.pump();
      mic.speak(const Duration(seconds: 3));
      await tester.pump();
      await tester.tap(find.text(RecorderPanel.done));
      await tester.pump();
      await tester.pump();
      expect(done, hasLength(1));
      expect(done.single.seconds, 3);
      expect(done.single.retakes, 1);
      expect(done.single.pausedCount, 1);
    },
  );
}
