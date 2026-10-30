import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// The follow-up question's edit: when [shot] changes, the screen goes to one black frame
/// ([BrandMotion.hardCut]) and comes back on the new [child]. No fade, no move: pressure reads
/// as an edit (DESIGN.md, borrowed from Concrete Noir). [onCut] fires on the black frame.
///
/// Under reduced motion the cut is a short cross-fade instead, like every other camera move.
class HardCut extends StatefulWidget {
  const HardCut({
    super.key,
    required this.shot,
    required this.child,
    this.onCut,
  });

  /// Identifies the framing. A new value cuts.
  final Object shot;
  final Widget child;
  final VoidCallback? onCut;

  @override
  State<HardCut> createState() => _HardCutState();
}

class _HardCutState extends State<HardCut> with SingleTickerProviderStateMixin {
  late final AnimationController _black = AnimationController(
    vsync: this,
    duration: BrandMotion.hardCut,
  )..addStatusListener(_onStatus);

  bool _cutting = false;

  @override
  void didUpdateWidget(HardCut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shot == widget.shot) return;
    widget.onCut?.call();
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _cutting = true);
    _black.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _cutting = false);
    }
  }

  @override
  void dispose() {
    _black.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return AnimatedSwitcher(
        duration: BrandMotion.reducedMotionFade,
        child: KeyedSubtree(key: ValueKey(widget.shot), child: widget.child),
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_cutting)
          const Positioned.fill(child: ColoredBox(color: BrandColors.void_)),
      ],
    );
  }
}
