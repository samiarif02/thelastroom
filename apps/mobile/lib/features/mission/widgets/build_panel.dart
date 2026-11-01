import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// "Build your answer" (brief 27): the answer so far, live in the speech panel, the fragments
/// as big chips, and "Lock it in". **One tap places** a fragment at the end of the answer; a
/// tap on a placed one takes it out (and the ones after it close up). The order the chips are
/// tapped is the order the answer is said.
///
/// The chips arrive like the answer cards do; [onArrived] fires when they're all up, the moment
/// the player's stopwatch starts. Nothing animates under reduced motion. Stateless: the player
/// keeps [placed].
class BuildPanel extends StatelessWidget {
  const BuildPanel({
    super.key,
    required this.label,
    required this.fragments,
    required this.placed,
    required this.grade,
    required this.onToggle,
    required this.onLockIn,
    this.locked = false,
    this.onArrived,
  });

  final String label;

  /// In the attempt's shuffled order.
  final List<Fragment> fragments;

  /// The fragment ids placed so far, in the order tapped.
  final List<String> placed;
  final ChapterGrade grade;
  final ValueChanged<Fragment> onToggle;
  final VoidCallback onLockIn;

  /// Said: nothing can change, the button is spent.
  final bool locked;
  final VoidCallback? onArrived;

  static const String lockIn = 'Lock it in';
  static const String empty = 'Tap the pieces in the order you’d say them.';
  static const String hint = 'TAP A PLACED PIECE TO TAKE IT OUT';

  /// The answer as built so far, the fragments' words joined.
  static String answerSoFar(List<Fragment> fragments, List<String> placed) {
    final byId = {for (final f in fragments) f.id: f.text};
    return [for (final id in placed) ?byId[id]].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final soFar = answerSoFar(fragments, placed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            placed.isEmpty || locked ? label : hint,
            textAlign: TextAlign.center,
            style: BrandVividType.kicker.copyWith(color: grade.glow),
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        // The line, building as the player taps: in the speech panel, where her lines are.
        Semantics(
          liveRegion: true,
          label: soFar.isEmpty ? empty : 'Your answer: $soFar',
          excludeSemantics: true,
          child: SpeechPanel(
            child: Text(
              soFar.isEmpty ? empty : soFar,
              style: BrandType.choice.copyWith(
                color: soFar.isEmpty
                    ? BrandColors.textSecondary
                    : BrandColors.textPrimary,
                fontStyle: soFar.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: BrandSpace.md),
        Timeline(
          duration: BrandMotion.cinematic,
          onFinished: onArrived,
          builder: (context, t, _) => Opacity(
            opacity: t,
            child: Wrap(
              spacing: BrandSpace.sm,
              runSpacing: BrandSpace.sm,
              children: [
                for (final f in fragments)
                  FragmentChip(
                    text: f.text,
                    grade: grade,
                    position: placed.contains(f.id)
                        ? placed.indexOf(f.id) + 1
                        : null,
                    onTap: locked ? null : () => onToggle(f),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BrandSpace.md),
        VividButton(
          label: lockIn,
          expand: true,
          onPressed: placed.isEmpty || locked ? null : onLockIn,
        ),
      ],
    );
  }
}

/// One fragment: a vivid pill at least [BrandSpace.minTarget] tall. Placed, it lights with the
/// sunflower ring and carries its place in the answer.
class FragmentChip extends StatelessWidget {
  const FragmentChip({
    super.key,
    required this.text,
    required this.grade,
    this.position,
    this.onTap,
  });

  final String text;
  final ChapterGrade grade;

  /// 1-based place in the answer, or null when not placed.
  final int? position;
  final VoidCallback? onTap;

  static const double _radius = 16;
  static const double _ring = 2;
  static const double _badge = 22;

  @override
  Widget build(BuildContext context) {
    final position = this.position;
    final placed = position != null;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? BrandMotion.quick
        : BrandMotion.standard;
    return Pressable(
      label: placed ? '$text, placed ${_ordinal(position)}' : text,
      selected: placed,
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: BrandMotion.enter,
        constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.md - BrandSpace.xs,
          vertical: BrandSpace.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: placed ? [grade.deeper, grade.deeper] : grade.cardGradient,
          ),
          border: Border.all(
            color: placed ? BrandVivid.accent : BrandVivid.hairline(),
            width: placed ? _ring : 1,
          ),
          boxShadow: placed
              ? BrandVivid.glowShadow(BrandVivid.accent)
              : BrandVivid.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (placed) ...[
              Container(
                width: _badge,
                height: _badge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandVivid.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$position',
                  style: BrandVividType.kicker.copyWith(
                    color: BrandVivid.night,
                  ),
                ),
              ),
              const SizedBox(width: BrandSpace.sm),
            ],
            Flexible(child: Text(text, style: BrandVividType.row)),
          ],
        ),
      ),
    );
  }

  static String _ordinal(int n) => switch (n) {
    1 => 'first',
    2 => 'second',
    3 => 'third',
    4 => 'fourth',
    _ => 'fifth',
  };
}
