import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// The app's title (brief 20): on the evening sky, the tower's windows light up floor by
/// floor from the street to the top, the last room glows raspberry, then the name arrives.
/// About [length] long; under reduced motion it shows its last frame at once. [onLanded] fires
/// when the name has arrived. Not interactive: the screen around it decides what a tap does.
class VividTitle extends StatelessWidget {
  const VividTitle({super.key, this.onLanded, this.footer});

  final VoidCallback? onLanded;

  /// Below the name once it has landed: "Begin" on the first launch.
  final Widget? footer;

  static const String title = 'THE LAST ROOM';
  static const String tagline = 'One room left between you and the offer.';

  /// The whole title, from the first window to the name settled.
  static const Duration length = Duration(milliseconds: 1400);

  // The cue sheet, as shares of [length].
  static const double _lightsTo = 0.7;
  static const double _nameFrom = 0.45;
  static const double _footFrom = 0.8;
  static const double _rise = 18;
  static const double _towerShare = 0.42;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const VividBackdrop(),
        Timeline(
          duration: still ? Duration.zero : length,
          onFinished: onLanded,
          builder: (context, t, _) {
            final at = still ? 1.0 : t;
            final lights = cue(at, 0, _lightsTo, BrandMotion.camera);
            final name = cue(at, _nameFrom, 1, BrandMotion.enter);
            final foot = cue(at, _footFrom, 1, BrandMotion.enter);
            return SafeArea(
              child: LayoutBuilder(
                // Fills the frame, and scrolls only when large text makes it taller.
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(),
                          SizedBox(
                            height: box.maxHeight * _towerShare,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: TowerPainter(lit: lights),
                            ),
                          ),
                          const SizedBox(height: BrandSpace.lg),
                          Opacity(
                            opacity: name,
                            child: Transform.translate(
                              offset: Offset(0, _rise * (1 - name)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BrandSpace.lg,
                                ),
                                child: Column(
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: BrandVividType.hero.copyWith(
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: BrandSpace.sm),
                                    Text(
                                      tagline,
                                      textAlign: TextAlign.center,
                                      style: BrandVividType.body,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (footer case final f?)
                            Opacity(
                              opacity: foot,
                              child: IgnorePointer(
                                ignoring: foot < 1,
                                child: f,
                              ),
                            ),
                          const SizedBox(height: BrandSpace.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
