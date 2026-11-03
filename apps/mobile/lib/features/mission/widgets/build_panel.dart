import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';
import '../../../ui/film/timeline.dart';

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
    this.onLockIn,
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

  /// "Lock it in" under the pieces; null when the screen pins it in its own dock instead (the
  /// mission player does, above the system's gesture bar: QA 51).
  final VoidCallback? onLockIn;

  /// Said: nothing can change, the button is spent.
  final bool locked;
  final VoidCallback? onArrived;

  static const String lockIn = 'Lock it in';
  static const String empty = 'Tap the pieces in the order you’d say them.';
  static const String hint = 'Tap a placed piece to take it out';

  /// The answer as built so far, the fragments' words joined.
  static String answerSoFar(List<Fragment> fragments, List<String> placed) {
    final byId = {for (final f in fragments) f.id: f.text};
    return [for (final id in placed) ?byId[id]].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final soFar = answerSoFar(fragments, placed);
    final f = grade.floor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: DaylightSpace.s12,
          runSpacing: DaylightSpace.s2,
          children: [
            Semantics(
              header: true,
              child: Text(
                label,
                style: DaylightType.title3.copyWith(
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation.weight(600)],
                ),
              ),
            ),
            if (placed.isNotEmpty && !locked)
              Text(
                hint,
                style: DaylightType.caption4.copyWith(
                  color: DaylightColors.ink2,
                ),
              ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s8),
        // The line, building as the player taps: a white card, the words in Body 3.
        Semantics(
          liveRegion: true,
          label: soFar.isEmpty ? empty : 'Your answer: $soFar',
          excludeSemantics: true,
          child: DaylightPanel(
            radius: DaylightRadius.card,
            edge: soFar.isEmpty ? null : f.soft,
            child: Text(
              soFar.isEmpty ? empty : soFar,
              style: DaylightType.body3.copyWith(
                color: soFar.isEmpty ? DaylightColors.ink2 : DaylightColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: DaylightSpace.s12),
        Timeline(
          duration: DaylightMotion.move,
          onFinished: onArrived,
          builder: (context, t, _) => Opacity(
            opacity: t,
            child: Wrap(
              spacing: DaylightSpace.s8,
              runSpacing: DaylightSpace.s8,
              children: [
                for (final fr in fragments)
                  FragmentChip(
                    text: fr.text,
                    grade: grade,
                    position: placed.contains(fr.id)
                        ? placed.indexOf(fr.id) + 1
                        : null,
                    onTap: locked ? null : () => onToggle(fr),
                  ),
              ],
            ),
          ),
        ),
        if (onLockIn case final lock?) ...[
          const SizedBox(height: DaylightSpace.s16),
          TactileButton(
            label: lockIn,
            icon: PhosphorBold.lockSimple,
            onPressed: placed.isEmpty || locked ? null : lock,
          ),
        ],
      ],
    );
  }
}

/// One fragment: a Daylight chip at least 48 tall, white on its edge. Placed, it takes the
/// floor's ring and tint and carries its place in the answer.
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

  static const double _badge = 22;

  @override
  Widget build(BuildContext context) {
    final position = this.position;
    final placed = position != null;
    final f = grade.floor;
    return Tactile(
      label: placed ? '$text, placed ${_ordinal(position)}' : text,
      selected: placed,
      onTap: onTap,
      style: TactileStyle(
        face: placed
            ? Color.alphaBlend(
                f.tint.withValues(alpha: 0.6),
                DaylightColors.raised,
              )
            : DaylightColors.raised,
        edge: placed ? f.deep : DaylightColors.sand2,
        ring: placed ? f.base : null,
        radius: BorderRadius.circular(DaylightRadius.tile),
        depth: DaylightSize.edgeSmall,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: DaylightSize.hit - 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DaylightSpace.s12,
            vertical: DaylightSpace.s8,
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
                    color: f.base,
                    borderRadius: BorderRadius.circular(DaylightRadius.tag),
                  ),
                  child: Text(
                    '$position',
                    style: DaylightType.tabular(DaylightType.caption3)
                        .copyWith(color: DaylightColors.raised),
                  ),
                ),
                const SizedBox(width: DaylightSpace.s8),
              ],
              Flexible(child: Text(text, style: DaylightType.body5)),
            ],
          ),
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
