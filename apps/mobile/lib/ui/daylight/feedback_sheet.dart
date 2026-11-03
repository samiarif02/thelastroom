import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'arch_frame.dart';
import 'chapter_tint.dart';
import 'entrance.dart';
import 'tactile_button.dart';

/// What a reason pick earned (direction.md, "Why that line?").
enum FeedbackTone {
  /// A sound pick: the interviewer nods, "That's the principle.", XP.
  sound,

  /// A tempting pick: "Close, but not quite." and why it tempts.
  close,

  /// A guess (under 1.5 s): "You barely looked at those."
  guess,
}

/// The sheet that rises after a pick (moment 3): the interviewer reacting in a small arch, a
/// verdict, an optional "+10 XP" that pops in, the one-line lesson on the floor's tint, and the
/// next step. It rises over [DaylightMotion.move] and its parts arrive 60 ms apart; under
/// reduced motion it fades. No red anywhere: a miss is calm.
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({
    super.key,
    required this.person,
    required this.tone,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.note,
    this.xp,
    this.lesson,
    this.lessonIcon,
    this.actionIcon,
    this.floor,
  });

  final CastPerson person;
  final FeedbackTone tone;

  /// "That's the principle."
  final String title;

  /// "Marcus nods. Trust goes up one."
  final String? note;

  /// XP earned, shown as "+10 XP".
  final int? xp;

  /// The one line to keep.
  final String? lesson;
  final IconData? lessonIcon;

  /// "Next: land the answer".
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final FloorColours? floor;

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: DaylightMotion.move,
  );

  @override
  void initState() {
    super.initState();
    _rise.forward();
  }

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  static const double _portraitWidth = 56;
  static const double _portraitHeight = 64;
  static const double _xpTurn = -0.07; // about −4°
  static const double _xpFrom = 0.6;
  static const double _lessonIcon = 20;

  @override
  Widget build(BuildContext context) {
    final f = widget.floor ?? ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final sound = widget.tone == FeedbackTone.sound;
    final xp = widget.xp;
    final lesson = widget.lesson;
    final parts = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArchPortrait(
            person: widget.person,
            expression: sound ? CastExpression.nod : CastExpression.hmm,
            width: _portraitWidth,
            height: _portraitHeight,
            ground: f.soft,
          ),
          const SizedBox(width: DaylightSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: DaylightType.heading6.copyWith(
                    color: sound ? f.deep : DaylightColors.ink,
                  ),
                ),
                if (widget.note case final note?)
                  Text(
                    note,
                    style: DaylightType.body6.copyWith(
                      color: DaylightColors.ink2,
                    ),
                  ),
              ],
            ),
          ),
          if (xp != null) ...[
            const SizedBox(width: DaylightSpace.s8),
            _XpPop(xp: xp, still: still),
          ],
        ],
      ),
      if (lesson != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DaylightSpace.s16),
          decoration: BoxDecoration(
            color: f.tint,
            borderRadius: BorderRadius.circular(DaylightRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.lessonIcon case final icon?) ...[
                Icon(icon, size: _lessonIcon, color: f.deep),
                const SizedBox(width: DaylightSpace.s12),
              ],
              Expanded(child: Text(lesson, style: DaylightType.body5)),
            ],
          ),
        ),
      TactileButton(
        label: widget.actionLabel,
        icon: widget.actionIcon,
        onPressed: widget.onAction,
      ),
    ];
    final sheet = Container(
      width: double.infinity,
      // Clear of the navigation bar: the sheet's white runs under it.
      padding: EdgeInsets.fromLTRB(
        DaylightSpace.s16,
        DaylightSpace.s24,
        DaylightSpace.s16,
        DaylightSpace.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: DaylightColors.raised,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DaylightRadius.panel),
        ),
        boxShadow: DaylightElevation.lift,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: DaylightSpace.s16),
            Entrance(index: i + 1, child: part),
          ],
        ],
      ),
    );
    final curve = CurvedAnimation(parent: _rise, curve: DaylightMotion.ease);
    return Semantics(
      liveRegion: true,
      child: still
          ? FadeTransition(opacity: curve, child: sheet)
          : SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curve),
              child: sheet,
            ),
    );
  }
}

class _XpPop extends StatelessWidget {
  const _XpPop({required this.xp, required this.still});

  final int xp;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final chip = Transform.rotate(
      angle: _FeedbackSheetState._xpTurn,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DaylightSpace.s12,
          vertical: DaylightSpace.s4,
        ),
        decoration: BoxDecoration(
          color: DaylightColors.honey,
          borderRadius: BorderRadius.circular(DaylightRadius.inner),
          boxShadow: DaylightElevation.edgeOf(
            DaylightColors.honeyEdge,
            depth: DaylightSize.edgeSmall,
          ),
        ),
        child: Text(
          '+$xp XP',
          style: DaylightType.tabular(DaylightType.body4)
              .copyWith(color: DaylightColors.onHoney),
        ),
      ),
    );
    if (still) return chip;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _FeedbackSheetState._xpFrom, end: 1),
      duration: DaylightMotion.move,
      curve: DaylightMotion.ease,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: chip,
    );
  }
}
