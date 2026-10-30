import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/features/debrief/debrief_facts.dart';
import 'package:the_last_room/features/debrief/debrief_view.dart';
import 'package:the_last_room/features/debrief/red_pen_slip.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/widgets/beat_timer.dart';
import 'package:the_last_room/ui/film_kit.dart';

import 'mission_harness.dart';

/// A known path through Mission 1: a strong open, the "we" evidence (so Priya asks "What was
/// your part?"), a strong land, and the half-credit reply.
const List<String> _beats = [
  'm01_open_role_fit',
  'm01_evidence_team_did',
  'm01_land_bring_habit',
];
const String _reply = 'm01_reply_part_led_it';

/// What the engine says that path scores, computed here from content, not from the screen.
MissionScore _expected() {
  const m = missionTheOpportunity;
  final picks = [
    for (var i = 0; i < _beats.length; i++)
      BeatPick(beat: m.beats[i].kind, choice: m.optionById(_beats[i])!.scored),
  ];
  return scoreAttempt(
    AttemptInput(
      picks: picks,
      followUpReply: m.optionById(_reply)!.scored,
      hinted: m.hinted,
    ),
  );
}

void main() {
  Future<MissionRig> playMissionOne(
    WidgetTester tester, {
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    final rig = MissionRig(tester);
    await rig.boot(
      Routes.mission(1),
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    await rig.play(1, beats: _beats, reply: _reply);
    return rig;
  }

  testWidgets(
    'Mission 1 plays end to end; the dossier shows the engine score',
    (tester) async {
      final rig = await playMissionOne(tester);
      await rig.settleDossier();

      final expected = _expected();
      final dossier = tester.widget<Dossier>(find.byType(Dossier));
      expect(dossier.total, expected.total);
      expect(
        {for (final s in dossier.scores) s.label: s.value},
        {
          for (final d in Dimension.values)
            dimensionLabel(d): expected.dimensions[d],
        },
      );
      expect(find.text('${expected.total}'), findsOneWidget);

      // The follow-up came from the engine: the "we" line drew "What was your part?".
      expect(rig.state(1).followUp!.id, 'm01_follow_your_part');

      // The red pen quotes the costliest line with a lesson, and teaches that lesson.
      final facts = DebriefFacts.of(missionTheOpportunity, expected);
      expect(facts.markedLine!.id, expected.optionIdsByCost.first);
      final slip = tester.widget<RedPenSlip>(find.byType(RedPenSlip));
      expect(slip.line, facts.markedLine!.text);
      expect(slip.lesson.id, facts.markedLine!.lessonId);
      expect(find.text(slip.lesson.takeaway), findsOneWidget);

      // The attempt is stored, with the order it was shown in.
      final stored = await rig.progress.attempts();
      expect(stored.single.score, expected);
      expect(stored.single.beatOptionIds, _beats);
      expect(stored.single.seed, testSeed);
      expect(stored.single.draft, isNull);
      expect(await rig.progress.baseline(), same(stored.single));
    },
  );

  testWidgets('every mission event fires exactly once, with ids, never text', (
    tester,
  ) async {
    final rig = await playMissionOne(tester);
    await rig.settleDossier();
    final a = rig.analytics;
    for (final event in [
      AnalyticsEvent.missionStarted,
      AnalyticsEvent.draftCompleted,
      AnalyticsEvent.followUpAnswered,
      AnalyticsEvent.missionCompleted,
      AnalyticsEvent.baselineRecorded,
      AnalyticsEvent.userActivated,
    ]) {
      expect(a.count(event), 1, reason: event.wireName);
    }
    expect(a.count(AnalyticsEvent.answerTimerExpired), 0);
    expect(a.only(AnalyticsEvent.missionStarted).wire, {
      'mission_id': 'm01_the_opportunity',
      'chapter': 1,
      'attempt_number': 1,
    });
    expect(a.only(AnalyticsEvent.draftCompleted).wire['skipped'], isTrue);
    expect(a.only(AnalyticsEvent.followUpAnswered).wire, {
      'mission_id': 'm01_the_opportunity',
      'follow_up_id': 'm01_follow_your_part',
    });
    final bucket = ScoreBucket.of(_expected().total).name;
    expect(
      a.only(AnalyticsEvent.missionCompleted).wire['score_bucket'],
      bucket,
    );
    expect(a.only(AnalyticsEvent.baselineRecorded).wire, {
      'score_bucket': bucket,
    });
  });

  testWidgets(
    'every sound moment is called; no timer sound on untimed Mission 1',
    (tester) async {
      final rig = await playMissionOne(tester);
      await rig.settleDossier();
      final s = rig.sounds;
      expect(s.argsOf('chapterCard'), [
        [1],
      ]);
      expect(s.argsOf('ambience').first, [1]);
      expect(s.count('subtitleCharacter'), greaterThan(0));
      expect(s.argsOf('subtitleCharacter').map((a) => a.first).toSet(), {
        'priya',
      });
      expect(s.count('subtitleCompleted'), greaterThan(0));
      expect(s.count('questionLands'), 1);
      expect(s.count('choiceTapped'), 4);
      expect(s.count('answerLocked'), 4);
      expect(s.count('trustChanged'), greaterThan(0));
      expect(s.argsOf('followUpChallenge'), [
        ['priya'],
      ]);
      expect(s.count('dossierSlides'), 1);
      expect(s.count('scoreStamped'), 4);
      expect(s.count('result'), 1);
      expect(s.count('timerPulse'), 0);

      // Leaving the scene stops everything.
      rig.container.read(routerProvider).go(Routes.home);
      await rig.run(const Duration(milliseconds: 500));
      expect(s.count('stopAll'), greaterThan(0));
    },
  );

  testWidgets('Mission 1 has no timer', (tester) async {
    final rig = MissionRig(tester);
    await rig.boot(Routes.mission(1));
    await rig.playLines(1);
    await rig.skipDraft();
    await rig.until(find.byType(AnswerCard));
    expect(find.byType(BeatTimer), findsNothing);
    // A minute and more passes: no timer starts and nothing expires.
    await rig.run(
      const Duration(seconds: 65),
      step: const Duration(seconds: 1),
    );
    expect(find.byType(BeatTimer), findsNothing);
    expect(rig.analytics.count(AnalyticsEvent.answerTimerExpired), 0);
  });

  testWidgets(
    'options appear in the attempt\'s seeded order, not the file\'s',
    (tester) async {
      final rig = MissionRig(tester);
      await rig.boot(Routes.mission(1));
      await rig.playLines(1);
      await rig.skipDraft();
      await rig.until(find.byType(AnswerCard));
      final shown = tester
          .widgetList<AnswerCard>(find.byType(AnswerCard))
          .map((c) => c.text)
          .toList();
      final seeded = shuffled(
        missionTheOpportunity.beats.first.options,
        seed: testSeed,
      ).map((o) => o.text).toList();
      final fileOrder = missionTheOpportunity.beats.first.options
          .map((o) => o.text)
          .toList();
      expect(shown, seeded);
      expect(shown, isNot(fileOrder));
    },
  );

  testWidgets('survives 2x text from the scene to the dossier', (tester) async {
    final rig = await playMissionOne(tester, textScale: 2);
    await rig.settleDossier();
    expect(find.byType(DebriefView), findsOneWidget);
  });

  testWidgets(
    'reduced motion: every camera move is a cross-fade, and it still plays',
    (tester) async {
      final rig = await playMissionOne(tester, reduceMotion: true);
      await rig.settleDossier();
      expect(find.byType(DebriefView), findsOneWidget);
      // The dossier is settled at once; the slip and the way on are there.
      expect(find.byType(RedPenSlip), findsOneWidget);
      expect(
        find.text(
          DebriefView.continueLabel(missionTheOpportunity.next).toUpperCase(),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('after the dossier, the next mission starts', (tester) async {
    final rig = await playMissionOne(tester);
    await rig.settleDossier();
    final next = find.text(
      DebriefView.continueLabel(missionTellMeAboutYourself).toUpperCase(),
    );
    await tester.ensureVisible(next);
    await tester.tap(next);
    await rig.until(find.byType(ChapterTitleCard));
    expect(rig.state(2).mission, missionTellMeAboutYourself);
  });
}
