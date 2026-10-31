import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The root screens' back button (brief 20; owner: "when I press back, the app completely
/// closes"). The first back shows a toast, "Press back again to exit"; a second within
/// [window] closes the app. [onBack], when given, handles back first (onboarding steps back a
/// step) and returns true if it did, so the toast is only for the real root.
class BackToExit extends StatefulWidget {
  const BackToExit({super.key, required this.child, this.onBack});

  final Widget child;

  /// Handles back before the exit hint; true if it did something.
  final bool Function()? onBack;

  static const String hint = 'Press back again to exit';

  /// How long the second press has.
  static const Duration window = Duration(seconds: 2);

  /// Closes the app. A seam so tests can watch it without a platform.
  @visibleForTesting
  static Future<void> Function() exit = SystemNavigator.pop;

  @override
  State<BackToExit> createState() => _BackToExitState();
}

class _BackToExitState extends State<BackToExit> {
  Timer? _armed;

  bool get _waiting => _armed?.isActive ?? false;

  void _back() {
    if (widget.onBack?.call() ?? false) return;
    if (_waiting) {
      _armed?.cancel();
      unawaited(BackToExit.exit());
      return;
    }
    setState(() {
      _armed = Timer(BackToExit.window, () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _armed?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: Stack(
      fit: StackFit.expand,
      children: [widget.child, if (_waiting) const _ExitToast()],
    ),
  );
}

/// The hint: an opaque night pill with a sunflower edge and a deep shadow, well above the
/// bottom of the frame, rising in. Never faded, so nothing behind it shows through (the lead's
/// phone review of #22).
class _ExitToast extends StatelessWidget {
  const _ExitToast();

  /// How far above the bottom inset it sits: clear of a list's last row.
  static const double lift = 96;
  static const double _rise = 16;

  @override
  Widget build(BuildContext context) => Positioned(
    left: BrandSpace.lg,
    right: BrandSpace.lg,
    bottom: MediaQuery.paddingOf(context).bottom + lift,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : BrandMotion.quick,
        curve: BrandMotion.enter,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, _rise * (1 - t)),
          child: child,
        ),
        child: Semantics(
          liveRegion: true,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrandVivid.night,
                borderRadius: BorderRadius.circular(BrandRadius.pill),
                border: Border.all(color: BrandVivid.accent, width: 1.5),
                boxShadow: BrandVivid.glowShadow(BrandVivid.night),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: BrandSpace.lg,
                  vertical: BrandSpace.sm + 4,
                ),
                child: Text(
                  BackToExit.hint,
                  textAlign: TextAlign.center,
                  style: BrandVividType.row,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
