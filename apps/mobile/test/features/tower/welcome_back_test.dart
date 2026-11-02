import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/logging/log.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/progression/progression_card.dart';
import 'package:the_last_room/features/recall/recall_controller.dart';
import 'package:the_last_room/features/tower/tower_rooms.dart';
import 'package:the_last_room/features/tower/welcome_back.dart';
import 'package:the_last_room/features/tower/welcome_back_card.dart';

import '../../core/notifications/reminder_fakes.dart' show RecordingAnalytics;
import '../../ui/harness.dart';
import 'played_attempt.dart';

class MemoryLastVisitStore implements LastVisitStore {
  MemoryLastVisitStore([this.saved]);

  DateTime? saved;

  @override
  Future<DateTime?> load() async => saved;

  @override
  Future<void> save(DateTime at) async => saved = at;
}

void main() {
  // A Wednesday morning.
  final now = DateTime(2026, 11, 4, 9, 30);
  final newPlayer = towerRooms(missions, const []);
  const week = Progression(
    xp: 40,
    lastXp: 0,
    unlocked: {},
    uncelebrated: {},
    sessionsThisWeek: 1,
    weeklyGoal: 3,
  );

  group('when it shows (pure)', () {
    test('calendar days away, not 24-hour spans', () {
      expect(daysAway(null, now), isNull);
      expect(daysAway(DateTime(2026, 11, 4, 7), now), 0);
      expect(daysAway(DateTime(2026, 11, 3, 23, 50), now), 1);
      expect(daysAway(DateTime(2026, 10, 30, 12), now), 5);
      expect(daysAway(DateTime(2026, 11, 5, 8), now), -1);
    });

    test('a day or more away: yes; a first visit, the same day, a clock '
        'gone backwards: no', () {
      expect(welcomesBack(1), isTrue);
      expect(welcomesBack(5), isTrue);
      expect(welcomesBack(null), isFalse);
      expect(welcomesBack(0), isFalse);
      expect(welcomesBack(-1), isFalse);
    });
  });

  group('what it says (pure)', () {
    test('cards due come first, then the next room, then the week', () {
      final w = welcomeBackFor(
        recallDue: 3,
        next: heroRoom(newPlayer),
        progress: week,
      );
      final m1 = missions.first;
      expect(w.waiting, [
        '3 traps are waiting in the Recall Room.',
        'Room 1, “${m1.title}”, is ready for you.',
        ProgressionCard.weekLine(1, 3),
      ]);
      expect(w.target, WelcomeBackTarget.recall);
      expect(w.action, 'Open the Recall Room');
      expect(w.speaker, 'Priya');
      expect(w.kicker, 'WELCOME BACK · PRIYA');
    });

    test('nothing due: the next room, in its interviewer\'s voice', () {
      final played = [for (final m in missions.take(3)) playedAttempt(m)];
      final next = heroRoom(towerRooms(missions, played))!;
      final w = welcomeBackFor(recallDue: 0, next: next, progress: week);
      expect(w.target, WelcomeBackTarget.mission);
      expect(w.missionNumber, next.mission.number);
      expect(w.action, 'Start Room ${next.mission.number}');
      expect(w.interviewerId, next.mission.question.speakerId);
      expect(w.waiting, hasLength(2));
    });

    test('never shaming: no day count, no "missed", no exclamation', () {
      for (final id in ['priya', 'marcus', 'lena', 'sam']) {
        final w = WelcomeBack(
          interviewerId: id,
          waiting: const [],
          target: WelcomeBackTarget.progress,
        );
        expect(w.greeting, isNot(contains('!')), reason: id);
        expect(w.greeting, isNot(matches(RegExp(r'\d'))), reason: id);
        expect(w.greeting.toLowerCase(), isNot(contains('miss')), reason: id);
      }
      expect(ProgressionCard.weekLine(0, 3), contains('so far'));
    });

    test('no room at all: the player\'s file', () {
      final w = welcomeBackFor(recallDue: 0, next: null, progress: week);
      expect(w.target, WelcomeBackTarget.progress);
      expect(w.speaker, 'Priya');
    });
  });

  group('once per return (the controller)', () {
    late MemoryLastVisitStore visits;
    late RecordingAnalytics analytics;
    var clock = now;

    ProviderContainer container(DateTime? lastVisit) {
      visits = MemoryLastVisitStore(lastVisit);
      analytics = RecordingAnalytics();
      clock = now;
      final c = ProviderContainer(
        overrides: [
          logProvider.overrideWithValue(Log(sink: (_) {})),
          analyticsProvider.overrideWithValue(analytics),
          lastVisitStoreProvider.overrideWithValue(visits),
          welcomeBackClockProvider.overrideWithValue(() => clock),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('shown after a day away; closed, not shown again that day', () async {
      final c = container(DateTime(2026, 11, 2, 21));
      final welcome = c.read(welcomeBackProvider.notifier);
      await welcome.arrive();
      expect(c.read(welcomeBackProvider), 2);
      welcome
        ..shown(WelcomeBackTarget.mission)
        ..shown(WelcomeBackTarget.mission);
      expect(analytics.events, hasLength(1), reason: 'reported once');
      welcome.close(WelcomeBackTarget.mission, followed: false);
      expect(c.read(welcomeBackProvider), isNull);
      // The app comes back to the front an hour later: still the same day.
      clock = now.add(const Duration(hours: 1));
      await welcome.arrive();
      expect(c.read(welcomeBackProvider), isNull);
      // And the next morning: a new return.
      clock = now.add(const Duration(days: 1));
      await welcome.arrive();
      expect(c.read(welcomeBackProvider), 1);
    });

    test('leaving records the end of the visit', () async {
      final c = container(null);
      clock = DateTime(2026, 11, 4, 23, 59);
      await c.read(welcomeBackProvider.notifier).leave();
      expect(visits.saved, clock);
    });

    test('a store that fails: no card, no crash', () async {
      final c = ProviderContainer(
        overrides: [
          logProvider.overrideWithValue(Log(sink: (_) {})),
          lastVisitStoreProvider.overrideWithValue(_BrokenStore()),
          welcomeBackClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      await c.read(welcomeBackProvider.notifier).arrive();
      await c.read(welcomeBackProvider.notifier).leave();
      expect(c.read(welcomeBackProvider), isNull);
    });
  });

  group('on the tower', () {
    late MemoryLastVisitStore visits;
    late RecordingAnalytics analytics;
    late GoRouter router;

    Future<void> pump(
      WidgetTester tester, {
      DateTime? lastVisit,
      int due = 2,
      bool quiet = false,
      double textScale = 1,
      bool reduceMotion = false,
    }) async {
      visits = MemoryLastVisitStore(lastVisit);
      analytics = RecordingAnalytics();
      Widget page(String text) => Center(child: Text(text));
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: WelcomeBackCard(quiet: quiet),
            ),
          ),
          GoRoute(path: Routes.recall, builder: (_, _) => page('recall')),
          GoRoute(path: Routes.progress, builder: (_, _) => page('file')),
          GoRoute(
            path: '/tower/mission/:n',
            builder: (_, s) => page('mission ${s.pathParameters['n']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          logProvider.overrideWithValue(Log(sink: (_) {})),
          analyticsProvider.overrideWithValue(analytics),
          lastVisitStoreProvider.overrideWithValue(visits),
          welcomeBackClockProvider.overrideWithValue(() => now),
          towerRoomsProvider.overrideWith((ref) async => newPlayer),
          recallDueCountProvider.overrideWith((ref) async => due),
          progressionProvider.overrideWith((ref) async => week),
        ],
      );
      addTearDown(container.dispose);
      await pumpKit(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: Router.withConfig(config: router),
        ),
        textScale: textScale,
        reduceMotion: reduceMotion,
      );
      await pumpThrough(tester, const Duration(seconds: 1));
    }

    List<AnalyticsEvent> fired() => [for (final e in analytics.events) e.$1];

    testWidgets('a first visit: no card, and the visit is remembered', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('WELCOME BACK · PRIYA'), findsNothing);
      expect(visits.saved, now);
      expect(fired(), isEmpty);
    });

    testWidgets('earlier today: no card', (tester) async {
      await pump(tester, lastVisit: DateTime(2026, 11, 4, 7));
      expect(find.text('WELCOME BACK · PRIYA'), findsNothing);
    });

    testWidgets('back from a mission (quiet): no card, even a day later', (
      tester,
    ) async {
      await pump(tester, lastVisit: DateTime(2026, 11, 3, 20), quiet: true);
      expect(find.text('WELCOME BACK · PRIYA'), findsNothing);
      expect(visits.saved, now);
    });

    for (final (scale, reduced) in [(1.0, false), (2.0, true)]) {
      final at = ' (text ${scale}x${reduced ? ', reduced motion' : ''})';

      testWidgets('a day away: the card, and its button opens the Recall '
          'Room$at', (tester) async {
        await pump(
          tester,
          lastVisit: DateTime(2026, 11, 3, 20),
          textScale: scale,
          reduceMotion: reduced,
        );
        expect(find.text('WELCOME BACK · PRIYA'), findsOneWidget);
        expect(
          find.text('2 traps are waiting in the Recall Room.'),
          findsOneWidget,
        );
        expect(analytics.events.single.$1, AnalyticsEvent.welcomeBackShown);
        expect(analytics.events.single.$2, {
          'days_away': 1,
          'target': 'recall',
        });
        await tester.ensureVisible(find.text('Open the Recall Room'));
        await tester.tap(find.text('Open the Recall Room'));
        await pumpThrough(tester, const Duration(seconds: 1));
        expect(find.text('recall'), findsOneWidget);
        expect(analytics.events.last.$1, AnalyticsEvent.welcomeBackClosed);
        expect(analytics.events.last.$2, {
          'action': 'followed',
          'target': 'recall',
        });
      });

      testWidgets('dismissed: gone, reported once$at', (tester) async {
        await pump(
          tester,
          lastVisit: DateTime(2026, 10, 30),
          due: 0,
          textScale: scale,
          reduceMotion: reduced,
        );
        expect(find.text('Start Room 1'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(WelcomeBackCard.dismiss));
        await pumpThrough(tester, const Duration(seconds: 1));
        expect(find.text('WELCOME BACK · PRIYA'), findsNothing);
        expect(analytics.events.last.$2, {
          'action': 'dismissed',
          'target': 'mission',
        });
        expect(fired().where((e) => e == AnalyticsEvent.welcomeBackShown), [
          AnalyticsEvent.welcomeBackShown,
        ]);
      });
    }

    testWidgets('nothing due: its button starts the next room', (tester) async {
      await pump(tester, lastVisit: DateTime(2026, 11, 2), due: 0);
      await tester.tap(find.text('Start Room 1'));
      await pumpThrough(tester, const Duration(seconds: 1));
      expect(find.text('mission 1'), findsOneWidget);
    });
  });
}

class _BrokenStore implements LastVisitStore {
  @override
  Future<DateTime?> load() => Future.error(StateError('unreadable'));

  @override
  Future<void> save(DateTime at) => Future.error(StateError('unwritable'));
}
