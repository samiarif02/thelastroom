import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../haptics.dart';
import 'chapter_tint.dart';

/// A setting you switch, in Daylight: the label (Title 3), "On"/"Off" (Caption 4, ink-2), and
/// a track that turns the floor's colour with a white knob. The whole row is the target (48),
/// and screen readers hear a toggle. Reduced motion: the knob jumps.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
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

  static const double _trackW = 48;
  static const double _trackH = 28;
  static const double _knob = 22;

  void _flip() {
    choiceTick();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      toggled: value,
      label: label,
      excludeSemantics: true,
      onTap: _flip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _flip,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: DaylightSize.hit),
          child: Row(
            children: [
              Expanded(child: Text(label, style: DaylightType.title3)),
              const SizedBox(width: DaylightSpace.s8),
              Text(
                value ? on : off,
                style: DaylightType.caption4.copyWith(
                  color: DaylightColors.ink2,
                ),
              ),
              const SizedBox(width: DaylightSpace.s8),
              AnimatedContainer(
                duration: still ? Duration.zero : DaylightMotion.press,
                curve: DaylightMotion.ease,
                width: _trackW,
                height: _trackH,
                padding: const EdgeInsets.all((_trackH - _knob) / 2),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: value ? f.base : DaylightColors.sand2,
                  borderRadius: BorderRadius.circular(_trackH / 2),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DaylightColors.raised,
                  ),
                  child: SizedBox.square(dimension: _knob),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
