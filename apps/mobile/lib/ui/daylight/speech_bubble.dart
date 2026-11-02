import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'chapter_tint.dart';

/// Where the bubble's tail points: up at a stage, or left at a portrait beside it.
enum BubbleTail { top, left, none }

/// What the interviewer says (direction.md, "Answer cards"): a white bubble with a soft lift,
/// the speaker's name as a Caption 3 kicker in the floor's deep colour, and the line in
/// Heading 6 (or [lineStyle]). The line is a quote from a person, so it's set roman, never
/// italic.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.line,
    this.speaker,
    this.tail = BubbleTail.top,
    this.lineStyle,
    this.floor,
    this.flat = false,
  });

  final String line;

  /// "Marcus · hiring manager".
  final String? speaker;
  final BubbleTail tail;

  /// Heading 6 by default; Heading 5 for a short question, Body 2 for a long reply.
  final TextStyle? lineStyle;
  final FloorColours? floor;

  /// An edge instead of the lift (a bubble sitting on paper, the debrief's).
  final bool flat;

  static const double _tail = 16;
  static const double _tailInset = 16;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DaylightSpace.s16,
        DaylightSpace.s12,
        DaylightSpace.s16,
        DaylightSpace.s16,
      ),
      decoration: BoxDecoration(
        color: DaylightColors.raised,
        borderRadius: BorderRadius.circular(DaylightRadius.card),
        boxShadow: flat ? DaylightElevation.edge : DaylightElevation.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (speaker case final speaker?) ...[
            Text(speaker, style: DaylightType.caption3.copyWith(color: f.deep)),
            const SizedBox(height: DaylightSpace.s4),
          ],
          Text(line, style: lineStyle ?? DaylightType.heading6),
        ],
      ),
    );
    if (tail == BubbleTail.none) return bubble;
    final diamond = Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: _tail,
        height: _tail,
        decoration: BoxDecoration(
          color: DaylightColors.raised,
          borderRadius: BorderRadius.circular(DaylightSpace.s2),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        if (tail == BubbleTail.top)
          Positioned(
            top: -_tail / 2,
            left: 0,
            right: 0,
            child: Center(child: diamond),
          )
        else
          Positioned(left: -_tail / 2 + 2, top: _tailInset, child: diamond),
      ],
    );
  }
}
