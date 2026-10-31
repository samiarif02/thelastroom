import 'dart:async';

import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/backend/backend.dart';
import 'package:the_last_room/core/env/env.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_verdict_cards.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
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
      AiScorer? scorer,
    ) async {
      final rig = MissionRig(tester)..scorer = scorer;
      await rig.boot(Routes.mission(1));
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
        await rig.until(find.byType(DeliberatingCard));
        expect(find.byType(Dossier), findsNothing);
        await rig.until(find.byType(Dossier));
        expect(
          find.text(ScoreSourceLabel.aiLabel.toUpperCase()),
          findsOneWidget,
        );
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
        await rig.until(find.byType(DeliberatingCard));
        await rig.until(
          find.byType(Dossier),
          timeout: AiScorer.timeout + const Duration(seconds: 3),
        );
        expect(
          find.text(ScoreSourceLabel.offlineLabel.toUpperCase()),
          findsOneWidget,
        );
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
      'no backend (the zero-setup run): straight to "Offline score", no waiting',
      (tester) async {
        final rig = await playToDebrief(tester, null);
        await rig.until(find.byType(Dossier));
        expect(find.byType(DeliberatingCard), findsNothing);
        expect(
          find.text(ScoreSourceLabel.offlineLabel.toUpperCase()),
          findsOneWidget,
        );
        expect(rig.analytics.count(AnalyticsEvent.aiScoreRequested), 0);
        expect(
          rig.analytics.only(AnalyticsEvent.aiScoreFallback).wire['reason'],
          'noBackend',
        );
        await rig.settleDossier();
      },
    );
  });
}
