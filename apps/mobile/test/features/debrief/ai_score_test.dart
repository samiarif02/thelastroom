import 'dart:async';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/debrief/deliberation_scene.dart';
import 'package:the_last_room/features/debrief/scoring_basis_sheet.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/ui/film_kit.dart';

import '../../core/backend/fakes.dart';
import '../mission/mission_harness.dart';

const Env _withBackend = Env(
  appEnv: 'dev',
  supabaseUrl: 'http://192.168.1.20:54321',
  supabaseAnonKey: 'public-anon-key',
  sentryDsn: '',
  posthogApiKey: '',
  posthogHost: '',
);

const Env _noBackend = Env(
  appEnv: 'dev',
  supabaseUrl: '',
  supabaseAnonKey: '',
  sentryDsn: '',
  posthogApiKey: '',
  posthogHost: '',
);

const GuestSession _guest = GuestSession(userId: FakeBackend.guestId);

/// What the `score` function answers for a good call.
const Map<String, Object?> _verdict = {
  'model': 'gemini-3.8-flash',
  'overall': {
    'score': 74,
    'basis': 'A relevant, evidenced answer with a weak close.',
  },
  'dimensions': {
    'relevance': {'score': 85, 'basis': 'It answers why this role.'},
    'specificity': {
      'score': 70,
      'basis': 'One concrete project with a number.',
    },
    'structure': {'score': 60, 'basis': 'The close trails off.'},
    'adaptability': {
      'score': 80,
      'basis': 'The reply names the candidate\'s own part.',
    },
  },
};

ScoreRequest _request() {
  const m = missionTheOpportunity;
  return ScoreRequest(
    mission: m,
    plays: [
      BeatPlay(
        option: m.beats[0].options.first,
        decidedIn: const Duration(milliseconds: 400),
        reason: m.beats[0].why!.reasons.first,
      ),
      BeatPlay(
        option: m.beats[1].options.first,
        decidedIn: const Duration(seconds: 4),
      ),
    ],
    followUp: m.followUps.first,
    reply: m.followUps.first.replies.first,
  );
}

AiScorer _scorer(
  FakeBackend backend, {
  Env env = _withBackend,
  BackendSession session = _guest,
}) => AiScorer(env: env, session: session, backend: () => backend, log: Log());

void main() {
  group('the request', () {
    test('carries the answer, the reasons and the guesses, never the player\'s name', () {
      final json = _request().toJson();
      expect(json['mission_id'], missionTheOpportunity.id);
      expect(json['interviewer_role'], 'Recruiter');
      expect(json['hiring_for'], ScoreRequest.hiringFor);
      final beats = json['beats']! as List<Object?>;
      expect(beats, hasLength(2));
      expect((beats[0]! as Map<String, Object?>)['guessed'], isTrue);
      expect((beats[1]! as Map<String, Object?>)['guessed'], isFalse);
      expect((beats[0]! as Map<String, Object?>)['reason'], isNotNull);
      expect((beats[1]! as Map<String, Object?>)['reason'], isNull);
      // The lines are the content's (the practice candidate's), never addressed to the player.
      expect(json['question'], missionTheOpportunity.question.text);
      expect(json.keys, isNot(contains('name')));
    });
  });

  group('the verdict', () {
    test('parses a complete verdict', () {
      final score = AiScore.fromJson(_verdict)!;
      expect(score.overall.score, 74);
      expect(
        score.dimensions[Dimension.structure]!.basis,
        'The close trails off.',
      );
    });

    test('anything incomplete or out of range is no verdict', () {
      Map<String, Object?> without(String key) => {..._verdict}..remove(key);
      final bad = <Object?>[
        null,
        'text',
        without('overall'),
        without('dimensions'),
        {
          ..._verdict,
          'overall': {'score': 101, 'basis': 'x'},
        },
        {
          ..._verdict,
          'overall': {'score': 50, 'basis': ' '},
        },
        {
          ..._verdict,
          'dimensions': {
            'relevance': {'score': 1, 'basis': 'x'},
          },
        },
      ];
      for (final b in bad) {
        expect(AiScore.fromJson(b), isNull, reason: '$b');
      }
    });
  });

  group('the scorer never fails: it falls back', () {
    test('no backend configured: offline at once, no call', () async {
      final backend = FakeBackend()..scorer = (_) async => _verdict;
      final scorer = _scorer(backend, env: _noBackend);
      expect(scorer.unavailable, AiFallbackReason.noBackend);
      final v = await scorer.score(_request());
      expect((v as AiOffline).reason, AiFallbackReason.noBackend);
      expect(backend.scoreRequests, isEmpty);
    });

    test('not signed in: offline at once', () async {
      final scorer = _scorer(FakeBackend(), session: const NoSession());
      expect(scorer.unavailable, AiFallbackReason.noSession);
    });

    test('a verdict comes back as AiScored', () async {
      final backend = FakeBackend()..scorer = (_) async => _verdict;
      final v = await _scorer(backend).score(_request());
      expect((v as AiScored).score.overall.score, 74);
      expect(
        backend.scoreRequests.single['mission_id'],
        missionTheOpportunity.id,
      );
    });

    test('no answer within 8 s is a timeout', () {
      fakeAsync((async) {
        final backend = FakeBackend()
          ..scorer = (_) => Completer<Object?>().future;
        AiVerdict? verdict;
        unawaited(_scorer(backend).score(_request()).then((v) => verdict = v));
        async.elapse(AiScorer.timeout - const Duration(milliseconds: 1));
        expect(verdict, isNull);
        async.elapse(const Duration(milliseconds: 2));
        expect((verdict! as AiOffline).reason, AiFallbackReason.timeout);
      });
    });

    test(
      'a slow verdict: the offline score at 8 s, then the verdict replaces it',
      () {
        fakeAsync((async) {
          final backend = FakeBackend()
            ..scorer = (_) => Future<Object?>.delayed(
              AiScorer.timeout + const Duration(seconds: 6),
              () => _verdict,
            );
          final seen = <AiVerdict>[];
          _scorer(backend).verdicts(_request()).listen(seen.add);
          async.elapse(AiScorer.timeout + const Duration(milliseconds: 1));
          expect(seen.single, isA<AiOffline>());
          async.elapse(const Duration(seconds: 6));
          expect(seen, hasLength(2));
          expect((seen.last as AiScored).score.overall.score, 74);
        });
      },
    );

    test('a verdict within 8 s is the only thing shown', () {
      fakeAsync((async) {
        final backend = FakeBackend()
          ..scorer = (_) => Future<Object?>.delayed(
            const Duration(seconds: 2),
            () => _verdict,
          );
        final seen = <AiVerdict>[];
        _scorer(backend).verdicts(_request()).listen(seen.add);
        async.elapse(AiScorer.lateLimit);
        expect(seen.single, isA<AiScored>());
      });
    });

    test('nothing by the late limit: the offline score stays', () {
      fakeAsync((async) {
        final backend = FakeBackend()
          ..scorer = (_) => Completer<Object?>().future;
        final seen = <AiVerdict>[];
        _scorer(backend).verdicts(_request()).listen(seen.add);
        async.elapse(AiScorer.lateLimit + const Duration(seconds: 1));
        expect(seen.single, isA<AiOffline>());
      });
    });

    test(
      'a spent quota, a refusal, junk and no network are offline scores',
      () async {
        final cases =
            <Future<Object?> Function(Map<String, Object?>), AiFallbackReason>{
              (_) async => throw const ScoreRefused(429, 'daily_limit_reached'):
                  AiFallbackReason.limited,
              (_) async => throw const ScoreRefused(502, 'upstream_error'):
                  AiFallbackReason.error,
              (_) async => {'model': 'x'}: AiFallbackReason.error,
              (_) async => throw StateError('socket closed'):
                  AiFallbackReason.error,
            };
        for (final MapEntry(key: answer, value: reason) in cases.entries) {
          final backend = FakeBackend()..scorer = answer;
          final v = await _scorer(backend).score(_request());
          expect((v as AiOffline).reason, reason);
        }
        final offline = FakeBackend()..online = false;
        expect(
          ((await _scorer(offline).score(_request())) as AiOffline).reason,
          AiFallbackReason.error,
        );
      },
    );
  });

  group('the dossier', () {
    Future<MissionRig> playToDebrief(
      WidgetTester tester,
      AiScorer? scorer, {
      double textScale = 1,
      bool reduceMotion = false,
    }) async {
      final rig = MissionRig(tester)..scorer = scorer;
      await rig.boot(
        Routes.mission(1),
        textScale: textScale,
        reduceMotion: reduceMotion,
      );
      const m = missionTheOpportunity;
      await rig.playLines(1);
      await rig.skipDraft();
      for (final beat in m.beats) {
        await rig.say(beat.options.firstWhere((o) => beat.isStrongest(o.id)));
      }
      final followUp = rig.state(1).followUpLine!;
      await rig.until(find.text(followUp.text));
      await rig.run(const Duration(milliseconds: 300));
      if (rig.typing) await rig.tapScene();
      await rig.say(rig.state(1).replyOptions.first);
      return rig;
    }

    testWidgets(
      'with a backend: the panel deliberates, then the AI\'s numbers and their basis',
      (tester) async {
        final backend = FakeBackend()
          ..scorer = (_) => Future<Object?>.delayed(
            const Duration(seconds: 2),
            () => _verdict,
          );
        final rig = await playToDebrief(tester, _scorer(backend));
        await rig.until(find.byType(DeliberationScene));
        expect(find.byType(Dossier), findsNothing);
        // The interviewer reads the file, in their name; never an offline flash first.
        expect(
          find.text(
            DeliberationScene.steps(
              missionTheOpportunity.lead.name,
              DeliberationKind.reading,
            ).first,
          ),
          findsOneWidget,
        );
        await rig.until(
          find.byType(Dossier),
          eachFrame: () =>
              expect(find.text(ScoreSourceLabel.offlineLabel), findsNothing),
        );
        expect(find.text(ScoreSourceLabel.aiLabel), findsOneWidget);
        // The sheet plays once, with the recruiter's numbers.
        expect(rig.sounds.count('dossierSlides'), 1);
        final dossier = tester.widget<Dossier>(find.byType(Dossier));
        expect(dossier.total, 74);
        expect(dossier.scores.map((s) => s.value), [85, 70, 60, 80]);
        await rig.settleDossier();
        expect(find.byType(AiBasisSlip), findsOneWidget);
        expect(find.text('The close trails off.'), findsOneWidget);
        expect(rig.analytics.count(AnalyticsEvent.aiScoreRequested), 1);
        expect(
          rig.analytics.only(AnalyticsEvent.aiScoreShown).wire['score_bucket'],
          'from60',
        );
        expect(rig.analytics.count(AnalyticsEvent.aiScoreFallback), 0);
        // The engine still scored the attempt (offline play, traps, the Recall Room).
        expect(rig.state(1).score, isNotNull);
      },
    );

    testWidgets(
      'a timeout: after 8 s, the engine\'s score as "Offline score"',
      (tester) async {
        final backend = FakeBackend()
          ..scorer = (_) => Completer<Object?>().future;
        final rig = await playToDebrief(tester, _scorer(backend));
        await rig.until(find.byType(DeliberationScene));
        // Past 4 s it says it's nearly done, so it never feels stuck.
        await rig.run(DeliberationScene.longAfter + const Duration(seconds: 1));
        expect(find.byType(Dossier), findsNothing);
        final almost = tester.widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(DeliberationScene.almost),
            matching: find.byType(AnimatedOpacity),
          ),
        );
        expect(almost.opacity, 1);
        await rig.until(
          find.byType(Dossier),
          timeout: AiScorer.timeout + const Duration(seconds: 3),
        );
        expect(find.text(ScoreSourceLabel.offlineLabel), findsOneWidget);
        final dossier = tester.widget<Dossier>(find.byType(Dossier));
        expect(dossier.total, rig.state(1).score!.total);
        expect(
          rig.analytics.only(AnalyticsEvent.aiScoreFallback).wire['reason'],
          'timeout',
        );
        await rig.settleDossier();
      },
    );

    testWidgets(
      'a late verdict: "Offline score" at 8 s; the recruiter\'s score waits for a tap, no restamp',
      (tester) async {
        // Lands while the offline sheet is still playing.
        final backend = FakeBackend()
          ..scorer = (_) => Future<Object?>.delayed(
            AiScorer.timeout + const Duration(seconds: 1),
            () => _verdict,
          );
        final rig = await playToDebrief(tester, _scorer(backend));
        await rig.until(
          find.text(ScoreSourceLabel.offlineLabel),
          timeout: AiScorer.timeout + const Duration(seconds: 3),
        );
        final offline = rig.state(1).score!.total;
        final banner = find.text(LateVerdictBanner.title).hitTestable();
        await rig.run(const Duration(seconds: 2));
        // Arrived, but the sheet is mid-timeline: nothing changes under the player.
        expect(banner, findsNothing);
        expect(tester.widget<Dossier>(find.byType(Dossier)).total, offline);
        await rig.settleDossier();
        await rig.until(banner);
        expect(find.text(ScoreSourceLabel.offlineLabel), findsOneWidget);
        expect(tester.widget<Dossier>(find.byType(Dossier)).total, offline);
        expect(rig.analytics.count(AnalyticsEvent.aiScoreShown), 0);
        final stamps = rig.sounds.count('scoreStamped');
        final slides = rig.sounds.count('dossierSlides');
        await tester.tap(banner);
        await rig.run(const Duration(seconds: 2));
        expect(find.text(ScoreSourceLabel.aiLabel), findsOneWidget);
        expect(tester.widget<Dossier>(find.byType(Dossier)).total, 74);
        expect(find.byType(AiBasisSlip), findsOneWidget);
        expect(banner, findsNothing);
        // Swapped in place: no second slide, no stamps again.
        expect(rig.sounds.count('scoreStamped'), stamps);
        expect(rig.sounds.count('dossierSlides'), slides);
        expect(
          rig.analytics.only(AnalyticsEvent.aiScoreShown).wire['late'],
          isTrue,
        );
      },
    );

    testWidgets(
      'no backend (the zero-setup run): straight to "Offline score", no waiting',
      (tester) async {
        final rig = await playToDebrief(tester, null);
        await rig.until(find.byType(Dossier));
        expect(find.byType(DeliberationScene), findsNothing);
        expect(find.text(ScoreSourceLabel.offlineLabel), findsOneWidget);
        expect(rig.analytics.count(AnalyticsEvent.aiScoreRequested), 0);
        expect(
          rig.analytics.only(AnalyticsEvent.aiScoreFallback).wire['reason'],
          'noBackend',
        );
        await rig.settleDossier();
      },
    );

    Future<void> openBasis(MissionRig rig) async {
      final open = find.text(ScoringBasisSheet.open);
      final button = open.evaluate().isEmpty
          ? find.text(ScoringBasisSheet.open)
          : open;
      await rig.until(button);
      await rig.tester.ensureVisible(button);
      await rig.tester.pump();
      await rig.tester.tap(button);
      await rig.until(find.byType(ScoringBasisSheet));
      await rig.run(const Duration(seconds: 1));
    }

    testWidgets(
      '"How we scored this" with the AI: who scored, the weights, both scores, what it is told',
      (tester) async {
        final backend = FakeBackend()..scorer = (_) async => _verdict;
        final rig = await playToDebrief(tester, _scorer(backend));
        await rig.until(find.byType(Dossier));
        await rig.settleDossier();
        await openBasis(rig);
        expect(find.text(missionTheOpportunity.practises!), findsOneWidget);
        expect(find.text(ScoringBasisSheet.aiWho), findsOneWidget);
        for (final d in Dimension.values) {
          expect(find.textContaining('${d.weightPercent} %'), findsWidgets);
        }
        expect(
          find.text('Recruiter 74  ·  Game ${rig.state(1).score!.total}'),
          findsOneWidget,
        );
        expect(find.text(ScoringBasisSheet.neverSees), findsOneWidget);
        expect(rig.analytics.only(AnalyticsEvent.scoreBasisViewed).wire, {
          'mission_id': missionTheOpportunity.id,
          'source': 'ai',
        });
        await tester.ensureVisible(find.text(ScoringBasisSheet.close));
        await tester.tap(find.text(ScoringBasisSheet.close));
        await rig.run(const Duration(seconds: 1));
        expect(find.byType(ScoringBasisSheet), findsNothing);
      },
    );

    for (final (scale, still) in [(1.0, false), (2.0, true)]) {
      testWidgets(
        '"How we scored this" offline, ${scale}x text, reduced motion: $still',
        (tester) async {
          final rig = await playToDebrief(
            tester,
            null,
            textScale: scale,
            reduceMotion: still,
          );
          await rig.until(find.byType(Dossier));
          await rig.settleDossier();
          await openBasis(rig);
          expect(find.text(ScoringBasisSheet.offlineWho), findsOneWidget);
          expect(find.textContaining('Recruiter '), findsNothing);
          expect(
            rig.analytics.only(AnalyticsEvent.scoreBasisViewed).wire['source'],
            'offline',
          );
        },
      );
    }
  });
}
