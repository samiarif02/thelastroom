import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/audio/game_sounds.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/scene/room_intro.dart';
import 'package:the_last_room/features/recall/recall_store.dart';
import 'package:the_last_room/features/tips/tips.dart';
import 'package:the_last_room/features/voice/audio/take_playback.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/features/voice/voice_controller.dart';
import 'package:the_last_room/features/voice/voice_debrief.dart';
import 'package:the_last_room/features/voice/voice_providers.dart';
import 'package:the_last_room/features/voice/voice_scoring.dart';
import 'package:the_last_room/features/voice/widgets/scene_controls.dart';

import '../../core/backend/fakes.dart' show FakeBackend, keyedEnv;
import '../mission/mission_harness.dart';
import 'voice_fixture.dart';

/// The app booted on the voice fixture (`/tower/mission/8`), with a fake microphone per take,
/// a recording interviewer voice and, when [online], the AI scorer on a [FakeBackend].
class VoiceRig {
  VoiceRig(this.tester, {this.online = false});

  final WidgetTester tester;
  final bool online;
  final InMemoryProfileRepository profile = InMemoryProfileRepository(
    onboardedPlayer,
  );
  final RecordingAnalytics analytics = RecordingAnalytics();
  final RecordingSounds sounds = RecordingSounds();
  final InMemoryProgressRepository progress = InMemoryProgressRepository();
  final InMemoryAiScoreStore aiScores = InMemoryAiScoreStore();
  final RecordingVoice voice = RecordingVoice();
  final SilentTakePlayback playback = SilentTakePlayback();
  final FakeBackend backend = FakeBackend();

  /// The first-time tips: all seen, unless a test clears them (`rig.tips.flags.clear()`).
  final InMemoryTipStore tips = InMemoryTipStore.allSeen();

  /// Every microphone the player opened, one per take.
  final List<FakeMicrophone> mics = [];

  /// What each new microphone is: allowed, by default.
  FakeMicrophone Function() newMic = FakeMicrophone.new;
  late final ProviderContainer container;

  FakeMicrophone get mic => mics.last;

  static const Size phone = Size(390, 844);

  /// The whole screen, for stills.
  static const Key frame = ValueKey('voice-frame');

  Future<void> boot({double textScale = 1, bool reduceMotion = false}) async {
    tester.view.physicalSize = phone * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.mission(voiceFixture.number),
      routes: appRoutes(),
    );
    addTearDown(router.dispose);
    final log = Log(sink: (_) {});
    container = ProviderContainer(
      overrides: [
        logProvider.overrideWithValue(log),
        analyticsProvider.overrideWithValue(analytics),
        gameSoundsProvider.overrideWithValue(sounds),
        progressRepositoryProvider.overrideWithValue(progress),
        profileRepositoryProvider.overrideWithValue(profile),
        aiScoreStoreProvider.overrideWithValue(aiScores),
        recallStoreProvider.overrideWithValue(InMemoryRecallStore()),
        routerProvider.overrideWithValue(router),
        tipStoreProvider.overrideWithValue(tips),
        missionCatalogProvider.overrideWithValue(const [voiceFixture]),
        microphoneFactoryProvider.overrideWithValue(() {
          final m = newMic();
          mics.add(m);
          return m;
        }),
        interviewerVoiceProvider.overrideWithValue(voice),
        takePlaybackProvider.overrideWithValue(playback),
        if (online)
          voiceScorerProvider.overrideWithValue(
            VoiceScorer(
              env: keyedEnv,
              session: const GuestSession(userId: FakeBackend.guestId),
              backend: () => backend,
              log: log,
            ),
          ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: phone,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: RepaintBoundary(
          key: frame,
          child: UncontrolledProviderScope(
            container: container,
            child: const TheLastRoomApp(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  VoiceState get state =>
      container.read(voiceControllerProvider(voiceFixture.number)).requireValue;

  /// "Start the interview" on the room's intro (issue 76).
  Future<void> startInterview() async {
    await until(find.text(RoomIntro.start).hitTestable());
    await tap(find.text(RoomIntro.start));
  }

  /// Pumps until [finder] finds something, failing on any frame that throws.
  Future<void> until(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 100),
    bool absent = false,
  }) async {
    for (var e = Duration.zero; e < timeout; e += step) {
      if (finder.evaluate().isNotEmpty != absent) return;
      await tester.pump(step);
      expect(tester.takeException(), isNull, reason: 'at $e');
    }
    fail('timed out waiting for $finder');
  }

  Future<void> tap(Finder finder) async {
    await until(finder);
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await tester.pump();
    await tester.pump();
  }

  /// From the title card to the recorder: the lines play (typed and spoken) by themselves.
  Future<void> playToAnswer() async {
    await startInterview();
    await until(find.text(RecorderPanel.readyLine).hitTestable());
  }

  /// From the title card to the recorder's explainer (the microphone not yet allowed).
  Future<void> playToAnswerExplained() async {
    await startInterview();
    await until(find.text(RecorderPanel.allow).hitTestable());
  }

  /// Records [length] of speech and taps Done.
  Future<void> recordAndSubmit({
    Duration length = const Duration(seconds: 3),
  }) async {
    await tap(find.bySemanticsLabel(RecorderPanel.recordLabel));
    mic.speak(length);
    await tester.pump();
    await tap(find.text(RecorderPanel.done));
  }

  /// The answer, then the follow-up, then the reply.
  Future<void> answerBoth() async {
    await playToAnswer();
    await recordAndSubmit();
    await until(find.text(RecorderPanel.readyLine), absent: true);
    await until(find.text(RecorderPanel.readyLine).hitTestable());
    await recordAndSubmit(length: const Duration(seconds: 2));
  }

  /// Without a microphone: Done on the spoken-aloud panel, then again after the follow-up.
  Future<void> answerAloudBoth() async {
    await tap(find.text(SpokenAloudPanel.done));
    await until(find.text(SpokenAloudPanel.done), absent: true);
    await until(find.text(SpokenAloudPanel.done).hitTestable());
    await tap(find.text(SpokenAloudPanel.done));
  }

  /// Lets the dossier stamp and seal, so the slips under it are up.
  Future<void> settleDebrief() async {
    await until(find.byType(VoiceDebrief));
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  }
}
