import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
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
import 'package:the_last_room/core/profile/profile_repository.dart';
import 'package:the_last_room/core/progress/progress_repository.dart';
import 'package:the_last_room/features/debrief/ai_score.dart';
import 'package:the_last_room/features/debrief/ai_score_store.dart';
import 'package:the_last_room/features/mission/mission_controller.dart';
import 'package:the_last_room/features/mission/mission_lookup.dart';
import 'package:the_last_room/features/mission/mission_resume.dart';
import 'package:the_last_room/features/mission/scene/mission_card.dart';
import 'package:the_last_room/features/mission/widgets/build_panel.dart';
import 'package:the_last_room/features/mission/widgets/choice_card.dart';
import 'package:the_last_room/features/mission/widgets/draft_panel.dart';
import 'package:the_last_room/features/mission/widgets/next_control.dart';
import 'package:the_last_room/ui/film_kit.dart';

/// How long the harness "reads" the cards before picking: well past `guessThreshold`.
const Duration readFor = Duration(milliseconds: 2500);

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

/// In-memory progress whose reads can be made to fail: the device store's error states.
class FlakyProgressRepository extends InMemoryProgressRepository {
  bool failReads = false;

  @override
  Future<List<AttemptRecord>> attempts({String? missionId}) {
    if (failReads) throw StateError('the store is unreadable');
    return super.attempts(missionId: missionId);
  }

  @override
  Future<AttemptRecord?> baseline() {
    if (failReads) throw StateError('the store is unreadable');
    return super.baseline();
  }
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
  void skillUnlocked() => calls.add(('skillUnlocked', const []));

  @override
  void stopAll() => calls.add(('stopAll', const []));
}

/// The player every rig starts as unless a test says otherwise: onboarded, named.
const PlayerProfile onboardedPlayer = PlayerProfile(
  firstName: testName,
  onboarded: true,
);

/// The name the rig's player gave in onboarding.
const String testName = 'Sami';

/// The app, booted at [location], with recording fakes and a pinned seed.
class MissionRig {
  MissionRig(this.tester, {PlayerProfile profile = onboardedPlayer})
    : profile = InMemoryProfileRepository(profile);

  final WidgetTester tester;
  final InMemoryProfileRepository profile;
  final RecordingAnalytics analytics = RecordingAnalytics();
  final RecordingSounds sounds = RecordingSounds();
  final FlakyProgressRepository progress = FlakyProgressRepository();
  final InMemoryResumeStore resume = InMemoryResumeStore();
  final InMemoryAiScoreStore aiScores = InMemoryAiScoreStore();
  late final ProviderContainer container;

  /// The debrief's AI scorer; null keeps the app's (no backend in tests: "Offline score").
  AiScorer? scorer;

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
        profileRepositoryProvider.overrideWithValue(profile),
        attemptSeedProvider.overrideWithValue(() => testSeed),
        resumeStoreProvider.overrideWithValue(resume),
        aiScoreStoreProvider.overrideWithValue(aiScores),
        routerProvider.overrideWithValue(router),
        if (scorer case final s?) aiScorerProvider.overrideWithValue(s),
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

  /// Records a played attempt (first options, read slowly) at every mission before [number], so
  /// the tower's rule (rooms open in order) lets a test start at [number]. Call before [boot].
  Future<void> unlockThrough(int number) async {
    for (final m in missions.where((m) => m.number < number)) {
      final beats = [
        for (final b in m.beats)
          BeatPick(beat: b.kind, choice: b.options.first.scored),
      ];
      final followUp = m.followUps.firstWhere((f) => f.trigger == null);
      await progress.recordAttempt(
        AttemptRecord(
          missionId: m.id,
          attemptNumber: 1,
          seed: testSeed,
          beatOptionIds: [for (final b in m.beats) b.options.first.id],
          followUpId: followUp.id,
          replyOptionId: followUp.replies.first.id,
          score: scoreAttempt(
            AttemptInput(
              picks: beats,
              followUpReply: followUp.replies.first.scored,
              hinted: m.hinted,
            ),
          ),
          hinted: m.hinted,
        ),
      );
    }
  }

  /// A tap on the scene itself, in the frame's top strip (clear of cards and the meter).
  Future<void> tapScene() async {
    await tester.tapAt(const Offset(8, 124));
    await tester.pump();
  }

  /// Skips the title card and plays the lines (letting each type a little, so the typing
  /// sound fires) up to the question landing and the push in: each line is completed with a
  /// tap, then moved on with one tap on the Next control.
  Future<void> playLines(int number) async {
    await until(find.byType(MissionCard));
    await tapScene();
    final lines = state(number).scene.length + 1;
    for (var i = 0; i < lines; i++) {
      await until(find.byType(TypewriterSubtitle));
      await run(const Duration(milliseconds: 300));
      if (typing) await tapScene(); // completes the line
      if (i < lines - 1) await tapNext(); // the next line
    }
  }

  /// One tap on the Next control under a typed line.
  Future<void> tapNext() async {
    final next = find.byType(NextControl);
    await until(next);
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tapAt(tester.getCenter(next));
    await tester.pump();
  }

  /// Whether the subtitle on screen is still typing (never, under reduced motion).
  bool get typing {
    final text = tester.widget<TypewriterText>(find.byType(TypewriterText));
    return text.characters < text.text.length;
  }

  /// Picks [option] on screen: a tap to choose it, a tap to say it.
  ///
  /// The player reads first: the tap comes [readFor] after the cards arrive, past the engine's
  /// guess threshold. [guess] taps the moment the card is there, as a random clicker would.
  ///
  /// A beat line whose beat asks "why that line?" is then explained: with the reasoning that's
  /// sound for it, or with [reason] when given.
  Future<void> say(Object option, {bool guess = false, Reason? reason}) async {
    if (option is AnswerOption) {
      if (parseBuildOptionId(option.id) case (:final placed, buildId: _)) {
        await build(placed, guess: guess);
        return;
      }
    }
    await pick(option, guess: guess);
    if (option is! AnswerOption) return;
    final why = _beatOf(option)?.why;
    if (why == null) return;
    await pick(
      reason ??
          why.reasons.firstWhere(
            (r) => r.isSoundFor(option.id),
            orElse: () => why.reasons.first,
          ),
    );
  }

  /// The beat [option] belongs to, in the catalog being played.
  Beat? _beatOf(AnswerOption option) {
    for (final m in container.read(missionCatalogProvider)) {
      for (final b in m.beats) {
        if (b.options.contains(option)) return b;
      }
    }
    return null;
  }

  /// Builds the answer on a built beat (brief 27): taps the fragments [placed] in that order,
  /// then "Lock it in". The player reads first unless [guess].
  Future<void> build(List<String> placed, {bool guess = false}) async {
    await until(find.byType(FragmentChip));
    if (!guess) await run(readFor);
    for (final id in placed) {
      await tapFragment(id);
    }
    final lock = find.text(BuildPanel.lockIn);
    await tester.ensureVisible(lock);
    await tester.pump();
    await tester.tap(lock);
    await tester.pump();
  }

  /// One tap on the chip of fragment [id]: places it, or takes it out.
  Future<void> tapFragment(String id) async {
    final chip = find.widgetWithText(FragmentChip, fragmentText(id));
    await until(chip);
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();
  }

  /// The words of fragment [id], in the catalog being played.
  String fragmentText(String id) {
    for (final m in container.read(missionCatalogProvider)) {
      for (final b in m.beats) {
        for (final f in b.build?.fragments ?? const <Fragment>[]) {
          if (f.id == id) return f.text;
        }
      }
    }
    throw ArgumentError.value(id, 'id', 'no such fragment');
  }

  /// One tap on [option]'s card (on the part that's on screen), and nothing more.
  Future<void> tapOnce(Object option) async {
    final card = find.widgetWithText(ChoiceCard, _textOf(option));
    await until(card);
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tapAt(_visibleCentre(card));
    await tester.pump();
  }

  static String _textOf(Object option) => switch (option) {
    AnswerOption(:final text) => text,
    Reason(:final text) => text,
    _ => throw ArgumentError.value(option, 'option'),
  };

  Offset _visibleCentre(Finder card) {
    final view = tester.getRect(
      find.ancestor(of: card, matching: find.byType(SingleChildScrollView)),
    );
    return tester.getRect(card).intersect(view).center;
  }

  /// Picks [option] (a line, a reply or a reason) and says it, without answering "why".
  Future<void> pick(Object option, {bool guess = false}) async {
    final text = switch (option) {
      AnswerOption(:final text) => text,
      Reason(:final text) => text,
      _ => throw ArgumentError.value(option, 'option'),
    };
    final card = find.widgetWithText(ChoiceCard, text);
    await until(card);
    if (!guess) await run(readFor);
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
    final skip = find.text(DraftPanel.skip);
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
      await say(mission.optionById(id)!);
    }
    // The follow-up's line, after the hard cut: let it type, then complete it.
    await until(find.text(state(number).followUpLine!.text));
    await run(const Duration(milliseconds: 300));
    if (typing) await tapScene();
    await say(mission.optionById(reply)!);
    await until(find.byType(Dossier));
  }

  /// Plays the whole dossier through (stamps, seal, pen) and the slip arriving.
  Future<void> settleDossier() => run(BrandMotion.dossier + BrandMotion.pen);
}
