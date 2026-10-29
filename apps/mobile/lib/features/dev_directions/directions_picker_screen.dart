import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'direction_studio.dart';

/// `/dev/directions`: the three prototype directions side by side, each a poster in its own
/// type and light. Debug builds only.
class DirectionsPickerScreen extends StatelessWidget {
  const DirectionsPickerScreen({super.key});

  static const String heading = 'Three directions';

  // BrandType has no bundled font until brief 06 picks one, and on the web an unbundled family
  // means a runtime font download. This dev screen borrows the neutral sans from direction A.
  static final TextStyle _label = BrandType.label.copyWith(
    fontFamily: nightGlass.type.body.fontFamily,
  );
  static final TextStyle _display = nightGlass.type.display;
  static final TextStyle _body = nightGlass.type.body.copyWith(
    color: BrandColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandColors.void_,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.lg,
                BrandSpace.xl,
                BrandSpace.lg,
                BrandSpace.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEV · BRIEF 03', style: _label),
                    const SizedBox(height: BrandSpace.sm),
                    Semantics(
                      header: true,
                      child: Text(heading, style: _display),
                    ),
                    const SizedBox(height: BrandSpace.sm),
                    Text(
                      'Mission 1, three ways. Open one, then step through its title card, scene and dossier.',
                      style: _body,
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
                itemCount: DirectionStudio.all.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BrandSpace.md),
                itemBuilder: (context, i) =>
                    _Poster(studio: DirectionStudio.all[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.studio});

  final DirectionStudio studio;

  @override
  Widget build(BuildContext context) {
    final d = studio.direction;
    final p = d.palette;
    final grade = d.lobby;
    return Semantics(
      button: true,
      label: 'Open direction ${d.letter}, ${d.name}',
      child: GestureDetector(
        onTap: () => context.push('/dev/directions/${d.id}'),
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.line),
              gradient: RadialGradient(
                center: const Alignment(0.7, -0.9),
                radius: 1.3,
                colors: [grade.key.withValues(alpha: 0.2), p.surface],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BrandSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'DIRECTION ${d.letter}',
                          style: d.type.eyebrow.copyWith(color: grade.key),
                        ),
                      ),
                      for (final g in d.grades)
                        Padding(
                          padding: const EdgeInsets.only(left: BrandSpace.xs),
                          child: SizedBox.square(
                            dimension: 10,
                            child: ColoredBox(color: g.key),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: BrandSpace.md),
                  Text(d.name, style: d.type.display),
                  const SizedBox(height: BrandSpace.sm),
                  Text(
                    d.mood,
                    style: d.type.body.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: BrandSpace.md),
                  Text(d.references.toUpperCase(), style: d.type.label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
