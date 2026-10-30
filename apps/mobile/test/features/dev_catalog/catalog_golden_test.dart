import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_last_room/features/dev_catalog/catalog_entries.dart';

import '../../ui/harness.dart';

/// One golden per catalog state: every film-kit component's key states, settled, at a phone's
/// 375×667, the harness's default (`flutter test --update-goldens test/features/dev_catalog` to redraw them, then look
/// at every changed image before committing). The grain is seeded and the ambient clock is the
/// test's fake time, so a frame is the same on every run.
void main() {
  const stageKey = ValueKey('catalog-stage');

  for (final entry in CatalogEntries.all) {
    for (final shot in entry.shots) {
      testWidgets('${entry.id}/${shot.id}', (tester) async {
        tester.view.devicePixelRatio = 1;
        await pumpKit(
          tester,
          RepaintBoundary(
            key: stageKey,
            child: ColoredBox(
              color: BrandColors.void_,
              child: shot.build(ChapterGrade.lobby),
            ),
          ),
        );
        await pumpThrough(tester, shot.settle);
        await expectLater(
          find.byKey(stageKey),
          matchesGoldenFile('goldens/${entry.id}-${shot.id}.png'),
        );
      });
    }
  }
}
