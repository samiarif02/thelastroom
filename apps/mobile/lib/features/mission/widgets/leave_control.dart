import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// The way out of a scene that doesn't need a back gesture (brief 24, no dead ends): Chrome and
/// iOS have no system back button, so a small × at the top right opens the same "Leave the
/// interview?" sheet as Android's back.
class LeaveControl extends StatelessWidget {
  const LeaveControl({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const String label = 'Leave the interview';
  static const double size = BrandSpace.minTarget;
  static const double _disc = 32;
  static const double _arm = 5.5;
  static const double _stroke = 1.8;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onPressed,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BrandVivid.night.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: BrandVivid.hairline(0.3)),
            ),
            child: const SizedBox.square(
              dimension: _disc,
              child: CustomPaint(painter: _Cross()),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Cross extends CustomPainter {
  const _Cross();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = BrandVivid.onDeep
      ..strokeWidth = LeaveControl._stroke
      ..strokeCap = StrokeCap.round;
    const a = LeaveControl._arm;
    canvas
      ..drawLine(c.translate(-a, -a), c.translate(a, a), paint)
      ..drawLine(c.translate(a, -a), c.translate(-a, a), paint);
  }

  @override
  bool shouldRepaint(_Cross oldDelegate) => false;
}
