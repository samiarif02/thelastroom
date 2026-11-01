import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';

/// A setting you switch (brief 23: one switch, everywhere): its label, ON/OFF, and a pill
/// track that turns sunflower with a white knob. The whole row is the target (44 pt), it sinks a
/// little under the finger, and screen readers hear a toggle.
class VividToggle extends StatefulWidget {
  const VividToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const String on = 'On';
  static const String off = 'Off';

  @override
  State<VividToggle> createState() => _VividToggleState();
}

class _VividToggleState extends State<VividToggle> {
  bool _down = false;

  static const double _trackW = 52;
  static const double _trackH = 30;
  static const double _knob = 24;
  static const double _pressed = 0.97;
  static const double _edgeAlpha = 0.3;

  void _flip() {
    choiceTick();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final value = widget.value;
    return Semantics(
      toggled: value,
      label: widget.label,
      excludeSemantics: true,
      onTap: _flip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: _flip,
        child: AnimatedScale(
          scale: _down && !still ? _pressed : 1,
          duration: BrandMotion.quick,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: BrandSpace.minTarget),
            child: Row(
              children: [
                Expanded(child: Text(widget.label, style: BrandVividType.row)),
                const SizedBox(width: BrandSpace.sm),
                Text(
                  (value ? VividToggle.on : VividToggle.off).toUpperCase(),
                  style: BrandVividType.kicker,
                ),
                const SizedBox(width: BrandSpace.sm),
                AnimatedContainer(
                  duration: still ? Duration.zero : BrandMotion.quick,
                  curve: BrandMotion.enter,
                  width: _trackW,
                  height: _trackH,
                  padding: const EdgeInsets.all((_trackH - _knob) / 2),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: value ? BrandVivid.accent : BrandVivid.locked,
                    borderRadius: BorderRadius.circular(BrandRadius.pill),
                    border: Border.all(color: BrandVivid.hairline(_edgeAlpha)),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandVivid.onDeep,
                    ),
                    child: const SizedBox.square(dimension: _knob),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
