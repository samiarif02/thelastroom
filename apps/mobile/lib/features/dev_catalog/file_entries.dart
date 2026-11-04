import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart' hide SkillBadge;
import '../../ui/daylight/daylight_radar.dart';
import '../progression/progression_card.dart' show HeroStat;
import '../progression/skill_badges.dart';
import 'catalog_entry.dart';
import 'daylight_backdrop.dart';

/// Your file's pieces in Daylight (brief 48): the radar (empty, one try, the report's first
/// try under the review), the hero's stat tiles, and the skill medal in every state.
abstract final class FileEntries {
  static final CatalogEntry file = CatalogEntry(
    id: 'file',
    name: 'Your file',
    note:
        'DaylightRadar (empty, latest, then vs now), HeroStat on the hero\'s floor, '
        'and the small SkillBadge medal (earned, not yet), brief 48.',
    shots: [
      CatalogShot(
        id: 'radar',
        label: 'Radar',
        build: (_) => CatalogPaper(
          children: [
            DaylightPanel(
              child: Center(
                child: DaylightRadar(
                  labels: _labels,
                  layers: [
                    RadarLayer(
                      values: const [72, 41, 89, 55],
                      fill: DaylightFloors.one.base,
                    ),
                  ],
                ),
              ),
            ),
            DaylightPanel(
              child: Center(
                child: DaylightRadar(
                  labels: _labels,
                  layers: [
                    const RadarLayer(
                      values: [48, 30, 61, 40],
                      outline: DaylightColors.ink3,
                    ),
                    RadarLayer(
                      values: const [81, 72, 88, 63],
                      fill: DaylightFloors.one.base,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      CatalogShot(
        id: 'pieces',
        label: 'Pieces',
        build: (_) => CatalogPaper(
          children: [
            DaylightPanel(
              child: Center(child: DaylightRadar.empty(labels: _labels)),
            ),
            DaylightPanel(
              color: DaylightFloors.one.base,
              edge: DaylightFloors.one.deep,
              // Laid out as ProgressionCard lays them: one height, the tallest's.
              child: const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: DaylightSpace.s8,
                  children: [
                    Expanded(
                      child: HeroStat(
                        label: 'Rooms lit',
                        value: '4',
                        after: 'of 21',
                      ),
                    ),
                    Expanded(
                      child: HeroStat(label: 'Average', value: '71'),
                    ),
                    Expanded(
                      child: HeroStat(
                        label: 'Best gain',
                        value: '+19',
                        after: 'on room 3',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, s) in SkillCopy.order.indexed)
                  SkillBadge(skill: s, earned: i < 2, size: DaylightSpace.s48),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  static final List<String> _labels = [
    for (final d in Dimension.values)
      '${d.name[0].toUpperCase()}${d.name.substring(1)}',
  ];
}
