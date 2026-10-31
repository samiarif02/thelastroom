import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// "Too fast: read before you answer": a guessed pick, called out on screen as the
/// interviewer calls it out in words. A dark plaque with a red-pen bar, so it reads over the
/// room at AA. Fades in and out with [shown].
class GuessCue extends StatelessWidget {
  const GuessCue({super.key, required this.shown});

  final bool shown;

  static const String text = 'Too fast: read before you answer';

  static const double _bar = 3;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: BrandMotion.standard,
      curve: BrandMotion.enter,
      child: Semantics(
        liveRegion: true,
        label: shown ? text : null,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandVivid.night.withValues(alpha: 0.92),
            border: const Border(
              left: BorderSide(color: BrandVivid.horizon, width: _bar),
            ),
            boxShadow: BrandVivid.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSpace.md,
              vertical: BrandSpace.sm,
            ),
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: BrandVividType.kicker.copyWith(color: BrandVivid.onDeep),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A small sheet over the dimmed scene, with a title, one line and two choices. The back button
/// mid-mission ([LeaveSheet]) and reopening a left mission ([ResumeSheet]) both use it.
class _SceneSheet extends StatelessWidget {
  const _SceneSheet({
    required this.title,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.grade,
  });

  final String title;
  final String line;
  final String primary;
  final VoidCallback onPrimary;
  final String secondary;
  final VoidCallback onSecondary;
  final ChapterGrade grade;

  static const double _scrim = 0.72;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: BrandVivid.night.withValues(alpha: _scrim)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [grade.deep, grade.deeper],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_radius),
                ),
                boxShadow: BrandVivid.cardShadow,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.lg,
                  BrandSpace.lg,
                  insets.bottom + BrandSpace.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: BrandVividType.title,
                      ),
                    ),
                    const SizedBox(height: BrandSpace.sm),
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: BrandVividType.body,
                    ),
                    const SizedBox(height: BrandSpace.lg),
                    VividButton(
                      label: primary,
                      expand: true,
                      onPressed: onPrimary,
                    ),
                    const SizedBox(height: BrandSpace.sm),
                    VividButton(
                      label: secondary,
                      primary: false,
                      expand: true,
                      onPressed: onSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The back button mid-mission: stay, or leave with the attempt saved on the device.
class LeaveSheet extends StatelessWidget {
  const LeaveSheet({
    super.key,
    required this.onResume,
    required this.onLeave,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onResume;
  final VoidCallback onLeave;
  final ChapterGrade grade;

  static const String title = 'Leave the interview?';
  static const String line =
      'Your progress is saved. You can continue where you left off.';
  static const String resume = 'Resume';
  static const String leave = 'Leave';

  @override
  Widget build(BuildContext context) => _SceneSheet(
    title: title,
    line: line,
    primary: resume,
    onPrimary: onResume,
    secondary: leave,
    onSecondary: onLeave,
    grade: grade,
  );
}

/// Reopening a mission the player left: continue it, or start again.
class ResumeSheet extends StatelessWidget {
  const ResumeSheet({
    super.key,
    required this.onContinue,
    required this.onRestart,
    this.grade = ChapterGrade.lobby,
  });

  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final ChapterGrade grade;

  static const String title = 'Continue where you left off?';
  static const String line = 'Your answers so far are kept, in the same order.';
  static const String resume = 'Continue';
  static const String restart = 'Start again';

  @override
  Widget build(BuildContext context) => _SceneSheet(
    title: title,
    line: line,
    primary: resume,
    onPrimary: onContinue,
    secondary: restart,
    onSecondary: onRestart,
    grade: grade,
  );
}
