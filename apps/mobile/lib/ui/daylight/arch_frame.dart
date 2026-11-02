import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../figure/cast_figure.dart';

/// The motif (direction.md, "The arched window"): one shape for everything that stands for a
/// person or a place. A round top, [DaylightRadius.card] at the bottom, a flat [ground], an
/// optional white [border] and a [sill] (a strip in the floor's deep colour at the bottom).
/// Whatever it holds is clipped to the arch.
class ArchFrame extends StatelessWidget {
  const ArchFrame({
    super.key,
    required this.child,
    this.ground = DaylightColors.sky,
    this.border = 0,
    this.borderColor = DaylightColors.raised,
    this.sill,
    this.bottomRadius = DaylightRadius.card,
  });

  final Widget child;
  final Color ground;

  /// A frame round the arch (the up-next card's window has 4 of white).
  final double border;
  final Color borderColor;

  /// The window sill's colour; null for none.
  final Color? sill;

  /// The bottom corners (0 sits it flat on a card's edge).
  final double bottomRadius;

  static const double sillHeight = 8;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: const Radius.circular(DaylightRadius.archTop),
      bottom: Radius.circular(bottomRadius),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: radius,
        border: border > 0
            ? Border.all(color: borderColor, width: border)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(border),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (sill case final sill?)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: sillHeight,
                  child: ColoredBox(color: sill),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An interviewer in an arch: the avatar shape everywhere a person appears (the welcome-back
/// card, the "why?" step, the debrief, the reward's panel). The bust stands on the arch's
/// bottom edge, a little wider than the arch so the shoulders are cropped by it.
class ArchPortrait extends StatelessWidget {
  const ArchPortrait({
    super.key,
    required this.person,
    this.expression = CastExpression.neutral,
    this.width = 104,
    this.height = 128,
    this.ground,
    this.border = 0,
    this.borderColor = DaylightColors.raised,
    this.sill,
    this.idle = true,
    this.semanticLabel,
  });

  final CastPerson person;
  final CastExpression expression;
  final double width;
  final double height;

  /// The arch's colour; the floor's soft colour suits most grounds. Defaults to the sky.
  final Color? ground;
  final double border;
  final Color borderColor;
  final Color? sill;
  final bool idle;
  final String? semanticLabel;

  /// How much wider than the arch the bust is drawn.
  static const double _overscan = 1.2;

  @override
  Widget build(BuildContext context) {
    final inner = width - border * 2;
    final bust = inner * _overscan;
    return SizedBox(
      width: width,
      height: height,
      child: ArchFrame(
        ground: ground ?? DaylightColors.sky,
        border: border,
        borderColor: borderColor,
        sill: sill,
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minWidth: bust,
          maxWidth: bust,
          minHeight: bust,
          maxHeight: bust,
          child: SizedBox.square(
            dimension: bust,
            child: CastFigure(
              person: person,
              expression: expression,
              idle: idle,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// A window on the tower (direction.md, "Northstar tower"): lit honey with a check (a room
/// done), the current room with its interviewer inside and a glow ring, unlit (to come) or dark
/// (a floor not open yet).
enum ArchWindowState { lit, current, unlit, dark }

class ArchWindow extends StatelessWidget {
  const ArchWindow({
    super.key,
    required this.state,
    this.person,
    this.floor = DaylightFloors.one,
    this.width = 28,
    this.height = 44,
    this.check,
  });

  final ArchWindowState state;

  /// Who's in the current room.
  final CastPerson? person;
  final FloorColours floor;
  final double width;
  final double height;

  /// The lit window's check glyph.
  final IconData? check;

  static const double _ring = 3;

  /// How much wider than the window the bust inside it is drawn.
  static const double _bust = 1.3;
  static const double _checkSize = 16;

  @override
  Widget build(BuildContext context) {
    final who = person;
    final window = switch (state) {
      ArchWindowState.lit => ArchFrame(
        ground: DaylightColors.honey,
        bottomRadius: DaylightRadius.tag,
        child: check == null
            ? const SizedBox.shrink()
            : Icon(check, size: _checkSize, color: DaylightColors.onHoney),
      ),
      ArchWindowState.current => ArchFrame(
        border: _ring,
        borderColor: floor.soft,
        bottomRadius: DaylightRadius.tag,
        child: who == null
            ? const SizedBox.shrink()
            : OverflowBox(
                alignment: Alignment.bottomCenter,
                minWidth: width * _bust,
                maxWidth: width * _bust,
                minHeight: width * _bust,
                maxHeight: width * _bust,
                child: CastFigure(person: who, idle: false),
              ),
      ),
      ArchWindowState.unlit => ArchFrame(
        ground: floor.deep,
        bottomRadius: DaylightRadius.tag,
        child: const SizedBox.shrink(),
      ),
      ArchWindowState.dark => const ArchFrame(
        ground: DaylightColors.dusk,
        bottomRadius: DaylightRadius.tag,
        child: SizedBox.shrink(),
      ),
    };
    return SizedBox(width: width, height: height, child: window);
  }
}
