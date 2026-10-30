import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/debrief_facts.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';

import 'mission_harness.dart';

void main() {
  late RecordingAnalytics analytics;
  late InMemoryProgressRepository progress;
  late ProviderContainer container;

  setUp(() {
    analytics = RecordingAnalytics();
    progress = InMemoryProgressRepository();
    container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        progressRepositoryProvider.overrideWithValue(progress),
        attemptSeedProvider.overrideWithValue(() => testSeed),
        profileRepositoryProvider.overrideWithValue(
          InMemoryProfileRepository(onboardedPlayer),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());

  /// Plays mission [number] through the controller: option [pick] of each beat (in file
  /// order, not the screen's), then reply [pick].
  Future<MissionState> play(int number, {String? draft, int pick = 0}) async {
    final provider = missionControllerProvider(number);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);
    final c = container.read(provider.notifier)..sceneStarted();
    if (container.read(provider).requireValue.mission.offersDraft) {
      c.finishDraft(draft);
    }
    for (final beat in container.read(provider).requireValue.mission.beats) {
      c.lock(beat.options[pick]);
    }
    final state = container.read(provider).requireValue;
    await c.answerFollowUp(state.followUp!.replies[pick]);
    return container.read(provider).requireValue;
  }

  test('the score is the engine\'s, for the picks made', () async {
    final s = await play(1);
    final m = s.mission;
    expect(
      s.score,
      scoreAttempt(
        AttemptInput(
          picks: [
            for (final b in m.beats)
              BeatPick(beat: b.kind, choice: b.options.first.scored),
          ],
          followUpReply: s.followUp!.replies.first.scored,
          hinted: m.hinted,
        ),
      ),
    );
  });

  test(
    'a second attempt counts up; the baseline and activation fire only once',
    () async {
      await play(1);
      container.invalidate(missionControllerProvider(1));
      final second = await play(1);
      expect(second.attemptNumber, 2);
      expect(analytics.count(AnalyticsEvent.baselineRecorded), 1);
      expect(analytics.count(AnalyticsEvent.userActivated), 1);
      expect(analytics.count(AnalyticsEvent.missionCompleted), 2);
      final baseline = await progress.baseline();
      expect(baseline!.attemptNumber, 1);
    },
  );

  test('a later mission first does not record a baseline', () async {
    await play(2);
    expect(analytics.count(AnalyticsEvent.baselineRecorded), 0);
    expect(analytics.count(AnalyticsEvent.userActivated), 1);
  });

  test('the draft stays on the device: stored, never in an event', () async {
    const words = 'I want to work on things people use every day.';
    await play(1, draft: words);
    final stored = (await progress.attempts()).single;
    expect(stored.draft, words);
    expect(
      analytics.only(AnalyticsEvent.draftCompleted).wire['skipped'],
      isFalse,
    );
    for (final e in analytics.events) {
      for (final value in e.wire.values) {
        expect(value, isNot(contains('people use')));
      }
    }
  });

  test('a blank draft is a skip', () async {
    await play(1, draft: '   ');
    expect(
      analytics.only(AnalyticsEvent.draftCompleted).wire['skipped'],
      isTrue,
    );
    expect((await progress.attempts()).single.draft, isNull);
  });

  test('a line from another beat, or a second reply, is ignored', () async {
    final provider = missionControllerProvider(1);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);
    final c = container.read(provider.notifier);
    const m = missionTheOpportunity;
    c.lock(m.beats[1].options.first); // not the open beat's
    expect(container.read(provider).requireValue.picks, isEmpty);
    for (final b in m.beats) {
      c.lock(b.options.first);
    }
    final replies = container.read(provider).requireValue.followUp!.replies;
    await c.answerFollowUp(replies.first);
    await c.answerFollowUp(replies.last);
    expect(analytics.count(AnalyticsEvent.followUpAnswered), 1);
    expect(await progress.attempts(), hasLength(1));
  });

  test(
    'Mission 6 quotes the costliest line of the mission it calls back to',
    () async {
      const m6 = missionTheFollowUpTrap;
      final from = missions.firstWhere(
        (m) => m.id == m6.continuity!.fromMissionId,
      );
      final s = await play(from.number);
      final provider = missionControllerProvider(m6.number);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final six = await container.read(provider.future);
      final line = m6.continuity!.lineFor(s.score!.optionIdsByCost);
      expect(line, isNotNull);
      expect(six.scene.map((l) => l.text), [
        for (final l in [...m6.scene, line!]) l.addressedTo(testName).text,
      ]);
    },
  );

  test('the interviewers call the player by their first name', () async {
    final provider = missionControllerProvider(1);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    final one = await container.read(provider.future);
    expect(
      one.scene.first.text,
      "Hi $testName, I'm Priya. "
      'I hire for the product team here at Northstar Labs.',
    );
    final candidate = player.name.split(' ').first;
    for (final line in [...one.scene, one.question]) {
      expect(line.text, isNot(contains(candidate)));
    }
  });

  test('a player who skipped their name is called Candidate', () {
    const line = SceneLine(speakerId: 'priya', text: 'Last one, Jordan.');
    expect(
      line.addressedTo(PlayerProfile.fallbackName).text,
      'Last one, Candidate.',
    );
    // A whole word only: never inside another word.
    const other = SceneLine(speakerId: 'priya', text: 'Jordanian food.');
    expect(other.addressedTo('Sami').text, 'Jordanian food.');
  });

  test('an unknown mission number is an error, not a crash', () async {
    final provider = missionControllerProvider(99);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      container.read(provider.future),
      throwsA(isA<MissionNotFound>()),
    );
  });

  test('the timer event names the beat, only on a timed mission', () async {
    final provider = missionControllerProvider(1);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);
    container.read(provider.notifier).timerExpired();
    expect(analytics.count(AnalyticsEvent.answerTimerExpired), 0);

    final two = missionControllerProvider(2);
    final sub2 = container.listen(two, (_, _) {});
    addTearDown(sub2.close);
    await container.read(two.future);
    container.read(two.notifier).timerExpired();
    expect(analytics.only(AnalyticsEvent.answerTimerExpired).wire, {
      'mission_id': 'm02_tell_me_about_yourself',
      'beat': 'open',
    });
  });

  group('debrief facts', () {
    test('the red pen marks the costliest line that has a lesson', () async {
      final s = await play(1, pick: 1);
      final facts = DebriefFacts.of(s.mission, s.score!);
      final firstTaught = s.score!.optionIdsByCost
          .map((id) => s.mission.optionById(id)!)
          .firstWhere((o) => o.lessonId != null);
      expect(facts.markedLine, firstTaught);
      expect(facts.lesson!.id, firstTaught.lessonId);
      expect(
        facts.markedDimensionIndex,
        Dimension.values.indexOf(facts.lesson!.flag.lowers),
      );
    });

    test('a clean run has no red pen and no lesson', () {
      const m = missionTheOpportunity;
      final strong = [
        for (final b in m.beats)
          b.options.reduce((a, b) => _points(a) >= _points(b) ? a : b),
      ];
      final followUp = m.followUpById(
        selectFollowUp(
          picks: [
            for (var i = 0; i < 3; i++)
              BeatPick(beat: m.beats[i].kind, choice: strong[i].scored),
          ],
          candidates: [for (final f in m.followUps) f.candidate],
        ),
      );
      final score = scoreAttempt(
        AttemptInput(
          picks: [
            for (var i = 0; i < 3; i++)
              BeatPick(beat: m.beats[i].kind, choice: strong[i].scored),
          ],
          followUpReply: followUp.replies
              .firstWhere((r) => r.lessonId == null)
              .scored,
          hinted: false,
        ),
      );
      final facts = DebriefFacts.of(m, score);
      expect(facts.markedLine, isNull);
      expect(facts.lesson, isNull);
      expect(facts.strong, isTrue);
    });
  });
}

int _points(AnswerOption o) =>
    o.scores.relevance + o.scores.specificity + o.scores.structure;
