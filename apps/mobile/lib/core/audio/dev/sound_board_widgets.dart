import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

/// A section of the board: an eyebrow, a line of explanation, then its controls.
class BoardSection extends StatelessWidget {
  const BoardSection({
    super.key,
    required this.title,
    required this.note,
    required this.child,
  });

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BrandSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: BrandType.eyebrow)),
          const SizedBox(height: BrandSpace.xs),
          Text(
            note,
            style: BrandType.body.copyWith(color: BrandColors.textSecondary),
          ),
          const SizedBox(height: BrandSpace.md),
          child,
        ],
      ),
    );
  }
}

/// A plain brass-edged button for the board (dev only, so no film treatment).
class BoardButton extends StatelessWidget {
  const BoardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Lit while what it starts is playing (a loop, the duck).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final key = ChapterGrade.lobby.key;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BrandSpace.minTarget,
              minWidth: BrandSpace.minTarget,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: active
                    ? key.withValues(alpha: 0.18)
                    : BrandColors.surface,
                border: Border.all(color: active ? key : BrandColors.line),
                borderRadius: BorderRadius.circular(BrandRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrandSpace.md,
                  vertical: BrandSpace.sm,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: BrandType.body.copyWith(
                      color: active ? key : BrandColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Buttons that wrap onto as many lines as they need.
class BoardButtons extends StatelessWidget {
  const BoardButtons({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: BrandSpace.sm,
    runSpacing: BrandSpace.sm,
    children: children,
  );
}
