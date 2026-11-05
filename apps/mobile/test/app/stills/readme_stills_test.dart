import 'dart:io';
import 'dart:ui' as ui;

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/notifications/reminder_settings.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/onboarding/onboarding_copy.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/progression/floor_cleared_screen.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/recall/recall_screen.dart';
import 'package:the_last_room/features/tips/tip_overlay.dart';
import 'package:the_last_room/features/tips/tips.dart';
import 'package:the_last_room/features/tower/northstar_tower.dart';
import 'package:the_last_room/features/voice/audio/take_playback.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/features/voice/voice_providers.dart';
import 'package:the_last_room/ui/paper/dossier.dart';

import '../../core/backend/fakes.dart' show FakeBackend, keyedEnv;
import '../../core/notifications/reminder_fakes.dart' show MemoryReminderStore;
import '../../features/mission/mission_harness.dart';
import '../../features/tower/played_attempt.dart';
import '../../features/voice/voice_fixture.dart';

/// The README's screenshots (wave 6): the game in the Daylight look, from widget-test stills
/// with real type and seeded data, at a 390 × 844 phone. Every still must draw without an
/// exception; with `WRITE_STILLS=1` each is saved as a PNG at 3x in `STILLS_DIR` (default
/// `.pr-screenshots/readme/`), then converted to the JPEGs in `docs/screenshots/`.
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  final dir =
      Platform.environment['STILLS_DIR'] ?? '../../.pr-screenshots/readme';
  const pixelRatio = 3.0;
  const phone = Size(390, 844);

  Future<void> still(WidgetTester tester, String name) async {
    await tester.pump();
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & (phone * dpr),
        pixelRatio: pixelRatio / dpr,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  /// A player part way up floor 1: rooms 1–4 played (room 2 twice, room 3 scored by the AI),
  /// a few traps waiting in the Recall Room, an interview date set.
  Future<MissionRig> midway(
    WidgetTester tester, {
    PlayerProfile profile = onboardedPlayer,
  }) async {
    final rig = _rig(tester, profile: profile);
    await rig.progress.recordAttempt(playedAttempt(missions[0], pick: 2));
    await rig.progress.recordAttempt(playedAttempt(missions[1], pick: 1));
    await rig.progress.recordAttempt(playedAttempt(missions[1], attempt: 2));
    await rig.progress.recordAttempt(playedAttempt(missions[2], pick: 1));
    await rig.progress.recordAttempt(playedAttempt(missions[3]));
    await rig.aiScores.save(
      SavedAiScore(
        missionId: missions[2].id,
        at: DateTime.now().toUtc().add(const Duration(minutes: 1)),
        score: AiScore.fromJson(_roomThree)!,
      ),
    );
    return rig;
  }

  testWidgets('the title', (tester) async {
    final rig = _rig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.home, size: phone);
    await rig.run(const Duration(seconds: 4));
    await still(tester, '11-title');
    await _done(tester);
  });

  testWidgets('onboarding: meet your interviewers', (tester) async {
    final rig = _rig(tester, profile: const PlayerProfile());
    await rig.boot(Routes.onboarding, size: phone);
    await rig.until(find.byType(OnboardingScreen));
    await rig.run(const Duration(seconds: 2));
    final next = find.text(OnboardingCopy.next);
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await rig.until(find.text(OnboardingCopy.castTitle));
    await rig.run(const Duration(seconds: 2));
    await still(tester, '12-onboarding');
    await _done(tester);
  });

  testWidgets('the tower, its first-time tip, and a floor sheet', (
    tester,
  ) async {
    var rig = await midway(tester);
    await rig.boot(Routes.tower(), size: phone);
    await rig.until(find.byType(NorthstarTower));
    await rig.run(const Duration(seconds: 3));
    await still(tester, '1-tower');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -760));
    await rig.run(const Duration(seconds: 2));
    await still(tester, '1b-tower-doors');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 760));
    await rig.run(const Duration(seconds: 1));

    final floor = find.text(NorthstarTower.floorLine(chapters[1]));
    await tester.ensureVisible(floor);
    await rig.run(const Duration(milliseconds: 600));
    await tester.tap(floor);
    await rig.run(const Duration(seconds: 2));
    await still(tester, '6-floor-sheet');
    await _done(tester);

    rig = _rig(tester);
    rig.tips.flags.remove(Tip.towerDoor);
    await rig.boot(Routes.tower(), size: phone);
    await rig.until(find.byType(TipOverlay));
    await rig.run(const Duration(seconds: 1));
    await still(tester, '13-first-tip');
    await _done(tester);
  });

  testWidgets('room 1: the answer cards, the why step, the debrief', (
    tester,
  ) async {
    final rig = _rig(tester)
      ..scorer = AiScorer(
        env: keyedEnv,
        session: const GuestSession(userId: FakeBackend.guestId),
        backend: () => FakeBackend()..scorer = (_) async => _verdict,
        log: Log(sink: (_) {}),
      );
    await rig.boot(Routes.mission(1), size: phone);
    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(ChoiceCard));
    await rig.run(const Duration(seconds: 2));
    await still(tester, '2-mission-answers');

    final m = rig.state(1).mission;
    final strongest = m.beats[0].options.firstWhere(
      (o) => m.beats[0].isStrongest(o.id),
    );
    await rig.pick(strongest);
    final why = m.beats[0].why!;
    await rig.until(find.widgetWithText(ChoiceCard, why.reasons.first.text));
    await rig.run(const Duration(seconds: 2));
    await still(tester, '3-why-step');

    await rig.pick(why.reasons.firstWhere((r) => r.isSoundFor(strongest.id)));
    for (final beat in m.beats.skip(1)) {
      await rig.say(beat.options.firstWhere((o) => beat.isStrongest(o.id)));
    }
    final followUp = rig.state(1).followUpLine!;
    await rig.until(find.text(followUp.text));
    await rig.run(const Duration(milliseconds: 300));
    if (rig.typing) await rig.tapScene();
    await rig.say(rig.state(1).replyOptions.first);
    await rig.until(find.byType(Dossier));
    await rig.settleDossier();
    await rig.run(const Duration(seconds: 2));
    await still(tester, '4-debrief');

    final basis = find.byType(AiBasisSlip);
    await rig.until(basis);
    await tester.ensureVisible(basis);
    await rig.run(const Duration(seconds: 1));
    await still(tester, '4b-debrief-basis');
    await _done(tester);
  });

  testWidgets('room 8: answering out loud', (tester) async {
    final rig = _rig(tester);
    final room = missions.firstWhere((m) => m.answerMode == AnswerMode.voice);
    await rig.unlockThrough(room.number);
    final mics = <FakeMicrophone>[];
    rig.overrides.addAll([
      microphoneFactoryProvider.overrideWithValue(() {
        final m = FakeMicrophone();
        mics.add(m);
        return m;
      }),
      interviewerVoiceProvider.overrideWithValue(RecordingVoice()),
      takePlaybackProvider.overrideWithValue(SilentTakePlayback()),
    ]);
    await rig.boot(Routes.mission(room.number), size: phone);
    await rig.startInterview();
    await rig.until(
      find.text(RecorderPanel.readyLine).hitTestable(),
      timeout: _long,
    );
    await tester.tap(find.bySemanticsLabel(RecorderPanel.recordLabel));
    await tester.pump();
    mics.last.speak(const Duration(seconds: 14));
    await rig.run(const Duration(milliseconds: 500));
    await still(tester, '7-voice-recorder');
    await _done(tester);
  });

  testWidgets('Your file and a past result', (tester) async {
    var rig = await midway(tester);
    await rig.boot(Routes.progress, size: phone);
    await rig.until(find.byType(ProgressScreen));
    await rig.run(const Duration(seconds: 2));
    await still(tester, '8-your-file');
    await _done(tester);

    rig = await midway(tester);
    await rig.boot(Routes.result(3), size: phone);
    await rig.until(find.byType(Dossier));
    await rig.run(const Duration(seconds: 6));
    await still(tester, '9-past-result');
    await _done(tester);
  });

  testWidgets('the Recall Room', (tester) async {
    final rig = await midway(tester);
    await rig.boot(Routes.recall, size: phone);
    await rig.until(find.byType(RecallScreen));
    await rig.run(const Duration(seconds: 3));
    await still(tester, '5-recall-room');
    await _done(tester);
  });

  testWidgets('floor 1 cleared', (tester) async {
    final rig = _rig(tester);
    final review = missions.lastWhere((m) => m.chapter == 1);
    await rig.unlockThrough(review.number + 1);
    await rig.boot(Routes.floorCleared(1), size: phone);
    await rig.until(find.byType(FloorClearedScreen));
    await rig.run(FloorClearedScreen.length + const Duration(seconds: 1));
    await still(tester, '10-floor-cleared');
    await _done(tester);
  });
}

const Duration _long = Duration(seconds: 40);

/// What the `score` function answers: a strong answer with a stated basis per number.
const Map<String, Object?> _verdict = {
  'model': 'gemini-3.5-flash-lite',
  'overall': {
    'score': 88,
    'basis': 'Answers why this role with one concrete project and a measured result.',
  },
  'dimensions': {
    'relevance': {
      'score': 92,
      'basis': 'Ties the answer to what the role does day to day.',
    },
    'specificity': {
      'score': 85,
      'basis': 'Names one project, the candidate\'s own part and a number.',
    },
    'structure': {
      'score': 88,
      'basis':
          'Opens on the role, gives the evidence, lands on what they bring.',
    },
    'adaptability': {
      'score': 86,
      'basis': 'The follow-up reply owns the part they led, without blaming.',
    },
  },
};

/// Room 3's verdict, for Your file and its past result.
const Map<String, Object?> _roomThree = {
  'model': 'gemini-3.5-flash-lite',
  'overall': {
    'score': 78,
    'basis': 'Owns the missing experience and bridges it with one project, but the close is vague.',
  },
  'dimensions': {
    'relevance': {
      'score': 85,
      'basis': 'Answers the worry about experience head on.',
    },
    'specificity': {
      'score': 70,
      'basis': 'One project, though the result has no number.',
    },
    'structure': {
      'score': 80,
      'basis': 'A clear open and evidence; the landing trails off.',
    },
    'adaptability': {
      'score': 76,
      'basis': 'The reply stays calm under the push, a little general.',
    },
  },
};

/// Ends a test with nothing on screen and its timers run out.
Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// A rig with an interview date two weeks out, a little Recall XP, and the reminder offer
/// already answered (so no explainer covers the tower).
MissionRig _rig(
  WidgetTester tester, {
  PlayerProfile profile = onboardedPlayer,
}) {
  final rig = MissionRig(tester, profile: profile);
  final today = DateTime.now();
  rig.overrides.addAll([
    progressionStoreProvider.overrideWithValue(
      InMemoryProgressionStore(
        ProgressionRecord(
          recallXp: 30,
          interviewDate: CalendarDay(today.year, today.month, today.day + 16),
        ),
      ),
    ),
    reminderSettingsStoreProvider.overrideWithValue(
      MemoryReminderStore(const ReminderSettings(offered: true)),
    ),
  ]);
  return rig;
}
