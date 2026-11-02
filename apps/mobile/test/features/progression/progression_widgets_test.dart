import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/audio/game_sounds.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/progression/debrief_rewards.dart';
import 'package:the_last_room/features/progression/interview_date_choices.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/progression/progression_card.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/progression/skill_badges.dart';

import 'progression_test.dart' show attempt;

class _Recording implements Analytics {
  final List<(AnalyticsEvent, Map<String, Object>)> events = [];

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) =>
      events.add((
        event,
        {for (final e in properties.entries) e.key: e.value.wire},
      ));
}

class _Sounds extends SilentGameSounds {
  int unlocks = 0;

  @override
  void skillUnlocked() => unlocks++;
}

void main() {
  final now = DateTime(2026, 11, 4, 18);
  final m7 = missions.firstWhere((m) => m.number == 7);
  late InMemoryProgressRepository progress;
  late InMemoryProgressionStore store;
  late _Recording analytics;
  late _Sounds sounds;

  setUp(() {
    progress = InMemoryProgressRepository();
    store = InMemoryProgressionStore();
    analytics = _Recording();
    sounds = _Sounds();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    const size = Size(390, 1200);
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logProvider.overrideWithValue(Log(sink: (_) {})),
          analyticsProvider.overrideWithValue(analytics),
          gameSoundsProvider.overrideWithValue(sounds),
          progressRepositoryProvider.overrideWithValue(progress),
          progressionStoreProvider.overrideWithValue(store),
          progressionClockProvider.overrideWithValue(() => now),
        ],
        child: MediaQuery(
          data: const MediaQueryData(size: size, disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: BrandType.body,
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('the debrief shows the XP and celebrates a new skill once', (
    tester,
  ) async {
    await progress.recordAttempt(attempt(m7, 100, at: now));
    await pump(tester, DebriefRewards(mission: m7, grade: ChapterGrade.lobby));
    expect(
      find.text(
        DebriefRewards.xpGained(missionXp(total: 100, firstClear: true)),
      ),
      findsOneWidget,
    );
    expect(find.text(SkillCopy.name(Skill.evidenceBuilder)), findsOneWidget);
    expect(sounds.unlocks, 1);
    expect(analytics.events.single.$1, AnalyticsEvent.skillUnlocked);
    expect(analytics.events.single.$2, {'skill_id': 'evidenceBuilder'});
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(store.record.celebrated, {Skill.evidenceBuilder});
  });

  testWidgets('a skill already celebrated is not celebrated again', (
    tester,
  ) async {
    await progress.recordAttempt(attempt(m7, 100, at: now));
    store.record = const ProgressionRecord(celebrated: {Skill.evidenceBuilder});
    await pump(tester, DebriefRewards(mission: m7, grade: ChapterGrade.lobby));
    expect(find.text(DebriefRewards.unlockedKicker), findsNothing);
    expect(sounds.unlocks, 0);
    expect(analytics.events, isEmpty);
  });

  testWidgets('the progress card: XP, the week so far, badges, the countdown', (
    tester,
  ) async {
    await progress.recordAttempt(attempt(m7, 100, at: now));
    store.record = ProgressionRecord(interviewDate: CalendarDay(2026, 11, 9));
    await pump(tester, const ProgressionCard());
    expect(find.text(ProgressionCard.weekLine(1, 3)), findsOneWidget);
    expect(find.text(ProgressionCard.countdown(5)), findsOneWidget);
    expect(find.bySemanticsLabel('Evidence Builder, earned'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Clear Introductions, earned in Mission 3'),
      findsOneWidget,
    );
  });

  test('the week line is never punishing', () {
    expect(
      ProgressionCard.weekLine(0, 3),
      'A new week: 0 of 3 sessions so far.',
    );
    expect(ProgressionCard.weekLine(2, 3), '2 of 3 sessions this week.');
    expect(ProgressionCard.weekLine(5, 3), contains('bonus'));
  });

  testWidgets('choosing an interview date saves it; "Not sure yet" clears it', (
    tester,
  ) async {
    await pump(tester, const InterviewDateChoices());
    await tester.tap(find.text('Next week'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(store.record.interviewDate, CalendarDay(2026, 11, 14));
    await tester.tap(find.text('Not sure yet'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(store.record.interviewDate, isNull);
  });
}
