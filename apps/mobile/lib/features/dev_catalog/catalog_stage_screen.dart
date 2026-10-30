import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'catalog_controller.dart';
import 'catalog_controls.dart';
import 'catalog_entry.dart';

/// `/dev/catalog/<id>`: one component, one state at a time, full frame, under the catalog's
/// toggles. A slim pill of controls sits top-right (back, the states, replay, the toggles,
/// hide). Hide it for screenshots, or open the route with `?chrome=off`; a long press anywhere
/// brings it back.
class CatalogStageScreen extends ConsumerStatefulWidget {
  const CatalogStageScreen({
    super.key,
    required this.entry,
    this.shot,
    this.chrome = true,
  });

  final CatalogEntry entry;

  /// The state to open on (`?shot=`); the first when null or unknown.
  final String? shot;
  final bool chrome;

  @override
  ConsumerState<CatalogStageScreen> createState() => _CatalogStageScreenState();
}

class _CatalogStageScreenState extends ConsumerState<CatalogStageScreen> {
  late CatalogShot _shot = widget.entry.shot(widget.shot);
  late bool _chrome = widget.chrome;

  /// Bumped to replay the current state from the top.
  int _take = 0;

  void _show(CatalogShot s) => setState(() {
    _shot = s;
    _take++;
  });

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(catalogSettingsProvider);
    final grade = settings.grade;
    // A toggle change replays the shot, so its choreography runs under the new setting.
    final take =
        '${_shot.id}-$_take-${settings.reduceMotion}-${settings.largeText}-${grade.name}';
    return MediaQuery(
      data: settings.apply(MediaQuery.of(context)),
      child: ColoredBox(
        color: BrandColors.void_,
        child: Stack(
          fit: StackFit.expand,
          children: [
            KeyedSubtree(key: ValueKey(take), child: _shot.build(grade)),
            if (_chrome)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: CatalogPill(
                    children: [
                      CatalogControl(
                        label: '‹',
                        semantics: 'Back to the catalog',
                        onTap: () => context.pop(),
                      ),
                      if (widget.entry.shots.length > 1)
                        for (final s in widget.entry.shots)
                          CatalogControl(
                            label: s.label.toUpperCase(),
                            semantics: 'Show ${s.label}',
                            on: s.id == _shot.id,
                            grade: grade,
                            onTap: () => _show(s),
                          ),
                      CatalogControl(
                        label: 'REPLAY',
                        semantics: 'Replay this state',
                        onTap: () => _show(_shot),
                      ),
                      ...catalogToggles(ref),
                      CatalogControl(
                        label: 'HIDE',
                        semantics:
                            'Hide the controls (long-press to bring them back)',
                        onTap: () => setState(() => _chrome = false),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: () => setState(() => _chrome = true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
