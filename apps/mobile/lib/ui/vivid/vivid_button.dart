import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'pressable.dart';

/// The vivid screens' buttons (brief 17: one obvious button). [primary] is the sunflower pill
/// with dark ink, lit from below, for the one action that matters ("Play", "Let's go");
/// otherwise a quiet outlined pill in white for the rest ("Skip", "Your file").
class VividButton extends StatelessWidget {
  const VividButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
    this.expand = false,
  });

  /// A big "Play" with the play glyph.
  const VividButton.play({
    super.key,
    this.label = playLabel,
    required this.onPressed,
    this.expand = false,
  }) : primary = true,
       icon = VividButtonIcon.play;

  static const String playLabel = 'Play';

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final VividButtonIcon? icon;

  /// Fill the width it's given.
  final bool expand;

  static const double _height = 56;
  static const double _quietHeight = 44;
  static const double _glyph = 16;
  static const double _quietAlpha = 0.5;
  static const double _disabledOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final text = primary
        ? BrandVividType.button
        : BrandVividType.button.copyWith(
            color: BrandVivid.onDeep,
            fontSize: 15,
          );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon == VividButtonIcon.play) ...[
          CustomPaint(
            size: const Size.square(_glyph),
            painter: _PlayGlyph(color: text.color ?? BrandVivid.onAccent),
          ),
          const SizedBox(width: BrandSpace.sm),
        ],
        Flexible(
          child: Text(label, textAlign: TextAlign.center, style: text),
        ),
      ],
    );
    final pill = Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Container(
        constraints: BoxConstraints(
          minHeight: primary ? _height : _quietHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: primary ? BrandSpace.lg : BrandSpace.md,
          vertical: BrandSpace.sm,
        ),
        decoration: BoxDecoration(
          color: primary ? BrandVivid.accent : null,
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [BrandVivid.accent, BrandVivid.accentPressed],
                )
              : null,
          borderRadius: BorderRadius.circular(BrandRadius.pill),
          border: primary
              ? null
              : Border.all(color: BrandVivid.hairline(_quietAlpha)),
          boxShadow: primary && enabled
              ? BrandVivid.glowShadow(BrandVivid.accent)
              : null,
        ),
        child: Center(
          widthFactor: expand ? null : 1,
          heightFactor: 1,
          child: content,
        ),
      ),
    );
    return Pressable(label: label, onTap: onPressed, child: pill);
  }
}

enum VividButtonIcon { play }

class _PlayGlyph extends CustomPainter {
  const _PlayGlyph({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w * 0.15, h)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PlayGlyph old) => old.color != color;
}
