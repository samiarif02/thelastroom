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

/// The hint (brief 50: a Daylight snack bubble, the tower's notice): an opaque ink bubble with
/// a door glyph and white text, lifted, well above the bottom of the frame, rising in over
/// [DaylightMotion.colour]. Never faded, so nothing behind it shows through (the lead's phone
/// review of #22); under reduced motion it is simply there.
class _ExitToast extends StatelessWidget {
  const _ExitToast();

  /// How far above the bottom inset it sits: clear of the tab bar and a list's last row.
  static const double lift = DaylightSpace.s96;
  static const double _rise = DaylightSpace.s16;
  static const double _glyph = 18;

  @override
  Widget build(BuildContext context) => Positioned(
    left: DaylightSpace.s16,
    right: DaylightSpace.s16,
    bottom: MediaQuery.paddingOf(context).bottom + lift,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : DaylightMotion.colour,
        curve: DaylightMotion.ease,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, _rise * (1 - t)),
          child: child,
        ),
        child: Semantics(
          liveRegion: true,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DaylightColors.ink,
                borderRadius: BorderRadius.circular(DaylightRadius.card),
                boxShadow: DaylightElevation.lift,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DaylightSpace.s16,
                  vertical: DaylightSpace.s12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        PhosphorBold.door,
                        size: _glyph,
                        color: DaylightColors.honey,
                      ),
                    ),
                    const SizedBox(width: DaylightSpace.s8),
                    Flexible(
                      child: Text(
                        BackToExit.hint,
                        textAlign: TextAlign.center,
                        style: DaylightType.body5.copyWith(
                          color: DaylightColors.raised,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
