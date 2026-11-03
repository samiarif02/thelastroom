import 'dart:async';

import 'package:brand/brand.dart';
import 'package:content/content.dart';
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
import '../mission/mission_lookup.dart';
import '../progression/interview_date_choices.dart';
import 'name_field.dart';
import 'onboarding_copy.dart';

/// The onboarding's steps, in order (brief 17): what the game is, who you'll meet, when your
/// interview is (optional, brief 32), your name.
enum OnboardingStep { game, cast, interview, name }

/// First launch only (brief 17; Daylight in brief 48): four short steps, each on a floor's tint
/// (the ground eases from one to the next), with a step bar, one honey button and Skip. It ends
/// on the Tower with room 1 ready to play. Only the first name is asked; the rest of the profile
/// keeps its defaults. Saved once, at the end, with `onboarding_completed` (never the name:
/// it's not a property).
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Who hosts each floor, bottom up: the three faces the panel step introduces.
  static const List<String> floorHosts = ['priya', 'marcus', 'lena'];

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

  /// The step's floor: the game on floor 1, the cast on floor 2, the date on floor 3, the
  /// name back on floor 1, where room 1 waits.
  FloorColours get _floor => switch (_step) {
    OnboardingStep.game || OnboardingStep.name => DaylightFloors.one,
    OnboardingStep.cast => DaylightFloors.two,
    OnboardingStep.interview => DaylightFloors.three,
  };

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

  /// Android back steps back a step; on the first step it's the root's exit hint.
  bool _stepBack() {
    if (_step == OnboardingStep.values.first) return false;
    _go(OnboardingStep.values[_step.index - 1]);
    return true;
  }

  @override
  Widget build(BuildContext context) =>
      BackToExit(onBack: _stepBack, child: _screen(context));

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
    OnboardingStep.game => const _GameStep(),
    OnboardingStep.cast => const _CastStep(),
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

/// Step 1: the game in three cards, dealt like a hand, each with its floor's glyph tile.
class _GameStep extends StatelessWidget {
  const _GameStep();

  static const List<double> _tilts = [-0.02, 0.016, -0.01];
  static const List<IconData> _icons = [
    PhosphorBold.stack,
    PhosphorBold.chatCircle,
    PhosphorFill.chartBar,
  ];

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
              padding: const EdgeInsets.only(bottom: DaylightSpace.s12),
              child: Entrance(
                index: 3 + i,
                child: _IdeaCard(
                  title: ideas[i].title,
                  line: ideas[i].line,
                  icon: _icons[i],
                  floor: DaylightFloors.all[i],
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
    required this.title,
    required this.line,
    required this.icon,
    required this.floor,
    required this.tilt,
  });

  final String title;
  final String line;
  final IconData icon;
  final FloorColours floor;

  /// A slight hand-dealt angle, in radians. Level under reduced motion.
  final double tilt;

  static const double _tile = 44;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Transform.rotate(
      angle: still ? 0 : tilt,
      child: DaylightPanel(
        radius: DaylightRadius.card,
        child: Row(
          children: [
            Container(
              width: _tile,
              height: _tile,
              decoration: BoxDecoration(
                color: floor.base,
                borderRadius: BorderRadius.circular(DaylightRadius.inner),
              ),
              child: Icon(
                icon,
                size: DaylightSpace.s24,
                color: DaylightColors.raised,
              ),
            ),
            const SizedBox(width: DaylightSpace.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DaylightType.body1),
                  Text(
                    line,
                    style: DaylightType.body6.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2: Priya, Marcus and Lena in their arches, each on the colour of the floor they run,
/// and Sam at dusk, waiting on the top floor.
class _CastStep extends StatelessWidget {
  const _CastStep();

  /// The first mission this interviewer leads (they all appear in Chapter 1).
  static int _firstMet(Interviewer who) =>
      missions.firstWhere((m) => m.lead.id == who.id).number;

  /// "Hiring Manager" as the screen sets roles: sentence case.
  static String _role(String role) =>
      role.isEmpty ? role : role[0] + role.substring(1).toLowerCase();

  static const double _arch = 56;
  static const double _archHeight = 68;

  @override
  Widget build(BuildContext context) {
    final cast = [
      for (final id in OnboardingScreen.floorHosts)
        interviewers.firstWhere((i) => i.id == id),
    ];
    Widget row({
      required CastPerson person,
      required Color arch,
      required Widget text,
      Color face = DaylightColors.raised,
      Color edge = DaylightColors.sand2,
    }) => DaylightPanel(
      color: face,
      edge: edge,
      radius: DaylightRadius.card,
      padding: const EdgeInsets.fromLTRB(
        DaylightSpace.s12,
        DaylightSpace.s12,
        DaylightSpace.s16,
        DaylightSpace.s12,
      ),
      child: Row(
        children: [
          ArchPortrait(
            person: person,
            expression: CastExpression.smile,
            width: _arch,
            height: _archHeight,
            ground: arch,
            idle: false,
          ),
          const SizedBox(width: DaylightSpace.s16),
          Expanded(child: text),
        ],
      ),
    );
    return _Heading(
      kicker: OnboardingCopy.castKicker,
      title: OnboardingCopy.castTitle,
      line: OnboardingCopy.castLine,
      below: Column(
        children: [
          for (var i = 0; i < cast.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: DaylightSpace.s12),
              child: Entrance(
                index: 3 + i,
                child: Semantics(
                  label:
                      '${cast[i].name}, ${_role(cast[i].role)}, ${OnboardingCopy.castFirstMet(_firstMet(cast[i]))}',
                  excludeSemantics: true,
                  child: row(
                    person: CastPeople.byId(cast[i].id),
                    arch: DaylightFloors.all[i].soft,
                    text: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cast[i].name, style: DaylightType.heading6),
                        Text(
                          _role(cast[i].role),
                          style: DaylightType.body6.copyWith(
                            color: DaylightColors.ink2,
                          ),
                        ),
                        const SizedBox(height: DaylightSpace.s4),
                        Tag(
                          label: OnboardingCopy.castFirstMet(
                            _firstMet(cast[i]),
                          ),
                          tone: TagTone.floor(DaylightFloors.all[i]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Entrance(
            index: 3 + cast.length,
            child: Semantics(
              label:
                  '${CastPeople.sam.name}, ${OnboardingCopy.samRole}. '
                  '${OnboardingCopy.samLine}',
              excludeSemantics: true,
              child: row(
                person: CastPeople.sam,
                arch: DaylightColors.honey,
                face: DaylightColors.dusk,
                edge: DaylightColors.ink,
                text: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CastPeople.sam.name,
                      style: DaylightType.heading6.copyWith(
                        color: DaylightColors.raised,
                      ),
                    ),
                    Text(
                      OnboardingCopy.samRole,
                      style: DaylightType.body6.copyWith(
                        color: DaylightColors.sky,
                      ),
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Text(
                      OnboardingCopy.samLine,
                      style: DaylightType.caption3.copyWith(
                        color: DaylightColors.honey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
