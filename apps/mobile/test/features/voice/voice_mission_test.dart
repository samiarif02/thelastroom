import 'dart:async';
import 'dart:convert';

import 'package:brand/brand.dart' show DaylightMotion;
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/voice/recorder/recorder_panel.dart';
import 'package:the_last_room/features/voice/voice_debrief.dart';
import 'package:the_last_room/features/voice/voice_player.dart';
import 'package:the_last_room/features/voice/voice_scoring.dart';
import 'package:the_last_room/features/voice/widgets/scene_controls.dart';
import 'package:the_last_room/features/voice/widgets/self_check_panel.dart';

import 'voice_fixture.dart';
import 'voice_rig.dart';

/// What `score-voice` answers in these tests: two points made, a transcript of each take.
Map<String, Object?> verdict() => {
  'model': 'gemini-3.8-flash',
  'transcript': {
    'answer':
        'The launch date moved up a week, so I re-planned the survey myself.',
    'reply': 'I would check the timeline with the client sooner.',
  },
  'points_made': ['m08_names_change', 'm08_owns_it', 'not_a_point'],
  'overall': {'score': 64, 'basis': 'A clear change, owned, with no result.'},
  'dimensions': {
    'relevance': {'score': 80, 'basis': 'It names what changed and when.'},
    'specificity': {'score': 55, 'basis': 'Some of it is the team, not you.'},
    'structure': {'score': 40, 'basis': 'It stops before a result.'},
    'adaptability': {'score': 75, 'basis': 'The reply names one change.'},
  },
};

void main() {
  testWidgets(
    'a voice mission end to end: spoken lines, two takes, the AI verdict on the debrief',
    (tester) async {
      final rig = VoiceRig(tester, online: true);
      rig.backend.voiceScorer = (_) async => verdict();
      await rig.boot();
      await rig.answerBoth();
      await rig.until(find.text(HeardSlip.heading));

      // Every interviewer line was spoken, addressed to the player (never "Jordan").
      expect(rig.voice.said, [
        'Sami, thanks for coming back for round two.',
        'Tell me about a time a plan changed under you.',
        'And what would you do differently?',
      ]);

      // What was sent: the audio and the points, never the player's name.
      final sent = rig.backend.voiceScoreRequests.single;
      expect(sent['mission_id'], voiceFixture.id);
      expect(sent['mime_type'], 'audio/wav');
      expect(
        base64Decode(sent['answer_audio']! as String).length,
        44 + 3 * 32000,
      );
      expect(jsonEncode(sent), isNot(contains('Sami')));

      // The debrief: the AI's label, transcript, points made and missed, basis and lesson.
      expect(find.text(ScoreSourceLabel.aiLabel), findsOneWidget);
      expect(find.text(VoiceDebrief.contentOnly), findsOneWidget);
      await rig.settleDebrief();
      expect(
        find.textContaining('re-planned the survey myself'),
        findsOneWidget,
      );
      expect(find.text('Names what changed and when'), findsOneWidget);
      expect(find.text('Lands on a result, with a number'), findsOneWidget);
      expect(find.text('It stops before a result.'), findsOneWidget);
      expect(find.text(VoiceLessonSlip.heading), findsOneWidget);

      // Progress: one voice attempt, the engine's score from the AI's points.
      final stored = (await rig.progress.attempts()).single;
      expect(stored.voice!.source, VoiceScoreSource.ai);
      expect(stored.voice!.madePointIds, ['m08_names_change', 'm08_owns_it']);
      expect(stored.voice!.seconds, 5);
      // relevance 1/1, specificity 0/1, structure 0/1, adaptability 1/1 → 25 + 20 = 45.
      expect(stored.score.total, 45);
      expect(
        (await rig.aiScores.latest())[voiceFixture.id]!.score.overall.score,
        64,
      );

      // Events: one per take, then scored and completed; no audio, no words.
      final recorded = rig.analytics.events
          .where((e) => e.event == AnalyticsEvent.voiceAnswerRecorded)
          .toList();
      expect(recorded.map((e) => e.wire['seconds']), [3, 2]);
      expect(recorded.first.wire, {
        'mission_id': voiceFixture.id,
        'seconds': 3,
        'paused_count': 0,
        'retakes': 0,
      });
      expect(rig.analytics.only(AnalyticsEvent.voiceAnswerScored).wire, {
        'mission_id': voiceFixture.id,
        'score_bucket': 'from60',
        'source': 'ai',
      });
      expect(rig.analytics.count(AnalyticsEvent.missionCompleted), 1);
      expect(rig.analytics.count(AnalyticsEvent.missionStarted), 1);
      expect(rig.analytics.count(AnalyticsEvent.userActivated), 1);
    },
  );

  testWidgets(
    'offline (zero setup): the self-check scores it, labelled, and the room lights',
    (tester) async {
      final rig = VoiceRig(tester);
      await rig.boot();
      await rig.answerBoth();
      await rig.until(find.text(SelfCheckPanel.title));
      expect(
        find.text(SelfCheckPanel.reasonLine(SelfCheckReason.noBackend)),
        findsOneWidget,
      );

      // Listening back plays the take.
      await rig.tap(find.text(SelfCheckPanel.listenAnswer));
      expect(rig.playback.played, [44 + 3 * 32000]);

      await rig.tap(find.text('Names what changed and when'));
      await rig.tap(find.text('Says what you did, not what the team did'));
      await rig.tap(find.text(SelfCheckPanel.score));
      await rig.until(find.text(VoiceDebrief.selfCheckLabel));

      final stored = (await rig.progress.attempts()).single;
      expect(stored.voice!.source, VoiceScoreSource.selfCheck);
      expect(stored.voice!.madePointIds, ['m08_names_change', 'm08_own_part']);
      // relevance 100, specificity 100, structure 0, adaptability 0 → 25 + 30 = 55.
      expect(stored.score.total, 55);
      expect(
        rig.analytics.only(AnalyticsEvent.voiceAnswerScored).wire['source'],
        'selfCheck',
      );
      await rig.settleDebrief();
      expect(
        find.text(
          SelfCheckBasisSlip.basis(
            Dimension.structure,
            const PointTally(made: 0, of: 1, direct: true),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(HeardSlip.heading), findsNothing);
    },
  );

  testWidgets('microphone refused: answered out loud, then the self-check', (
    tester,
  ) async {
    final rig = VoiceRig(tester)
      ..newMic = () => FakeMicrophone(alreadyAllowed: false, granted: false);
    await rig.boot();
    await rig.until(find.byType(VoicePlayer));
    await rig.playToAnswerExplained();
    await rig.tap(find.text(RecorderPanel.allow));
    await rig.until(find.text(RecorderPanel.deniedTitle));
    await rig.tap(find.text(RecorderPanel.deniedAction));
    await rig.answerAloudBoth();
    await rig.until(find.text(SelfCheckPanel.title));
    expect(
      find.text(SelfCheckPanel.reasonLine(SelfCheckReason.noMicrophone)),
      findsOneWidget,
    );
    expect(find.text(SelfCheckPanel.listenAnswer), findsNothing);
    await rig.tap(find.text(SelfCheckPanel.score));
    await rig.until(find.text(VoiceDebrief.selfCheckLabel));
    expect(rig.analytics.count(AnalyticsEvent.voiceAnswerRecorded), 0);
    expect((await rig.progress.attempts()).single.score.total, 0);
  });

  testWidgets('quota spent: a designed self-check, never an error', (
    tester,
  ) async {
    final rig = VoiceRig(tester, online: true);
    rig.backend.voiceScorer = (_) async =>
        throw const ScoreRefused(429, 'daily_limit_reached');
    await rig.boot();
    await rig.answerBoth();
    await rig.until(find.text(SelfCheckPanel.title));
    expect(
      find.text(SelfCheckPanel.reasonLine(SelfCheckReason.limited)),
      findsOneWidget,
    );
  });

  testWidgets('a timeout: the recruiter listens, then the self-check', (
    tester,
  ) async {
    final rig = VoiceRig(tester, online: true);
    final never = Completer<Object?>();
    rig.backend.voiceScorer = (_) => never.future;
    await rig.boot();
    await rig.answerBoth();
    await rig.until(find.text(ListeningCard.title));
    await rig.until(
      find.text(SelfCheckPanel.title),
      timeout: VoiceScorer.timeout + const Duration(seconds: 2),
    );
    expect(
      find.text(SelfCheckPanel.reasonLine(SelfCheckReason.timeout)),
      findsOneWidget,
    );
  });

  testWidgets('a bad verdict falls back to the self-check too', (tester) async {
    final rig = VoiceRig(tester, online: true);
    rig.backend.voiceScorer = (_) async => {'model': 'x'};
    await rig.boot();
    await rig.answerBoth();
    await rig.until(find.text(SelfCheckPanel.title));
    expect(
      find.text(SelfCheckPanel.reasonLine(SelfCheckReason.error)),
      findsOneWidget,
    );
  });

  testWidgets('muting stops the voice; the lines are still subtitled', (
    tester,
  ) async {
    final rig = VoiceRig(tester);
    await rig.boot();
    await rig.until(find.byType(VoicePlayer));
    await rig.tester.tapAt(const Offset(8, 140));
    await rig.until(find.text(MuteControl.on));
    await rig.tap(find.text(MuteControl.on));
    expect(find.text(MuteControl.off), findsOneWidget);
    expect(rig.voice.stops, greaterThan(0));
    await rig.until(find.text(RecorderPanel.readyLine).hitTestable());
    expect(rig.voice.said.length, lessThan(2));
  });

  testWidgets('leaving asks first, with words true for a voice mission', (
    tester,
  ) async {
    final rig = VoiceRig(tester);
    await rig.boot();
    await rig.playToAnswer();
    await rig.tap(find.bySemanticsLabel('Leave the interview'));
    // The × nudges toward the way out first (brief 50), then asks.
    expect(find.text(VoicePlayer.leaveLine), findsNothing);
    await tester.pump(DaylightMotion.nudge);
    await tester.pump(DaylightMotion.nudge);
    await tester.pump();
    expect(find.text(VoicePlayer.leaveLine), findsOneWidget);
    await rig.tap(find.text(VoicePlayer.stay));
    expect(find.text(VoicePlayer.leaveLine), findsNothing);
  });

  for (final (scale, still) in [(2.0, false), (1.0, true), (2.0, true)]) {
    testWidgets(
      'the whole mission plays at ${scale}x${still ? ', reduced motion' : ''}',
      (tester) async {
        final rig = VoiceRig(tester);
        await rig.boot(textScale: scale, reduceMotion: still);
        await rig.answerBoth();
        await rig.until(find.text(SelfCheckPanel.title));
        await rig.tap(find.text(SelfCheckPanel.score));
        await rig.until(find.text(VoiceDebrief.selfCheckLabel));
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('the fixture is valid content', () {
    expect(
      validateContent(
        ContentBundle(
          // The fixture stands in for Mission 8, the first voice mission.
          missions: [
            for (final m in missions)
              m.number == voiceFixture.number ? voiceFixture : m,
          ],
          interviewers: interviewers,
          lessons: lessons,
          chapters: chapters,
        ),
      ).where(
        // Chapter 2 opens when brief 37's content flips it; everything else must hold.
        (i) =>
            i.itemId == voiceFixture.id &&
            i.problem != 'chapter 2 is not a playable chapter',
      ),
      isEmpty,
    );
  });

  test('the self-check basis agrees with one point and with two', () {
    expect(
      SelfCheckBasisSlip.basis(
        Dimension.structure,
        const PointTally(made: 0, of: 1, direct: true),
      ),
      'You ticked 0 of the 1 point that earns structure.',
    );
    expect(
      SelfCheckBasisSlip.basis(
        Dimension.relevance,
        const PointTally(made: 1, of: 2, direct: true),
      ),
      'You ticked 1 of the 2 points that earn relevance.',
    );
  });

  test('a stored voice attempt keeps no audio and no words', () {
    const record = VoiceAnswerRecord(
      madePointIds: ['m08_names_change'],
      source: VoiceScoreSource.ai,
      seconds: 41,
    );
    expect(record.toJson(), {
      'made': ['m08_names_change'],
      'source': 'ai',
      'seconds': 41,
    });
    expect(
      VoiceAnswerRecord.fromJson(record.toJson())!.source,
      VoiceScoreSource.ai,
    );
    expect(
      VoiceAnswerRecord.fromJson({
        'made': const <String>[],
        'source': 'x',
        'seconds': 1,
      }),
      isNull,
    );
  });
}
