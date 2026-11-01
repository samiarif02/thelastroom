import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import 'vivid_button.dart';

/// The pinned band at the top of a sub-screen (brief 31: one header, everywhere): the way back,
/// the screen's title, and an optional [trailing] (the Recall Room's streak). It sits on the top
/// of the sky, opaque, so nothing scrolls through it. At 2x text the back button is capped and
/// the title takes two lines at most, so the band never overflows or stacks letters.
class VividHeader extends StatelessWidget {
  const VividHeader({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    this.trailing,
  });

  final String title;

  /// "Tower": shown after a ‹, and what a screen reader hears.
  final String backLabel;
  final VoidCallback onBack;
  final Widget? trailing;

  static const double _backShare = 0.45;
  static const int _titleLines = 2;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: BrandVivid.skyTop,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        BrandSpace.md,
        BrandSpace.sm,
        BrandSpace.md,
        BrandSpace.sm,
      ),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * _backShare),
              child: Semantics(
                label: 'Back to the $backLabel',
                button: true,
                excludeSemantics: true,
                onTap: onBack,
                child: VividButton(
                  label: '‹  $backLabel',
                  primary: false,
                  onPressed: onBack,
                ),
              ),
            ),
            const SizedBox(width: BrandSpace.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: _titleLines,
                  overflow: TextOverflow.ellipsis,
                  style: BrandVividType.title,
                ),
              ),
            ),
            if (trailing case final t?) ...[
              const SizedBox(width: BrandSpace.sm),
              t,
            ],
          ],
        ),
      ),
    ),
  );
}
