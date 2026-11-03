import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/progression/floor_cleared_screen.dart';
import 'package:the_last_room/features/progression/progression.dart';
import 'package:the_last_room/features/progression/progression_store.dart';
import 'package:the_last_room/features/share/card_renderer.dart';
import 'package:the_last_room/features/share/card_sharer.dart';
import 'package:the_last_room/features/share/floor_card.dart';
import 'package:the_last_room/features/share/floor_card_facts.dart';
import 'package:the_last_room/features/share/share_floor_card_link.dart';

import '../progression/progression_test.dart' show attempt;

class _Recording implements Analytics {
  final List<(AnalyticsEvent, Map<String, Object>)> events = [];

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) =>
      events.add((
        event,
        {for (final e in properties.entries) e.key: e.value.wire},
      ));
}

/// Draws nothing: a few bytes stand in for the PNG.
class _FakeRenderer implements CardRenderer {
  final List<Widget> drawn = [];

  @override
  Future<Uint8List> render(
    Widget child, {
    required Size size,
    required double pixelRatio,
    required ui.FlutterView view,
  }) async {
    drawn.add(child);
    return Uint8List.fromList(const [1, 2, 3]);
  }
}

class _FakeSharer implements CardSharer {
  _FakeSharer({this.outcome = ShareOutcome.shared, this.fails = false});

  final ShareOutcome outcome;
  final bool fails;
  final List<({Uint8List png, String fileName, String text})> shared = [];

  @override
  Future<ShareOutcome> share({
    required Uint8List png,
    required String fileName,
    required String text,
    ui.Rect? origin,
  }) async {
    if (fails) throw Exception('no share target');
    shared.add((png: png, fileName: fileName, text: text));
    return outcome;
  }
}

void main() {
  final now = DateTime(2026, 11, 4, 18);
  List<Mission> floor(int n) => [
    for (final m in missions)
      if (m.chapter == n) m,
  ];

  late InMemoryProgressRepository progress;
  late _Recording analytics;
  late _FakeRenderer renderer;
  late List<String> logged;

  setUp(() {
    progress = InMemoryProgressRepository();
    analytics = _Recording();
    renderer = _FakeRenderer();
    logged = [];
  });

  Future<void> clearFloor(int n, {int first = 41, int last = 72}) async {
    final rooms = floor(n);
    for (final (i, m) in rooms.indexed) {
      await progress.recordAttempt(
        attempt(
          m,
          i == 0 ? first : (i == rooms.length - 1 ? last : 80),
          at: now,
        ),
      );
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required CardSharer sharer,
    String? name,
  }) async {
    const size = Size(390, 1400);
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logProvider.overrideWithValue(
            Log(sink: (r) => logged.add(r.message)),
          ),
          analyticsProvider.overrideWithValue(analytics),
          gameSoundsProvider.overrideWithValue(const SilentGameSounds()),
          progressRepositoryProvider.overrideWithValue(progress),
          progressionStoreProvider.overrideWithValue(
            InMemoryProgressionStore(),
          ),
          progressionClockProvider.overrideWithValue(() => now),
          profileRepositoryProvider.overrideWithValue(
            InMemoryProfileRepository(PlayerProfile(firstName: name)),
          ),
          cardRendererProvider.overrideWithValue(renderer),
          cardSharerProvider.overrideWithValue(sharer),
        ],
        child: MediaQuery(
          data: const MediaQueryData(size: size, disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: [OverlayEntry(builder: (_) => child)],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> tapShare(WidgetTester tester) async {
    await tester.tap(find.text(ShareFloorCardLink.label));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump();
  }

  group('the facts', () {
    test('floor 1: its name, its medals, then vs now, the name typed', () {
      final rooms = floor(1);
      final facts = FloorCardFacts.of(
        floor: 1,
        progression: const Progression(
          xp: 1247,
          lastXp: 0,
          unlocked: {Skill.clearIntroductions, Skill.evidenceBuilder},
          uncelebrated: {},
          sessionsThisWeek: 0,
          weeklyGoal: 3,
        ),
        attempts: [
          attempt(rooms.first, 41),
          attempt(rooms.first, 60, number: 2),
          attempt(rooms.last, 65),
          attempt(rooms.last, 72, number: 2),
        ],
        name: '  Sami. ',
      );
      expect(facts.title, chapters.first.title);
      expect(facts.rooms, 7);
      expect(facts.skills, [Skill.clearIntroductions, Skill.evidenceBuilder]);
      // The first room's first try, the last room's latest.
      expect((facts.then, facts.now), (41, 72));
      expect((facts.firstRoom, facts.lastRoom), (1, 7));
      expect(facts.hosts, hasLength(FloorCardFacts.hostCount));
      expect(facts.name, 'Sami');
      expect(
        FloorCard.shareText(facts),
        'I cleared floor 1 of The Last Room: Get through the door. '
        'thelastroom-ten.vercel.app',
      );
    });

    test('no name typed: none on the card; no medal earned: none shown', () {
      final facts = FloorCardFacts.of(
        floor: 2,
        progression: Progression.empty,
        attempts: const [],
        name: '   ',
      );
      expect(facts.name, isNull);
      expect(facts.skills, isEmpty);
      expect(facts.hasThenNow, isFalse);
    });
  });

  testWidgets('floor cleared shows the link; a tap shares the card', (
    tester,
  ) async {
    await clearFloor(1);
    final sharer = _FakeSharer();
    await pump(tester, const FloorClearedScreen(floor: 1), sharer: sharer);
    expect(find.text(ShareFloorCardLink.label), findsOneWidget);

    await tapShare(tester);

    final card = renderer.drawn.single as FloorCard;
    expect(card.facts.floor, 1);
    expect((card.facts.then, card.facts.now), (41, 72));
    expect(sharer.shared.single.fileName, 'the-last-room-floor-1.png');
    expect(
      sharer.shared.single.text,
      'I cleared floor 1 of The Last Room: Get through the door. '
      'thelastroom-ten.vercel.app',
    );
    expect(analytics.events.last.$1, AnalyticsEvent.floorCardShared);
    expect(analytics.events.last.$2, {'floor': 1, 'outcome': 'shared'});
    expect(find.text(ShareFloorCardLink.trouble), findsNothing);
  });

  testWidgets('closing the sheet is reported as dismissed, quietly', (
    tester,
  ) async {
    await clearFloor(2);
    final sharer = _FakeSharer(outcome: ShareOutcome.dismissed);
    await pump(tester, const ShareFloorCardLink(floor: 2), sharer: sharer);

    await tapShare(tester);

    expect(analytics.events.last.$1, AnalyticsEvent.floorCardShared);
    expect(analytics.events.last.$2, {'floor': 2, 'outcome': 'dismissed'});
    expect(find.text(ShareFloorCardLink.trouble), findsNothing);
  });

  testWidgets('sharing that fails shows the calm bubble, logs, and clears', (
    tester,
  ) async {
    await clearFloor(1);
    await pump(
      tester,
      const ShareFloorCardLink(floor: 1),
      sharer: _FakeSharer(fails: true),
    );

    await tapShare(tester);

    expect(find.text(ShareFloorCardLink.trouble), findsOneWidget);
    expect(analytics.events.last.$1, AnalyticsEvent.floorCardShared);
    expect(analytics.events.last.$2, {'floor': 1, 'outcome': 'unavailable'});
    expect(logged, contains('floor card not shared'));
    // The link is ready again.
    expect(find.text(ShareFloorCardLink.label), findsOneWidget);

    await tester.pump(ShareFloorCardLink.troubleFor);
    await tester.pump();
    expect(find.text(ShareFloorCardLink.trouble), findsNothing);
  });

  testWidgets('the name the player typed goes on the card, trimmed', (
    tester,
  ) async {
    await clearFloor(3);
    await pump(
      tester,
      const ShareFloorCardLink(floor: 3),
      sharer: _FakeSharer(),
      name: 'Sami. ',
    );

    await tapShare(tester);

    final card = renderer.drawn.single as FloorCard;
    expect(card.facts.name, 'Sami');
    expect(card.facts.title, chapters.last.title);
  });

  testWidgets('the real renderer makes a 1080 × 1350 PNG', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final facts = FloorCardFacts.of(
      floor: 1,
      progression: Progression.empty,
      attempts: const [],
    );
    final png = await tester.runAsync(
      () => const OffscreenCardRenderer().render(
        FloorCard(facts: facts),
        size: FloorCard.size,
        pixelRatio: FloorCard.pixelRatio,
        view: tester.view,
      ),
    );
    final bytes = ByteData.sublistView(png!);
    // The PNG signature, then IHDR's width and height.
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
    expect(bytes.getUint32(16), 1080);
    expect(bytes.getUint32(20), 1350);
  });
}
