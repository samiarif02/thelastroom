import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'arch_frame.dart';
import 'chapter_tint.dart';

/// Where a skill is: earned (only ever without hints), the next one to earn, or locked.
enum SkillState { earned, next, locked }

/// A skill on the shelf (direction.md, "Home"): an arch enamel with the skill's glyph, its name
/// and a hint ("Room 7"). Earned is a honey rim round the floor's deep colour; next is honey,
/// quiet, ringed; locked is sand.
class SkillBadge extends StatelessWidget {
  const SkillBadge({
    super.key,
    required this.icon,
    required this.name,
    this.hint,
    this.state = SkillState.locked,
    this.floor,
    this.width = 64,
    this.labelWidth,
  });

  final IconData icon;
  final String name;
  final String? hint;
  final SkillState state;
  final FloorColours? floor;
  final double width;

  /// The name's column; the arch plus 16 by default (wider at large text, so a name never
  /// breaks inside a word).
  final double? labelWidth;

  static const double _aspect = 76 / 64;
  static const double _iconShare = 0.44;
  static const double _rim = 3;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final (ground, glyph, rim) = switch (state) {
      SkillState.earned => (f.deep, DaylightColors.honey, DaylightColors.honey),
      SkillState.next => (
        DaylightColors.honeyTint,
        DaylightColors.honeyInk,
        DaylightColors.honey,
      ),
      SkillState.locked => (DaylightColors.sand, DaylightColors.ink3, null),
    };
    final status = switch (state) {
      SkillState.earned => 'earned',
      SkillState.next => 'next',
      SkillState.locked => 'locked',
    };
    return Semantics(
      label: '$name, $status${hint == null ? '' : ', $hint'}',
      excludeSemantics: true,
      child: SizedBox(
        width: labelWidth ?? width + DaylightSpace.s16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              height: width * _aspect,
              child: ArchFrame(
                ground: ground,
                border: rim == null ? 0 : _rim,
                borderColor: rim ?? ground,
                child: Icon(icon, size: width * _iconShare, color: glyph),
              ),
            ),
            const SizedBox(height: DaylightSpace.s8),
            Text(
              name,
              style: DaylightType.caption3,
              textAlign: TextAlign.center,
            ),
            if (hint case final hint?)
              Text(
                hint,
                style: DaylightType.caption4.copyWith(
                  color: DaylightColors.ink2,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// The reward screen's medal (direction.md, "Floor cleared"): a big arch with a honey rim,
/// the floor's deep field, the skill's glyph and a white ribbon across it with the name in
/// Bricolage. It sits on the floor's own colour.
class SkillMedal extends StatelessWidget {
  const SkillMedal({
    super.key,
    required this.icon,
    required this.name,
    this.floor,
    this.width = 156,
  });

  final IconData icon;
  final String name;
  final FloorColours? floor;
  final double width;

  static const double _aspect = 1.22;
  static const double _rimShare = 0.09;
  static const double _iconShare = 0.46;
  static const double _ribbonAt = 0.7;
  static const double _ribbonOverhang = 0.12;
  static const double _tail = 12;

  @override
  Widget build(BuildContext context) {
    final f = floor ?? ChapterTint.floorOf(context);
    final height = width * _aspect;
    final overhang = width * _ribbonOverhang;
    return Semantics(
      label: 'Skill earned: $name',
      excludeSemantics: true,
      child: SizedBox(
        width: width + overhang * 2,
        height: height + DaylightSize.edge,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: overhang,
              top: 0,
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: DaylightRadius.arch,
                  boxShadow: DaylightElevation.edgeOf(DaylightColors.honeyEdge),
                ),
                child: ArchFrame(
                  ground: f.deep,
                  border: width * _rimShare,
                  borderColor: DaylightColors.honey,
                  child: Align(
                    alignment: const Alignment(0, -0.3),
                    child: Icon(
                      icon,
                      size: width * _iconShare,
                      color: DaylightColors.raised,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: height * _ribbonAt - DaylightSpace.s24,
              child: Row(
                children: [
                  const _RibbonTail(left: true),
                  Expanded(
                    child: Container(
                      height: DaylightSpace.s48,
                      color: DaylightColors.raised,
                      alignment: Alignment.center,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DaylightType.heading6,
                      ),
                    ),
                  ),
                  const _RibbonTail(left: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonTail extends StatelessWidget {
  const _RibbonTail({required this.left});

  final bool left;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: SkillMedal._tail,
    height: DaylightSpace.s48,
    child: CustomPaint(painter: _TailPainter(left: left)),
  );
}

class _TailPainter extends CustomPainter {
  _TailPainter({required this.left});

  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final notch = left
        ? (Path()
            ..moveTo(w, 0)
            ..lineTo(0, 0)
            ..lineTo(w * 0.7, h / 2)
            ..lineTo(0, h)
            ..lineTo(w, h))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(w, 0)
            ..lineTo(w * 0.3, h / 2)
            ..lineTo(w, h)
            ..lineTo(0, h));
    canvas.drawPath(notch..close(), Paint()..color = DaylightColors.sand2);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.left != left;
}
