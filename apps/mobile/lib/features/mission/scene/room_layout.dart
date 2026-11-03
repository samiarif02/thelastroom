import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/daylight/daylight_kit.dart';

/// The room with the speech bubble over its foot (direction.md §2, mockup `02`): the stage
/// (r24, the floor's soft wall, the city through the arched glass, the plant, the desk, the
/// interviewer) and, overlapping it by 32, the [bubble]. [overlays] sit on the stage ("Recording",
/// "Listening"). At large text the room shrinks to a strip so the cards still fit.
class RoomWithBubble extends StatelessWidget {
  const RoomWithBubble({
    super.key,
    required this.person,
    required this.expression,
    required this.bubble,
    required this.semanticLabel,
    this.compact = false,
    this.overlays = const [],
  });

  final CastPerson person;
  final CastExpression expression;
  final Widget bubble;
  final String semanticLabel;
  final bool compact;
  final List<Widget> overlays;

  /// How far the bubble climbs over the room.
  static const double overlap = DaylightSpace.s32;

  @override
  Widget build(BuildContext context) {
    final height = compact ? RoomStage.compactHeight : RoomStage.defaultHeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height - overlap,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: height,
            maxHeight: height,
            child: AnimatedSwitcher(
              // A new speaker steps into the room (a panel's second interviewer).
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : DaylightMotion.colour,
              child: RoomStage(
                key: ValueKey(person.id),
                person: person,
                expression: expression,
                height: height,
                overlays: overlays,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DaylightSpace.s8),
          child: bubble,
        ),
      ],
    );
  }
}

/// "Why those details?" (direction.md §3, mockup `03`): the interviewer in an arch, thinking,
/// beside the [bubble] with its tail pointing to them.
class WhyHeader extends StatelessWidget {
  const WhyHeader({
    super.key,
    required this.person,
    required this.expression,
    required this.bubble,
    required this.semanticLabel,
    this.compact = false,
  });

  final CastPerson person;
  final CastExpression expression;
  final Widget bubble;
  final String semanticLabel;
  final bool compact;

  static const double _width = 104;
  static const double _height = 128;
  static const double _compact = 0.6;

  @override
  Widget build(BuildContext context) {
    final k = compact ? _compact : 1.0;
    return Row(
      children: [
        ArchPortrait(
          person: person,
          expression: expression,
          width: _width * k,
          height: _height * k,
          ground: ChapterTint.floorOf(context).soft,
          semanticLabel: semanticLabel,
        ),
        const SizedBox(width: DaylightSpace.s24),
        Expanded(child: bubble),
      ],
    );
  }
}

/// "Your line" (mockup `03`): the line just said, white 60%, r16, with a check, so the reason
/// is picked with it in view.
class YourLine extends StatelessWidget {
  const YourLine({super.key, required this.label, required this.text});

  final String label;
  final String text;

  static const double _veil = 0.6;
  static const double _icon = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.raised.withValues(alpha: _veil),
        borderRadius: BorderRadius.circular(DaylightRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorFill.checkCircle, size: _icon, color: f.base),
                const SizedBox(width: DaylightSpace.s4),
                Text(
                  label,
                  style: DaylightType.caption3.copyWith(color: f.deep),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s4),
            Text('“$text”', style: DaylightType.body2),
          ],
        ),
      ),
    );
  }
}

/// The beat's clock (direction.md §2, Calm mode off): a thin line in the floor's colour
/// draining under the top bar, and the seconds as a number only under ten.
class TimerLine extends StatelessWidget {
  const TimerLine({super.key, required this.elapsed, this.secondsLeft});

  /// 0 → 1 as the beat's time runs out.
  final double elapsed;
  final int? secondsLeft;

  static const double _height = 3;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final left = secondsLeft;
    // It changes every frame for a minute: its own layer, so the room and the cards under it
    // aren't repainted with it (NFR-3).
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DaylightSpace.s16,
          DaylightSpace.s4,
          DaylightSpace.s16,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_height),
                child: SizedBox(
                  height: _height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: DaylightColors.raised),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (1 - elapsed).clamp(0.0, 1.0),
                        child: ColoredBox(
                          color: left == null
                              ? f.base
                              : DaylightColors.honeyEdge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (left != null) ...[
              const SizedBox(width: DaylightSpace.s8),
              Semantics(
                liveRegion: true,
                label: '$left seconds',
                excludeSemantics: true,
                child: Text(
                  '$left',
                  style: DaylightType.tabular(DaylightType.body4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
