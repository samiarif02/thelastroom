import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'icon_tile.dart';

/// Opens a Daylight sheet over the dimmed screen: white, r24 at the top, lifted, up to 85% of
/// the screen and scrolling inside, with a close tile. It rises over [DaylightMotion.move] with
/// a slight settle while the scrim fades in ([daylightSheetTransition]; a fade under reduced
/// motion); a tap on the dim or the system back closes it. [label] names it for screen readers
/// and the barrier.
Future<T?> showDaylightSheet<T>(
  BuildContext context, {
  required String label,
  required WidgetBuilder builder,
}) {
  final still = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: DaylightColors.ink.withValues(alpha: DaylightSheet.scrim),
    transitionDuration: still ? DaylightMotion.colour : DaylightMotion.move,
    pageBuilder: (sheetContext, _, _) => DaylightSheet(
      label: label,
      onClose: () => Navigator.of(sheetContext).pop(),
      child: Builder(builder: builder),
    ),
    transitionBuilder: (context, animation, _, child) =>
        daylightSheetTransition(context, animation, child),
  );
}

/// How every Daylight sheet comes and goes (brief 50): it rises on [DaylightMotion.settle], a
/// touch past its rest and back, while the route's scrim fades in; it leaves on the base curve
/// with no bounce. With no [rise] the sheet travels its full height (a bottom sheet); a [rise]
/// is how far a centred card travels, and the card fades in as it comes. Under reduced motion,
/// only the fade.
Widget daylightSheetTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child, {
  double? rise,
}) {
  final fade = CurvedAnimation(parent: animation, curve: DaylightMotion.ease);
  if (MediaQuery.disableAnimationsOf(context)) {
    return FadeTransition(opacity: fade, child: child);
  }
  final t = CurvedAnimation(
    parent: animation,
    curve: DaylightMotion.settle,
    reverseCurve: DaylightMotion.ease,
  );
  final up = rise;
  if (up == null) {
    return SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
      child: child,
    );
  }
  return FadeTransition(
    opacity: fade,
    child: AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, up * (1 - t.value)),
        child: child,
      ),
    ),
  );
}

/// The sheet itself (see [showDaylightSheet]); the catalog draws it in place.
class DaylightSheet extends StatelessWidget {
  const DaylightSheet({
    super.key,
    required this.label,
    required this.child,
    this.onClose,
  });

  final String label;
  final Widget child;
  final VoidCallback? onClose;

  static const double scrim = 0.4;
  static const double _maxShare = 0.85;

  /// How far the white runs on below the sheet's foot (past any settle).
  static const double skirt = DaylightSpace.s48;
  static const String close = 'Close';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final close = onClose;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * _maxShare),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: label,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: DaylightColors.raised,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(DaylightRadius.panel),
              ),
              boxShadow: DaylightElevation.lift,
            ),
            child: DefaultTextStyle(
              style: DaylightType.body3,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // White below the foot: when the sheet settles a touch past its rest, no
                  // gap opens under it.
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: -skirt,
                    height: skirt,
                    child: ColoredBox(color: DaylightColors.raised),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      DaylightSpace.s16,
                      DaylightSpace.s24,
                      DaylightSpace.s16,
                      media.padding.bottom + DaylightSpace.s24,
                    ),
                    child: SizedBox(width: double.infinity, child: child),
                  ),
                  if (close != null)
                    Positioned(
                      top: DaylightSpace.s8,
                      right: DaylightSpace.s8,
                      child: IconTile.quiet(
                        icon: PhosphorBold.x,
                        semanticLabel: DaylightSheet.close,
                        onPressed: close,
                        nudge: AxisDirection.down,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
