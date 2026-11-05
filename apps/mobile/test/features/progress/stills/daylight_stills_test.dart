import 'dart:io';
import 'dart:ui' as ui;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/audio/game_sounds.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/intro/character_screen.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/scene/epilogue_scene.dart';
import 'package:the_last_room/features/onboarding/explainer_copy.dart';
import 'package:the_last_room/features/onboarding/onboarding_copy.dart';
import 'package:the_last_room/features/onboarding/onboarding_screen.dart';
import 'package:the_last_room/features/progress/chapter_report_screen.dart';
import 'package:the_last_room/features/progress/past_result_screen.dart';
import 'package:the_last_room/features/progress/progress_screen.dart';
import 'package:the_last_room/features/progression/interview_date_choices.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/ui/paper/dossier.dart';

import '../../mission/mission_harness.dart';
import '../../tower/played_attempt.dart';

/// The Daylight screens of brief 48 in every state the PR shows, with real type, at the
/// owner's phone (360 × 800) and a large one (411 × 914), 1x and 2x text. Every state must
/// draw without an exception; with `WRITE_STILLS=1` each is also saved as a PNG at 2x in
/// `.pr-screenshots/48/` (`tall` ones are the whole scroll, for the PR).
void main() {
  final write = Platform.environment['WRITE_STILLS'] == '1';
  const pixelRatio = 2.0;
  const small = Size(360, 800);
  const large = Size(411, 914);

  Future<void> still(WidgetTester tester, String name, Size size) async {
    await tester.pump();
    expect(tester.takeException(), isNull, reason: name);
    if (!write) return;
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final dpr = tester.view.devicePixelRatio;
    await tester.runAsync(() async {
      final image = await layer.toImage(
        Offset.zero & (size * dpr),
        pixelRatio: pixelRatio / dpr,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../../.pr-screenshots/48/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  const Map<String, Object?> verdict = {
    'model': 'gemini-3.8-flash',
    'overall': {
      'score': 77,
      'basis': 'A clear answer with one concrete project and a number.',
    },
    'dimensions': {
      'relevance': {'score': 80, 'basis': 'r.'},
      'specificity': {'score': 75, 'basis': 's.'},
      'structure': {'score': 70, 'basis': 't.'},
      'adaptability': {'score': 81, 'basis': 'a.'},
    },
  };

  Future<MissionRig> partial(WidgetTester tester) async {
    final rig = _rig(tester);
    await rig.progress.recordAttempt(playedAttempt(missions[0], pick: 2));
    await rig.progress.recordAttempt(playedAttempt(missions[1], pick: 1));
    await rig.progress.recordAttempt(playedAttempt(missions[1], attempt: 2));
    await rig.progress.recordAttempt(playedAttempt(missions[2], pick: 1));
    await rig.aiScores.save(
      SavedAiScore(
        missionId: missions[2].id,
        at: DateTime.now().toUtc().add(const Duration(minutes: 1)),
        score: AiScore.fromJson(verdict)!,
      ),
    );
    return rig;
  }

  for (final (tag, size, scale) in [
    ('360', small, 1.0),
    ('411', large, 1.0),
    ('360-2x', small, 2.0),
  ]) {
    testWidgets('Your file at $tag', (tester) async {
      // Empty: nothing played.
      var rig = _rig(tester);
      await rig.boot(Routes.progress, size: size, textScale: scale);
      await rig.until(find.byType(ProgressScreen));
      await rig.run(const Duration(seconds: 2));
      await still(tester, 'file-empty-$tag', size);

      // Part played: three rooms, one scored by AI, one played twice.
      rig = await partial(tester);
      await rig.boot(Routes.progress, size: size, textScale: scale);
      await rig.run(const Duration(seconds: 2));
      await still(tester, 'file-partial-$tag', size);
      if (tag == '411') {
        rig = await partial(tester);
        await rig.boot(
          Routes.progress,
          size: const Size(411, 3400),
          textScale: scale,
        );
        await rig.run(const Duration(seconds: 2));
        await still(tester, 'file-partial-tall', const Size(411, 3400));
      }
      await _done(tester);
    });
  }

  testWidgets('Your file, everything played, and the store failing', (
    tester,
  ) async {
    var rig = _rig(tester);
    await rig.unlockThrough(missions.length + 1);
    await rig.boot(Routes.progress, size: const Size(411, 3800));
    await rig.run(const Duration(seconds: 2));
    await still(tester, 'file-complete-tall', const Size(411, 3800));

    rig = _rig(tester);
    rig.progress.failReads = true;
    await rig.boot(Routes.progress, size: small);
    await rig.run(const Duration(seconds: 1));
    await still(tester, 'file-error-360', small);

    rig = await partial(tester);
    await rig.boot(Routes.progress, size: small, reduceMotion: true);
    await rig.run(const Duration(milliseconds: 500));
    await still(tester, 'file-partial-360-still', small);
    await _done(tester);
  });

  testWidgets('a played room\'s last result', (tester) async {
    var rig = await partial(tester);
    await rig.boot(Routes.result(2), size: small);
    await rig.until(find.byType(Dossier));
    await rig.run(const Duration(seconds: 6));
    await still(tester, 'result-360', small);
    rig = await partial(tester);
    await rig.boot(Routes.result(3), size: const Size(411, 2400));
    await rig.until(find.byType(Dossier));
    await rig.run(const Duration(seconds: 6));
    await still(tester, 'result-ai-tall', const Size(411, 2400));

    rig = _rig(tester);
    final voiceRoom = missions.firstWhere(
      (m) => m.answerMode == AnswerMode.voice,
    );
    await rig.unlockThrough(voiceRoom.number + 1);
    await rig.boot(
      Routes.result(voiceRoom.number),
      size: const Size(411, 2400),
    );
    await rig.until(find.byType(Dossier));
    await rig.run(const Duration(seconds: 6));
    await still(tester, 'result-voice-tall', const Size(411, 2400));

    rig = _rig(tester);
    await rig.boot(Routes.result(5), size: small, textScale: 2);
    await rig.until(find.text(PastResultScreen.notPlayedTitle));
    await rig.run(const Duration(seconds: 1));
    await still(tester, 'result-not-played-360-2x', small);
    await _done(tester);
  });

  testWidgets('the Chapter 1 report', (tester) async {
    var rig = _rig(tester);
    await rig.boot(Routes.report, size: small);
    await rig.until(find.text(ChapterReportScreen.notYetTitle));
    await rig.run(const Duration(seconds: 1));
    await still(tester, 'report-not-yet-360', small);

    rig = _rig(tester);
    final review = missions.lastWhere((m) => m.chapter == 1);
    await rig.unlockThrough(review.number + 1, baselineDraft: _draft);
    await rig.boot(Routes.report, size: const Size(411, 2600));
    await rig.until(find.text(ChapterReportScreen.honest));
    await rig.run(const Duration(seconds: 2));
    await still(tester, 'report-tall', const Size(411, 2600));
    rig = _rig(tester);
    await rig.unlockThrough(review.number + 1, baselineDraft: _draft);
    await rig.boot(Routes.report, size: small);
    await rig.until(find.text(ChapterReportScreen.honest));
    await rig.run(const Duration(seconds: 2));
    await still(tester, 'report-360', small);
    await _done(tester);
  });

  for (final (tag, size, scale) in [
    ('360', small, 1.0),
    ('411', large, 1.0),
    ('360-2x', small, 2.0),
  ]) {
    testWidgets('first launch at $tag', (tester) async {
      var rig = _rig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.home, size: size, textScale: scale);
      await rig.run(const Duration(seconds: 3));
      await still(tester, 'title-$tag', size);

      rig = _rig(tester, profile: const PlayerProfile());
      await rig.boot(Routes.onboarding, size: size, textScale: scale);
      await rig.until(find.byType(OnboardingScreen));
      await rig.run(const Duration(seconds: 2));
      await still(tester, 'onboarding-1-$tag', size);
      for (final (step, finder, label) in [
        ('2', find.text(ExplainerCopy.pages[1].title), ExplainerCopy.next),
        ('3', find.text(ExplainerCopy.pages[2].title), ExplainerCopy.next),
        ('4', find.text(ExplainerCopy.pages[3].title), ExplainerCopy.next),
        ('5', find.text(ExplainerCopy.pages[4].title), ExplainerCopy.next),
        ('6', find.text(InterviewDateChoices.title), ExplainerCopy.ready),
        ('7', find.text(OnboardingCopy.nameTitle), OnboardingCopy.next),
      ]) {
        final next = find.text(label);
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await rig.until(finder);
        await rig.run(const Duration(seconds: 2));
        await still(tester, 'onboarding-$step-$tag', size);
      }
      await _done(tester);
    });
  }

  testWidgets('the practice CV', (tester) async {
    final rig = _rig(tester);
    await rig.boot(Routes.character, size: small);
    await rig.until(find.byType(CharacterScreen));
    await rig.run(const Duration(seconds: 2));
    await still(tester, 'character-360', small);
    await _done(tester);
  });

  testWidgets('the epilogue', (tester) async {
    final review = missions.lastWhere((m) => m.chapter == 1);
    tester.view.physicalSize = small * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: small),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EpilogueScene(
            lines: [
              for (final line in review.epilogue) line.addressedTo('Sami'),
            ],
            grade: ChapterGrade.lobby,
            sounds: const SilentGameSounds(),
            doneLabel: 'See your Chapter 1 report',
            onDone: () {},
          ),
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await still(tester, 'epilogue-360', small);
    await _done(tester);
  });
}

/// Ends a test with nothing on screen and its timers run out.
Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// A rig whose progression record is in memory (shared preferences never answer in a test).
MissionRig _rig(
  WidgetTester tester, {
  PlayerProfile profile = onboardedPlayer,
}) {
  final rig = MissionRig(tester, profile: profile);
  rig.overrides.add(
    progressionStoreProvider.overrideWithValue(InMemoryProgressionStore()),
  );
  return rig;
}

const String _draft =
    'I like building things and I am good with people, so I think I would fit in well.';
