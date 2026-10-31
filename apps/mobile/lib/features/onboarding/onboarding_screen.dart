import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/event_value.dart';
import '../../core/audio/game_sounds.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/film_kit.dart';
import '../tower/tower_chapter_card.dart';
import 'name_field.dart';
import 'onboarding_copy.dart';

/// The onboarding's steps, in order (brief 17): what the game is, who you'll meet, your name.
enum OnboardingStep { game, cast, name }

/// First launch only (brief 17): three short, colourful steps, each on a chapter's colour,
/// with a dot row, one obvious button and Skip. It ends on the Tower with Mission 1 ready to
/// play. Only the first name is asked; the rest of the profile keeps its defaults. Saved once,
/// at the end, with `onboarding_completed` (never the name: it's not a property).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  OnboardingStep _step = OnboardingStep.game;
  int _skipped = 0;
  bool _finished = false;

  /// Which way the steps slide: forward is right to left.
  bool _forward = true;

  GameSounds get _sounds => ref.read(gameSoundsProvider);

  ChapterGrade get _grade => ChapterGrade.values[_step.index];

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

  /// Skip the explanation, straight to the name (the only thing asked).
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

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final fade = still ? BrandMotion.reducedMotionFade : BrandMotion.standard;
    final last = _step == OnboardingStep.name;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: fade,
          child: VividBackdrop(key: ValueKey(_grade), grade: _grade),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            BrandSpace.lg,
            BrandSpace.sm,
            BrandSpace.lg,
            BrandSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _Dots(at: _step.index)),
                  // Holds its place on the last step, so the dots don't jump.
                  Opacity(
                    opacity: last ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: last,
                      child: ExcludeSemantics(
                        excluding: last,
                        child: VividButton(
                          label: OnboardingCopy.skip,
                          primary: false,
                          onPressed: _skip,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: fade,
                  switchInCurve: BrandMotion.enter,
                  switchOutCurve: BrandMotion.exit,
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
                        vertical: BrandSpace.lg,
                      ),
                      children: [_body()],
                    ),
                  ),
                ),
              ),
              if (!last)
                VividButton(
                  label: OnboardingCopy.next,
                  expand: true,
                  onPressed: _next,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// How far a step slides in, as a share of the width.
  static const double _slide = 0.25;

  Widget _body() => switch (_step) {
    OnboardingStep.game => const _GameStep(),
    OnboardingStep.cast => const _CastStep(),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StaggeredEntrance(
        index: 0,
        child: Text(
          kicker,
          style: BrandVividType.kicker.copyWith(color: BrandVivid.accent),
        ),
      ),
      const SizedBox(height: BrandSpace.sm),
      StaggeredEntrance(
        index: 1,
        child: Semantics(
          header: true,
          child: Text(title, style: BrandVividType.hero),
        ),
      ),
      if (line case final l?) ...[
        const SizedBox(height: BrandSpace.sm),
        StaggeredEntrance(index: 2, child: Text(l, style: BrandVividType.body)),
      ],
      const SizedBox(height: BrandSpace.lg),
      below,
    ],
  );
}

/// Step 1: the game in three cards, dealt like a hand, each in a chapter's colour.
class _GameStep extends StatelessWidget {
  const _GameStep();

  static const List<double> _tilts = [-0.025, 0.02, -0.012];

  @override
  Widget build(BuildContext context) {
    const ideas = OnboardingCopy.gameIdeas;
    return _Heading(
      kicker: OnboardingCopy.gameKicker,
      title: OnboardingCopy.gameTitle,
      below: Column(
        children: [
          for (var i = 0; i < ideas.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BrandSpace.sm + 4),
              child: StaggeredEntrance(
                index: 3 + i,
                child: _IdeaCard(
                  number: i + 1,
                  title: ideas[i].title,
                  line: ideas[i].line,
                  grade: ChapterGrade.values[i],
                  tilt: _tilts[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({
    required this.number,
    required this.title,
    required this.line,
    required this.grade,
    required this.tilt,
  });

  final int number;
  final String title;
  final String line;
  final ChapterGrade grade;

  /// A slight hand-dealt angle, in radians. Level under reduced motion.
  final double tilt;

  static const double _disc = 44;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Transform.rotate(
      angle: still ? 0 : tilt,
      child: _ColourCard(
        grade: grade,
        child: Row(
          children: [
            Container(
              width: _disc,
              height: _disc,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: grade.glow,
              ),
              child: Text(
                '$number',
                style: BrandVividType.title.copyWith(color: grade.deeper),
              ),
            ),
            const SizedBox(width: BrandSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BrandVividType.row),
                  Text(line, style: BrandVividType.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2: Priya, Marcus and Lena, each on the colour of the chapter they run.
class _CastStep extends StatelessWidget {
  const _CastStep();

  static const double _badge = 68;

  @override
  Widget build(BuildContext context) {
    final cast = [
      for (final id in ChapterCard.hostIds)
        interviewers.firstWhere((i) => i.id == id),
    ];
    return _Heading(
      kicker: OnboardingCopy.castKicker,
      title: OnboardingCopy.castTitle,
      line: OnboardingCopy.castLine,
      below: Column(
        children: [
          for (var i = 0; i < cast.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: BrandSpace.sm),
              child: StaggeredEntrance(
                index: 3 + i,
                child: Semantics(
                  label:
                      '${cast[i].name}, ${cast[i].role}, ${OnboardingCopy.castChapter(i + 1)}',
                  excludeSemantics: true,
                  child: _ColourCard(
                    grade: ChapterGrade.values[i],
                    child: Row(
                      children: [
                        InterviewerBadge(
                          figure: FriendlyFigure.of(cast[i].id),
                          ring: ChapterGrade.values[i].glow,
                          grade: ChapterGrade.values[i],
                          size: _badge,
                        ),
                        const SizedBox(width: BrandSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                OnboardingCopy.castChapter(i + 1).toUpperCase(),
                                style: BrandVividType.kicker,
                              ),
                              Text(cast[i].name, style: BrandVividType.title),
                              Text(cast[i].role, style: BrandVividType.body),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A card in a chapter's colour, lifted off the sky.
class _ColourCard extends StatelessWidget {
  const _ColourCard({required this.grade, required this.child});

  final ChapterGrade grade;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(BrandSpace.md),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(BrandRadius.card),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: grade.cardGradient,
      ),
      border: Border.all(color: BrandVivid.hairline()),
      boxShadow: BrandVivid.cardShadow,
    ),
    child: child,
  );
}

/// Where you are in the three steps: a dot each, the current one a wide sunflower pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.at});

  final int at;

  static const double _dot = 10;
  static const double _wide = 28;
  static const double _restAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    const steps = OnboardingStep.values;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Step ${at + 1} of ${steps.length}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            AnimatedContainer(
              duration: still ? Duration.zero : BrandMotion.standard,
              curve: BrandMotion.enter,
              margin: const EdgeInsets.only(right: BrandSpace.xs + 2),
              width: i == at ? _wide : _dot,
              height: _dot,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BrandRadius.pill),
                color: i == at
                    ? BrandVivid.accent
                    : BrandVivid.onDeep.withValues(alpha: _restAlpha),
              ),
            ),
        ],
      ),
    );
  }
}
