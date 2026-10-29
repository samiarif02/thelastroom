import 'package:flutter/widgets.dart';

/// Cinema bars. [t] 0 is open frame, 1 is fully letterboxed. Under reduced motion the bars fade
/// in place rather than slide.
class Letterbox extends StatelessWidget {
  const Letterbox({
    super.key,
    required this.t,
    required this.color,
    this.fraction = 0.13,
  });

  final double t;
  final Color color;

  /// Each bar's height as a share of the screen at full letterbox.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final full = box.maxHeight * fraction;
          final height = still ? full : full * t;
          final opacity = still ? t : 1.0;
          Widget bar() => Opacity(
            opacity: opacity,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: ColoredBox(color: color),
            ),
          );
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [bar(), bar()],
          );
        },
      ),
    );
  }
}
