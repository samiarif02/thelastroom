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
import '../mission/mission_lookup.dart';
import '../mission/widgets/cue_button.dart';
import 'name_field.dart';
import 'onboarding_copy.dart';

/// The onboarding's questions, in order (researched from Duolingo's: one question a screen,
/// big tiles, a progress line at the top; docs/status/13.md).
enum OnboardingStep { name, experience, role, nerves, goal, ready }

/// First launch only, after the welcome cards (the intro): Priya asks five quick questions,
/// then "Your first interview is waiting" and the Tower. Every step but the name can be
/// skipped, and the name has "Skip, call me Candidate". The answers are saved once, at the
/// end, with `onboarding_completed` (never the name: it's not a property).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  OnboardingStep _step = OnboardingStep.name;
  int _skipped = 0;
  bool _finished = false;

  String? _name;
  Experience? _experience;
  TargetRole? _role;
  int? _nerves;
  int? _goal;

  /// A beat after a tile is picked, so the choice is seen to land.
  static const Duration _afterPick = Duration(milliseconds: 350);

  /// What's lit while the step waits to move on.
  Object? _picked;

  Interviewer get _host => missions.first.lead;

  bool get _calm => (_nerves ?? 0) >= PlayerProfile.calmFrom;

  GameSounds get _sounds => ref.read(gameSoundsProvider);

  void _next() {
    if (!mounted) return;
    _sounds.pageTurn();
    setState(() {
      _picked = null;
      _step = OnboardingStep.values[_step.index + 1];
    });
  }

  void _skip() {
    _skipped++;
    _next();
  }

  Future<void> _pick(Object value, void Function() store) async {
    if (_picked != null) return;
    _sounds.uiTap();
    store();
    setState(() => _picked = value);
    final still = MediaQuery.disableAnimationsOf(context);
    await Future<void>.delayed(still ? Duration.zero : _afterPick);
    _next();
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    final calm = _calm;
    await ref
        .read(profileProvider.notifier)
        .change(
          (p) => p.copyWith(
            firstName: () => _name,
            experience: () => _experience,
            targetRole: () => _role,
            nervesLevel: () => _nerves,
            calmMode: calm,
            weeklyGoal: () => _goal,
            onboarded: true,
          ),
        );
    ref.read(analyticsProvider).track(AnalyticsEvent.onboardingCompleted, {
      'skipped_steps': EventValue.count(_skipped),
      'named': EventValue.flag(_name != null),
      if (_experience case final e?) 'experience': EventValue.name(e),
      if (_role case final r?) 'target_role': EventValue.name(r),
      if (_nerves case final n?) 'nerves_level': EventValue.count(n),
      'calm_mode': EventValue.flag(calm),
      if (_goal case final g?) 'weekly_goal': EventValue.count(g),
    });
    if (mounted) context.go(Routes.tower());
  }

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    final skippable =
        _step != OnboardingStep.name && _step != OnboardingStep.ready;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.8),
              radius: 1.4,
              colors: [grade.tint, BrandColors.surface, BrandColors.void_],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(BrandSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ProgressLine(
                      at: _step.index,
                      of: OnboardingStep.values.length - 1,
                      grade: grade,
                    ),
                  ),
                  const SizedBox(width: BrandSpace.sm),
                  // Holds its place on the name step, so the line doesn't jump.
                  Opacity(
                    opacity: skippable ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !skippable,
                      child: ExcludeSemantics(
                        excluding: !skippable,
                        child: CueButton(
                          label: OnboardingCopy.skip,
                          quiet: true,
                          onPressed: _skip,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: BrandSpace.lg),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _body(grade),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(ChapterGrade grade) {
    final name = _name ?? PlayerProfile.fallbackName;
    Widget ask(String line) => Padding(
      padding: const EdgeInsets.only(bottom: BrandSpace.lg),
      child: TypewriterSubtitle(speaker: _host.name, line: line, grade: grade),
    );
    Widget tiles<T extends Object>(
      List<(T, String)> options,
      void Function(T) store,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: BrandSpace.sm),
            child: AnswerCard(
              numeral: AnswerCard.numeralFor(i),
              text: options[i].$2,
              grade: grade,
              state: _picked == null
                  ? AnswerCardState.idle
                  : _picked == options[i].$1
                  ? AnswerCardState.locked
                  : AnswerCardState.disabled,
              onTap: () =>
                  unawaited(_pick(options[i].$1, () => store(options[i].$1))),
            ),
          ),
      ],
    );

    switch (_step) {
      case OnboardingStep.name:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ask(OnboardingCopy.askName),
            NameField(
              grade: grade,
              onDone: (n) {
                _name = n;
                _next();
              },
            ),
          ],
        );
      case OnboardingStep.experience:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ask(OnboardingCopy.askExperience(name)),
            tiles([
              for (final e in Experience.values)
                (e, OnboardingCopy.experience[e]!),
            ], (e) => _experience = e),
          ],
        );
      case OnboardingStep.role:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ask(OnboardingCopy.askRole),
            tiles([
              for (final r in TargetRole.values) (r, OnboardingCopy.role[r]!),
            ], (r) => _role = r),
          ],
        );
      case OnboardingStep.nerves:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ask(OnboardingCopy.askNerves),
            tiles([
              for (var n = 1; n <= OnboardingCopy.nerves.length; n++)
                (n, OnboardingCopy.nerves[n - 1]),
            ], (n) => _nerves = n),
          ],
        );
      case OnboardingStep.goal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ask(OnboardingCopy.askGoal),
            tiles([
              for (final g in OnboardingCopy.goals) (g.sessions, g.label),
            ], (g) => _goal = g),
          ],
        );
      case OnboardingStep.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrassOrnament(text: OnboardingCopy.readyEyebrow),
            const SizedBox(height: BrandSpace.lg),
            Semantics(
              header: true,
              child: const Text(
                OnboardingCopy.ready,
                textAlign: TextAlign.center,
                style: BrandType.display,
              ),
            ),
            const SizedBox(height: BrandSpace.md),
            Text(
              OnboardingCopy.readyLine(name, _host.name),
              textAlign: TextAlign.center,
              style: BrandType.body.copyWith(color: BrandColors.textSecondary),
            ),
            if (_calm) ...[
              const SizedBox(height: BrandSpace.md),
              Text(
                OnboardingCopy.calmOn,
                textAlign: TextAlign.center,
                style: BrandType.body.copyWith(color: grade.key),
              ),
            ],
            const SizedBox(height: BrandSpace.xl),
            CueButton(
              label: OnboardingCopy.toTower,
              grade: grade,
              onPressed: () => unawaited(_finish()),
            ),
          ],
        );
    }
  }
}

/// The thin brass line at the top that fills as the questions go by.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.at,
    required this.of,
    required this.grade,
  });

  final int at;
  final int of;
  final ChapterGrade grade;

  static const double _height = 3;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Question ${(at + 1).clamp(1, of)} of $of',
    excludeSemantics: true,
    child: SizedBox(
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: grade.key.withValues(alpha: 0.2)),
          TweenAnimationBuilder<double>(
            tween: Tween(end: at / of),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : BrandMotion.standard,
            curve: BrandMotion.enter,
            builder: (context, share, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: share,
              child: ColoredBox(color: grade.key),
            ),
          ),
        ],
      ),
    ),
  );
}
