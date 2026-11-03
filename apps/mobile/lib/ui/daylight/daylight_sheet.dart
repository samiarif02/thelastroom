import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'icon_tile.dart';

/// Opens a Daylight sheet over the dimmed screen: white, r24 at the top, lifted, up to 85% of
/// the screen and scrolling inside, with a close tile. It rises over [DaylightMotion.move]
/// (fades under reduced motion); a tap on the dim or the system back closes it. [label] names
/// it for screen readers and the barrier.
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
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: DaylightMotion.ease);
      if (still) return FadeTransition(opacity: t, child: child);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
        child: child,
      );
    },
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
                children: [
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
