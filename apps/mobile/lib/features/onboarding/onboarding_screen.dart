import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/back_to_exit.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../../ui/film/anchored_scroll.dart';
import '../progression/interview_date_choices.dart';
import 'explainer_deck.dart';
import 'name_field.dart';
import 'onboarding_copy.dart';

/// Onboarding's questions, in order, after the "How it works" explainer: when your interview
/// is (optional, brief 32), then your name.
enum OnboardingStep { interview, name }

/// First launch only (brief 17; Daylight in brief 48; issue 75). First the "How it works"
/// explainer ([ExplainerDeck]: what the app is, how a room works, how you're scored, how it
/// sticks, why come back), then the questions, each on a floor's tint with a step bar, one honey
/// button and Skip. It ends on the Tower with room 1 ready to play. Only the first name is
/// asked; the rest of the profile keeps its defaults. Saved once, at the end, with
/// `onboarding_completed` (never the name: it's not a property). Skip on the explainer goes to
/// the questions, never past the name.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Who hosts each floor, bottom up.
  static const List<String> floorHosts = ['priya', 'marcus', 'lena'];

  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// The explainer is showing; the questions come after it.
  bool _explaining = true;

  /// The explainer's page to open on: the last one when back returns to it from a question.
  int _explainerPage = 0;
  final GlobalKey<ExplainerDeckState> _deck = GlobalKey();

  OnboardingStep _step = OnboardingStep.interview;
  int _skipped = 0;
  bool _finished = false;

  /// Which way the steps slide: forward is right to left.
  bool _forward = true;

  GameSounds get _sounds => ref.read(gameSoundsProvider);

  /// The step's floor: the date on floor 3, the name back on floor 1, where room 1 waits.
  FloorColours get _floor => switch (_step) {
    OnboardingStep.name => DaylightFloors.one,
    OnboardingStep.interview => DaylightFloors.three,
  };

  /// The explainer ended: on to the questions. A Skip counts the pages it passed by.
  void _explained({required bool skipped}) {
    if (!mounted) return;
    if (skipped) {
      final at = _deckPage;
      _skipped += ExplainerDeck.length - at;
    }
    _sounds.pageTurn();
    setState(() {
      _explaining = false;
      _forward = true;
      _step = OnboardingStep.interview;
    });
  }

  /// Which explainer page is showing (for a Skip's count).
  int get _deckPage => _deck.currentState?.page ?? 0;

  void _go(OnboardingStep step) {
    if (!mounted || step == _step) return;
    _sounds.pageTurn();
    setState(() {
      _forward = step.index > _step.index;
      _step = step;
    });
  }

  void _next() {
    _sounds.uiTap();
    _go(OnboardingStep.values[_step.index + 1]);
  }

  /// Skip the interview date, straight to the name (the only thing asked).
  void _skip() {
    _sounds.uiTap();
    _skipped += OnboardingStep.name.index - _step.index;
    _go(OnboardingStep.name);
  }

  Future<void> _finish(String? name) async {
    if (_finished) return;
    _finished = true;
    _sounds.uiTap();
    await ref
        .read(profileProvider.notifier)
        .change((p) => p.copyWith(firstName: () => name, onboarded: true));
    final calm =
        ref.read(profileProvider).value?.calmMode ??
        const PlayerProfile().calmMode;
    ref.read(analyticsProvider).track(AnalyticsEvent.onboardingCompleted, {
      'skipped_steps': EventValue.count(_skipped),
      'named': EventValue.flag(name != null),
      'calm_mode': EventValue.flag(calm),
    });
    if (mounted) context.go(Routes.tower());
  }

  /// Android back steps back: a page in the explainer, a question, or from the first question
  /// to the explainer's last page. On the explainer's first page it's the root's exit hint.
  bool _stepBack() {
    if (_explaining) return _deck.currentState?.back() ?? false;
    if (_step == OnboardingStep.values.first) {
      _sounds.pageTurn();
      setState(() {
        _explaining = true;
        _explainerPage = ExplainerDeck.length - 1;
      });
      return true;
    }
    _go(OnboardingStep.values[_step.index - 1]);
    return true;
  }

  @override
  Widget build(BuildContext context) => BackToExit(
    onBack: _stepBack,
    child: _explaining
        ? ExplainerDeck(
            key: _deck,
            initialPage: _explainerPage,
            onDone: _explained,
          )
        : _screen(context),
  );

  Widget _screen(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final last = _step == OnboardingStep.name;
    final f = _floor;
    return DaylightGround(
      floor: f,
      child: AnimatedContainer(
        duration: DaylightMotion.colour,
        curve: DaylightMotion.ease,
        color: f.tint,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            DaylightSpace.s16,
            DaylightSpace.s8,
            DaylightSpace.s16,
            DaylightSpace.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _StepBar(at: _step.index)),
                  const SizedBox(width: DaylightSpace.s16),
                  // Holds its place on the last step, so the bar doesn't jump.
                  Opacity(
                    opacity: last ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: last,
                      child: ExcludeSemantics(
                        excluding: last,
                        child: TactileButton(
                          label: OnboardingCopy.skip,
                          tone: TactileTone.quiet,
                          compact: true,
                          expand: false,
                          onPressed: _skip,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: still ? DaylightMotion.colour : DaylightMotion.move,
                  switchInCurve: DaylightMotion.ease,
                  switchOutCurve: DaylightMotion.ease,
                  transitionBuilder: (child, t) {
                    if (still) return FadeTransition(opacity: t, child: child);
                    final incoming = child.key == ValueKey(_step);
                    final from = incoming == _forward ? _slide : -_slide;
                    return FadeTransition(
                      opacity: t,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(from, 0),
                          end: Offset.zero,
                        ).animate(t),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: AnchoredScroll(
                      alignment: MainAxisAlignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: DaylightSpace.s24,
                      ),
                      children: [_body()],
                    ),
                  ),
                ),
              ),
              if (!last)
                TactileButton(
                  label: OnboardingCopy.next,
                  icon: PhosphorBold.arrowRight,
                  onPressed: _next,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// How far a step slides in, as a share of the width.
  static const double _slide = 0.25;

  Widget _body() => switch (_step) {
    OnboardingStep.interview => const _Heading(
      kicker: InterviewDateChoices.kicker,
      title: InterviewDateChoices.title,
      line: InterviewDateChoices.line,
      below: InterviewDateChoices(),
    ),
    OnboardingStep.name => _Heading(
      kicker: OnboardingCopy.nameKicker,
      title: OnboardingCopy.nameTitle,
      line: OnboardingCopy.nameLine,
      below: NameField(onDone: (n) => unawaited(_finish(n))),
    ),
  };
}

/// A step's kicker, big title and line, with whatever the step shows [below] it, arriving one
/// after another.
class _Heading extends StatelessWidget {
  const _Heading({
    required this.kicker,
    required this.title,
    required this.below,
    this.line,
  });

  final String kicker;
  final String title;
  final String? line;
  final Widget below;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Entrance(
          child: Text(
            kicker,
            style: DaylightType.caption3.copyWith(color: f.deep),
          ),
        ),
        const SizedBox(height: DaylightSpace.s8),
        Entrance(
          index: 1,
          child: Semantics(
            header: true,
            child: Text(title, style: DaylightType.heading3),
          ),
        ),
        if (line case final l?) ...[
          const SizedBox(height: DaylightSpace.s8),
          Entrance(
            index: 2,
            child: Text(
              l,
              style: DaylightType.body3.copyWith(color: DaylightColors.ink2),
            ),
          ),
        ],
        const SizedBox(height: DaylightSpace.s24),
        below,
      ],
    );
  }
}

/// Where you are in the steps: a bar each, the current one wide, in the floor's colour once
/// reached.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.at});

  final int at;

  static const double _height = 8;
  static const int _wide = 3;

  @override
  Widget build(BuildContext context) {
    const steps = OnboardingStep.values;
    final f = ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Step ${at + 1} of ${steps.length}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: DaylightSpace.s4),
            Expanded(
              flex: i == at ? _wide : 1,
              child: AnimatedContainer(
                duration: still ? Duration.zero : DaylightMotion.colour,
                curve: DaylightMotion.ease,
                height: _height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_height / 2),
                  color: i <= at ? f.base : DaylightColors.sand2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
