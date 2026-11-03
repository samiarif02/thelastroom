import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'tactile_button.dart';

/// A Daylight sheet over the dimmed screen (leave the room? continue where you left off?
/// delete this take?): white, r24 at the top, lifted, fading up into place over
/// [DaylightMotion.move] (only a fade under reduced motion). A title (Heading 5), one line (Body 6,
/// ink-2), the honey [primary] and the quiet [secondary]. While it's up it is all a screen
/// reader reaches. [leading] sits above the title (a portrait, an icon).
class ChoiceSheet extends StatelessWidget {
  const ChoiceSheet({
    super.key,
    required this.title,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    this.leading,
    this.primaryIcon,
  });

  final String title;
  final String line;
  final String primary;
  final VoidCallback? onPrimary;
  final String secondary;
  final VoidCallback? onSecondary;
  final Widget? leading;
  final IconData? primaryIcon;

  static const double _scrim = 0.4;

  /// How far the sheet rises as it fades in: a short lift, so it is where it will be from the
  /// first frame (a tap that comes at once still lands on its buttons).
  static const double _rise = DaylightSpace.s24;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final lead = leading;
    final sheet = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: DaylightColors.raised,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DaylightRadius.panel),
          ),
          boxShadow: DaylightElevation.lift,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            DaylightSpace.s16,
            DaylightSpace.s24,
            DaylightSpace.s16,
            insets.bottom + DaylightSpace.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (lead != null) ...[
                Align(alignment: Alignment.centerLeft, child: lead),
                const SizedBox(height: DaylightSpace.s12),
              ],
              Semantics(
                header: true,
                child: Text(title, style: DaylightType.heading5),
              ),
              const SizedBox(height: DaylightSpace.s4),
              Text(
                line,
                style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
              ),
              const SizedBox(height: DaylightSpace.s24),
              TactileButton(
                label: primary,
                icon: primaryIcon,
                onPressed: onPrimary,
              ),
              const SizedBox(height: DaylightSpace.s8),
              TactileButton(
                label: secondary,
                tone: TactileTone.quiet,
                onPressed: onSecondary,
              ),
            ],
          ),
        ),
      ),
    );
    return BlockSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: still ? DaylightMotion.colour : DaylightMotion.move,
        curve: DaylightMotion.ease,
        builder: (context, t, child) => Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: DaylightColors.ink.withValues(alpha: _scrim * t)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, still ? 0 : (1 - t) * _rise),
                  child: child,
                ),
              ),
            ),
          ],
        ),
        child: sheet,
      ),
    );
  }
}
