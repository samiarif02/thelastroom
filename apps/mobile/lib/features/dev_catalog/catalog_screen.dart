import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'catalog_controller.dart';
import 'catalog_controls.dart';
import 'catalog_entries.dart';
import 'catalog_entry.dart';

/// `/dev/catalog`: every film-kit component, each opening on its states. Debug and profile
/// builds only (see router.dart). The toggles carry into every page.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  static const String heading = 'The film kit';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(catalogSettingsProvider);
    final grade = settings.grade;
    return MediaQuery(
      data: settings.apply(MediaQuery.of(context)),
      child: ColoredBox(
        color: BrandColors.void_,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topRight,
                  child: CatalogPill(children: catalogToggles(ref)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.md,
                  BrandSpace.lg,
                  BrandSpace.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEV · CATALOG',
                        style: BrandType.eyebrow.copyWith(color: grade.key),
                      ),
                      const SizedBox(height: BrandSpace.sm),
                      Semantics(
                        header: true,
                        child: const Text(heading, style: BrandType.display),
                      ),
                      const SizedBox(height: BrandSpace.sm),
                      Text(
                        'Every component in every state. STILL is reduced motion, 2X doubles the '
                        'text, the grade cycles the three chapters.',
                        style: BrandType.body.copyWith(
                          color: BrandColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  0,
                  BrandSpace.lg,
                  BrandSpace.xl,
                ),
                sliver: SliverList.separated(
                  itemCount: CatalogEntries.all.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BrandSpace.sm),
                  itemBuilder: (context, i) =>
                      _EntryPlate(entry: CatalogEntries.all[i], grade: grade),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryPlate extends StatelessWidget {
  const _EntryPlate({required this.entry, required this.grade});

  final CatalogEntry entry;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) {
    final count = entry.shots.length;
    return Semantics(
      button: true,
      label: 'Open ${entry.name}, $count ${count == 1 ? 'state' : 'states'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/dev/catalog/${entry.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.surfaceRaised,
            border: Border(
              left: BorderSide(color: grade.key, width: _bar),
              top: const BorderSide(color: BrandColors.line),
              right: const BorderSide(color: BrandColors.line),
              bottom: const BorderSide(color: BrandColors.line),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BrandSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: BrandType.numeral.copyWith(
                          color: BrandColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: BrandType.label.copyWith(color: grade.key),
                    ),
                  ],
                ),
                const SizedBox(height: BrandSpace.xs),
                Text(
                  entry.note,
                  style: BrandType.choice.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _bar = 2;
}
