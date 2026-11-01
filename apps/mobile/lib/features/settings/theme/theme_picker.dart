import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/film_kit.dart';
import 'theme_controller.dart';

/// Settings' Theme section (brief 28): every theme as a swatch (its sky, a card, the chapters'
/// colours) with its name; tap one and every screen re-colours at once, and the pick is saved.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  static const String heading = 'THEME';

  static const double _gap = BrandSpace.sm;
  static const double _ring = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);
    final controller = ref.read(themeProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            heading,
            style: BrandVividType.kicker.copyWith(color: BrandVivid.accent),
          ),
        ),
        const SizedBox(height: BrandSpace.sm),
        LayoutBuilder(
          builder: (context, box) {
            final width = (box.maxWidth - _gap) / 2;
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final t in VividThemes.all)
                  SizedBox(
                    width: width,
                    child: Pressable(
                      label: '${t.name} theme. ${t.mood}',
                      selected: t == current,
                      onTap: () => controller.pick(t),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedContainer(
                            duration: BrandMotion.quick,
                            padding: const EdgeInsets.all(_ring),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                BrandRadius.lg,
                              ),
                              border: Border.all(
                                color: t == current
                                    ? BrandVivid.accent
                                    : BrandVivid.hairline(),
                                width: _ring,
                              ),
                            ),
                            child: ThemePreview(palette: t, height: 96),
                          ),
                          const SizedBox(height: BrandSpace.xs),
                          Text(
                            t.name,
                            style: BrandVividType.row.copyWith(
                              color: t == current
                                  ? BrandVivid.accent
                                  : BrandVivid.onDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
