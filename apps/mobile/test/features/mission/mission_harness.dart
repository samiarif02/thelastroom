import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_last_room/app/app.dart';
import 'package:the_last_room/app/providers.dart';
import 'package:the_last_room/app/router.dart';
import 'package:the_last_room/core/analytics/analytics.dart';
import 'package:the_last_room/core/analytics/analytics_event.dart';
import 'package:the_last_room/core/audio/game_sounds.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
import 'package:the_last_room/features/mission/scene/mission_card.dart';
import 'package:the_last_room/features/mission/widgets/draft_panel.dart';
import 'package:the_last_room/ui/film_kit.dart';

/// The seed every harness attempt is shuffled with.
const int testSeed = 42;

/// One recorded event, with its properties as the backend would get them.
typedef RecordedEvent = ({AnalyticsEvent event, Map<String, Object> wire});

class RecordingAnalytics implements Analytics {
  final List<RecordedEvent> events = [];

  @override
  void track(AnalyticsEvent event, [EventProperties properties = const {}]) =>
      events.add((
        event: event,
        wire: {
          for (final MapEntry(:key, :value) in properties.entries)
            key: value.wire,
        },
      ));

  int count(AnalyticsEvent event) =>
      events.where((e) => e.event == event).length;

  RecordedEvent only(AnalyticsEvent event) =>
      events.singleWhere((e) => e.event == event);
}

/// Records every [GameSounds] call by method name, with its arguments.
class RecordingSounds implements GameSounds {
  final List<(String, List<Object>)> calls = [];

  int count(String method) => calls.where((c) => c.$1 == method).length;
  List<List<Object>> argsOf(String method) => [
    for (final c in calls.where((c) => c.$1 == method)) c.$2,
  ];

  @override
  void subtitleCharacter(String interviewerId, String character) =>
      calls.add(('subtitleCharacter', [interviewerId, character]));

  @override
  void subtitleCompleted() => calls.add(('subtitleCompleted', const []));

  @override
  void questionLands() => calls.add(('questionLands', const []));

  @override
  void choiceTapped() => calls.add(('choiceTapped', const []));

  @override
  void answerLocked() => calls.add(('answerLocked', const []));

  @override
  void followUpChallenge(String interviewerId) =>
      calls.add(('followUpChallenge', [interviewerId]));

  @override
  void trustChanged({required bool rising}) =>
      calls.add(('trustChanged', [rising]));

  @override
  void timerPulse({required bool finalSeconds}) =>
      calls.add(('timerPulse', [finalSeconds]));

  @override
  void dossierSlides() => calls.add(('dossierSlides', const []));

  @override
  void scoreStamped() => calls.add(('scoreStamped', const []));

  @override
  void result({required bool strong}) => calls.add(('result', [strong]));

  @override
  void chapterCard(int chapter) => calls.add(('chapterCard', [chapter]));

  @override
  void ambience(int chapter) => calls.add(('ambience', [chapter]));

  @override
  void titleOpened() => calls.add(('titleOpened', const []));

  @override
  void uiTap() => calls.add(('uiTap', const []));

  @override
  void pageTurn() => calls.add(('pageTurn', const []));

  @override
  void towerOpened() => calls.add(('towerOpened', const []));

  @override
  void roomEntered() => calls.add(('roomEntered', const []));

  @override
  void elevator() => calls.add(('elevator', const []));

  @override
  void lockedRoomTapped() => calls.add(('lockedRoomTapped', const []));

  @override
  void stopAll() => calls.add(('stopAll', const []));
}

/// The app, booted at [location], with recording fakes and a pinned seed.
class MissionRig {
  MissionRig(this.tester);

  final WidgetTester tester;
  final RecordingAnalytics analytics = RecordingAnalytics();
  final RecordingSounds sounds = RecordingSounds();
  final InMemoryProgressRepository progress = InMemoryProgressRepository();
  late final ProviderContainer container;

  static const Size phone = Size(375, 667);

  Future<void> boot(
    String location, {
    Size size = phone,
    double textScale = 1,
    bool reduceMotion = false,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: location, routes: appRoutes());
    addTearDown(router.dispose);
    container = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        gameSoundsProvider.overrideWithValue(sounds),
        progressRepositoryProvider.overrideWithValue(progress),
        attemptSeedProvider.overrideWithValue(() => testSeed),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
          padding: viewPadding,
          viewPadding: viewPadding,
        ),
        child: UncontrolledProviderScope(
          container: container,
          child: const TheLastRoomApp(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Pumps in [step]s until [finder] finds something, failing on any frame that throws (an
  /// overflow mid-animation) or after [timeout].
  Future<void> until(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 100),
    void Function()? eachFrame,
  }) async {
    for (var e = Duration.zero; e < timeout; e += step) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(step);
      expect(tester.takeException(), isNull, reason: 'at $e');
      eachFrame?.call();
    }
    fail('timed out waiting for $finder');
  }

  /// Pumps [total] in [step]s, failing on any frame that throws.
  Future<void> run(
    Duration total, {
    Duration step = const Duration(milliseconds: 100),
    void Function()? eachFrame,
  }) async {
    for (var e = Duration.zero; e < total; e += step) {
      await tester.pump(step);
      expect(tester.takeException(), isNull, reason: 'at $e');
      eachFrame?.call();
    }
  }

  MissionState state(int number) =>
      container.read(missionControllerProvider(number)).requireValue;

  /// A tap on the scene itself, in the frame's top strip (clear of cards and the meter).
  Future<void> tapScene() async {
    await tester.tapAt(const Offset(8, 124));
    await tester.pump();
  }

  /// Skips the title card and plays the lines (letting each type a little, so the typing
  /// sound fires) up to the question landing and the push in.
  Future<void> playLines(int number) async {
    await until(find.byType(MissionCard));
    await tapScene();
    final lines = state(number).scene.length + 1;
    for (var i = 0; i < lines; i++) {
      await until(find.byType(TypewriterSubtitle));
      await run(const Duration(milliseconds: 300));
      if (typing) await tapScene(); // completes the line
      if (i < lines - 1) await tapScene(); // the next line
    }
  }

  /// Whether the subtitle on screen is still typing (never, under reduced motion).
  bool get typing {
    final text = tester.widget<TypewriterText>(find.byType(TypewriterText));
    return text.characters < text.text.length;
  }

  /// Picks [option] on screen: a tap to choose it, a tap to say it.
  Future<void> say(AnswerOption option) async {
    final card = find.widgetWithText(AnswerCard, option.text);
    await until(card);
    await tester.ensureVisible(card);
    await tester.pump();
    // At 2x text (and the test font's square glyphs) a card can be taller than the lower
    // third: tap the part of it that's on screen.
    Offset visible() {
      final view = tester.getRect(
        find.ancestor(of: card, matching: find.byType(SingleChildScrollView)),
      );
      final shown = tester.getRect(card).intersect(view);
      return Offset(shown.center.dx, shown.top + shown.height / 2);
    }

    await tester.tapAt(visible());
    await tester.pump();
    await tester.tapAt(visible());
    await tester.pump();
  }

  /// The draft step, skipped.
  Future<void> skipDraft() async {
    final skip = find.text(DraftPanel.skip.toUpperCase());
    await until(skip);
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pump();
  }

  /// Plays mission [number] from its card to the dossier with [beats] and [reply] (ids).
  Future<void> play(
    int number, {
    required List<String> beats,
    required String reply,
    bool draft = true,
  }) async {
    await playLines(number);
    final mission = state(number).mission;
    if (draft) await skipDraft();
    for (final id in beats) {
      await say(mission.allOptionsById[id]!);
    }
    // The follow-up's line, after the hard cut: let it type, then complete it.
    await until(find.text(state(number).followUp!.line.text));
    await run(const Duration(milliseconds: 300));
    if (typing) await tapScene();
    await say(mission.allOptionsById[reply]!);
    await until(find.byType(Dossier));
  }

  /// Plays the whole dossier through (stamps, seal, pen) and the slip arriving.
  Future<void> settleDossier() => run(BrandMotion.dossier + BrandMotion.pen);
}

extension on Mission {
  Map<String, AnswerOption> get allOptionsById => {
    for (final beat in beats)
      for (final o in beat.options) o.id: o,
    for (final f in followUps)
      for (final o in f.replies) o.id: o,
  };
}
