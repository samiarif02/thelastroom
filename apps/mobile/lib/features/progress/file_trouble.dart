import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';

/// Your file or the Chapter 1 report couldn't be read from the device (brief 24: every error
/// state designed). Says so plainly, promises nothing is lost, and offers to try again.
class FileTrouble extends StatelessWidget {
  const FileTrouble({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const String title = "Your file didn't open";
  static const String line =
      'Nothing is lost: your missions are kept on this device. Try again in a moment.';
  static const String retry = 'Try again';
  static const double _radius = 22;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BrandSpace.md),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandVivid.locked, BrandVivid.night],
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: BrandVivid.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.lg),
        child: Column(
          children: [
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: BrandVividType.title,
              ),
            ),
            const SizedBox(height: BrandSpace.sm),
            Text(line, textAlign: TextAlign.center, style: BrandVividType.body),
            const SizedBox(height: BrandSpace.lg),
            VividButton(label: retry, expand: true, onPressed: onRetry),
          ],
        ),
      ),
    ),
  );
}
