import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../choice/brass_button.dart';
import '../film/ambient_clock.dart';
import '../film/anchored_scroll.dart';
import '../vivid/tower_painter.dart';
import '../vivid/vivid_backdrop.dart';

/// Which of the four designed states a [SceneState] shows.
enum SceneStateKind {
  /// Waiting on something: the tower half lit, a sunflower rule breathing.
  loading,

  /// Nothing to show yet: the tower lit.
  empty,

  /// No connection: the tower dark. Progress is safe on the device (offline-first).
  offline,

  /// Something broke: a few windows on. Usually with a way out.
  error,
}

/// Loading, empty, offline and error, in the vivid language (`docs/rules/components.md`
/// "Every state is designed"; brief 23): the tower on the evening sky, lit or dark by the state,
/// a sunflower kicker, one big line and a quiet note. Never a spinner on a blank screen.
///
/// The named constructors carry the house copy; screens override it for their context
/// ("Your first dossier lands here after Mission 1."). [onAction] adds a [BrassButton].
/// Fades in over [BrandMotion.cinematic] (a short cross-fade under reduced motion); the loading
/// rule holds still under reduced motion.
class SceneState extends StatelessWidget {
  const SceneState({
    super.key,
    required this.kind,
    required this.eyebrow,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.grade = ChapterGrade.lobby,
  });

  const SceneState.loading({
    super.key,
    this.eyebrow = loadingEyebrow,
    this.title = loadingTitle,
    this.message,
    this.grade = ChapterGrade.lobby,
  }) : kind = SceneStateKind.loading,
       actionLabel = null,
       onAction = null;

  const SceneState.empty({
    super.key,
    this.eyebrow = emptyEyebrow,
    this.title = emptyTitle,
    this.message = emptyMessage,
    this.actionLabel,
    this.onAction,
    this.grade = ChapterGrade.lobby,
  }) : kind = SceneStateKind.empty;

  const SceneState.offline({
    super.key,
    this.eyebrow = offlineEyebrow,
    this.title = offlineTitle,
    this.message = offlineMessage,
    this.actionLabel = retryLabel,
    this.onAction,
    this.grade = ChapterGrade.lobby,
  }) : kind = SceneStateKind.offline;

  const SceneState.error({
    super.key,
    this.eyebrow = errorEyebrow,
    this.title = errorTitle,
    this.message = errorMessage,
    this.actionLabel = retryLabel,
    this.onAction,
    this.grade = ChapterGrade.lobby,
  }) : kind = SceneStateKind.error;

  static const String loadingEyebrow = 'ONE MOMENT';
  static const String loadingTitle = 'The lights are coming up.';
  static const String emptyEyebrow = 'NOTHING YET';
  static const String emptyTitle = 'The desk is clear.';
  static const String emptyMessage = 'Nothing has been filed here yet.';
  static const String offlineEyebrow = 'OFFLINE';
  static const String offlineTitle = 'The lights are out.';
  static const String offlineMessage = 'Your progress is safe on this device.';
  static const String errorEyebrow = 'SOMETHING WENT WRONG';
  static const String errorTitle = 'The room went dark.';
  static const String errorMessage =
      'Something broke on our side, not yours. Your progress is safe on this device.';
  static const String retryLabel = 'Try again';

  final SceneStateKind kind;

  /// Tracked sunflower caps.
  final String eyebrow;

  /// The big line.
  final String title;
  final String? message;

  /// The button's label; shown only with [onAction].
  final String? actionLabel;
  final VoidCallback? onAction;
  final ChapterGrade grade;

  static const double _towerHeight = 150;
  static const double _ruleWidth = 120;
  static const double _maxWidth = 420;

  /// How much of the tower is lit: the state, at a glance (brief 23). The tower is lit for an
  /// empty desk, half lit while loading, a few windows on an error, dark when offline.
  double get towerLit => switch (kind) {
    SceneStateKind.empty => 1,
    SceneStateKind.loading => 0.5,
    SceneStateKind.error => 0.3,
    SceneStateKind.offline => 0,
  };

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final label = actionLabel;
    return ColoredBox(
      color: BrandVivid.skyTop,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: still ? BrandMotion.reducedMotionFade : BrandMotion.cinematic,
        curve: BrandMotion.enter,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Stack(
          fit: StackFit.expand,
          children: [
            VividBackdrop(grade: grade),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: AnchoredScroll(
                    alignment: MainAxisAlignment.center,
                    padding: const EdgeInsets.all(BrandSpace.lg),
                    children: [
                      SizedBox(
                        height: _towerHeight,
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: TowerPainter(lit: towerLit),
                          ),
                        ),
                      ),
                      const SizedBox(height: BrandSpace.lg),
                      Text(
                        eyebrow,
                        textAlign: TextAlign.center,
                        style: BrandVividType.kicker.copyWith(
                          color: BrandVivid.accent,
                        ),
                      ),
                      const SizedBox(height: BrandSpace.sm),
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: BrandVividType.hero.copyWith(
                            fontSize: _titleSize,
                          ),
                        ),
                      ),
                      if (message case final m?) ...[
                        const SizedBox(height: BrandSpace.sm),
                        Text(
                          m,
                          textAlign: TextAlign.center,
                          style: BrandVividType.body,
                        ),
                      ],
                      if (kind == SceneStateKind.loading) ...[
                        const SizedBox(height: BrandSpace.lg),
                        Center(
                          child: SizedBox(
                            width: _ruleWidth,
                            child: LoadingRule(grade: grade),
                          ),
                        ),
                      ],
                      if (label != null && onAction != null) ...[
                        const SizedBox(height: BrandSpace.lg),
                        Center(
                          child: BrassButton(
                            label: label,
                            onTap: onAction,
                            grade: grade,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _titleSize = 26;
}

/// A hairline with a sunflower glint that travels along it and back, on the ambient clock:
/// the progress indicator (indeterminate). Under reduced motion the glint
/// rests in the middle.
class LoadingRule extends StatelessWidget {
  const LoadingRule({super.key, this.grade = ChapterGrade.lobby});

  final ChapterGrade grade;

  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: SizedBox(
        height: height,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _RulePainter(
              clock: AmbientClock.of(context),
              color: BrandVivid.accent,
              still: MediaQuery.disableAnimationsOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  _RulePainter({required this.clock, required this.color, required this.still})
    : super(repaint: clock);

  final ValueListenable<double> clock;
  final Color color;
  final bool still;

  static const double _period = 2.4;
  static const double _weight = 0.8;
  static const double _baseAlpha = 0.3;
  static const double _glint = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color.withValues(alpha: _baseAlpha)
        ..strokeWidth = _weight,
    );
    // A slow back-and-forth, eased at the ends like a lamp's beam swinging.
    final phase = still
        ? 0.5
        : (1 - math.cos(clock.value / _period * 2 * math.pi)) / 2;
    final centre = size.width * phase;
    final reach = size.width * _glint;
    final glint = Rect.fromLTRB(centre - reach, 0, centre + reach, size.height);
    canvas.drawLine(
      Offset(glint.left, y),
      Offset(glint.right, y),
      Paint()
        ..strokeWidth = _weight * 2
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ).createShader(glint),
    );
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.color != color || old.still != still || old.clock != clock;
}
