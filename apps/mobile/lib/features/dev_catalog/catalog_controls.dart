import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_controller.dart';

/// One control in the catalog's pill: a tracked caps label in a 44 pt target.
class CatalogControl extends StatelessWidget {
  const CatalogControl({
    super.key,
    required this.label,
    required this.semantics,
    required this.onTap,
    this.on = false,
    this.grade = ChapterGrade.lobby,
  });

  final String label;
  final String semantics;
  final VoidCallback onTap;

  /// Lit in the grade's brass: the current shot, a toggle that's on.
  final bool on;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: semantics,
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: BrandSpace.minTarget,
          minHeight: BrandSpace.minTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _padX),
          // heightFactor keeps the pill as tall as a control, not the screen.
          child: Center(
            heightFactor: 1,
            child: Text(
              label,
              style: BrandType.label.copyWith(
                color: on ? grade.key : BrandColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  static const double _padX = 10;
}

/// The dark pill the controls sit in. Scrolls sideways when they don't fit.
class CatalogPill extends StatelessWidget {
  const CatalogPill({super.key, required this.children});

  final List<Widget> children;

  static const double _alpha = 0.86;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(BrandSpace.sm),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.void_.withValues(alpha: _alpha),
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(BrandRadius.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
  );
}

/// Reduced motion, 2x text and the grade: the three toggles every catalog page carries.
List<Widget> catalogToggles(WidgetRef ref) {
  final s = ref.watch(catalogSettingsProvider);
  final n = ref.read(catalogSettingsProvider.notifier);
  return [
    CatalogControl(
      label: 'STILL',
      semantics: 'Reduced motion, ${s.reduceMotion ? 'on' : 'off'}',
      on: s.reduceMotion,
      grade: s.grade,
      onTap: n.toggleReduceMotion,
    ),
    CatalogControl(
      label: '2X',
      semantics: 'Double text size, ${s.largeText ? 'on' : 'off'}',
      on: s.largeText,
      grade: s.grade,
      onTap: n.toggleLargeText,
    ),
    CatalogControl(
      label: s.grade.label.toUpperCase(),
      semantics: 'Grade: ${s.grade.label}. Tap for the next chapter',
      on: true,
      grade: s.grade,
      onTap: n.nextGrade,
    ),
  ];
}
