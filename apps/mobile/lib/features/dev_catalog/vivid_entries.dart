import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';
import '../tower/tower_chapter_card.dart';
import '../tower/tower_extras.dart';
import '../tower/tower_hero.dart';
import '../tower/tower_rooms.dart';
import 'catalog_entry.dart';

/// The vivid layer (brief 17) in the catalog: the kit on the sky, and the tower's cards with
/// sample rooms (two done, one current, the rest locked).
abstract final class VividEntries {
  static final CatalogEntry kit = CatalogEntry(
    id: 'vivid',
    name: 'Vivid kit',
    note:
        'VividBackdrop, VividButton (.play, quiet, disabled), ProgressRing, InterviewerBadge, '
        'SkillRadar, LockGlyph: the home screens\' language (brief 17).',
    shots: [
      CatalogShot(
        id: 'buttons',
        label: 'Buttons',
        build: (_) => _OnSky(
          children: [
            VividButton.play(expand: true, onPressed: () {}),
            const SizedBox(height: BrandSpace.md),
            VividButton(label: 'Next', expand: true, onPressed: () {}),
            const SizedBox(height: BrandSpace.md),
            Center(
              child: VividButton(
                label: 'Your file',
                primary: false,
                onPressed: () {},
              ),
            ),
            const SizedBox(height: BrandSpace.md),
            const VividButton(label: 'Let’s go', expand: true, onPressed: null),
          ],
        ),
      ),
      CatalogShot(
        id: 'badges',
        label: 'Badges',
        build: (_) => _OnSky(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, id) in ChapterCard.hostIds.indexed)
                  InterviewerBadge(
                    figure: FriendlyFigure.of(id),
                    ring: ChapterGrade.values[i].glow,
                    grade: ChapterGrade.values[i],
                    size: 84,
                  ),
              ],
            ),
            const SizedBox(height: BrandSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, g) in ChapterGrade.values.indexed)
                  ProgressRing(
                    value: (i + 1) / 4,
                    color: g.glow,
                    size: 72,
                    child: Text('${i + 1}', style: BrandVividType.title),
                  ),
              ],
            ),
            const SizedBox(height: BrandSpace.lg),
            Center(
              child: SkillRadar(
                values: const [72, 48, 64, 55],
                labels: const [
                  'Relevance',
                  'Specificity',
                  'Structure',
                  'Adaptability',
                ],
                color: ChapterGrade.lobby.glow,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  static final CatalogEntry tower = CatalogEntry(
    id: 'tower-cards',
    name: 'Tower cards',
    note:
        'TowerHero (one Play), ChapterCard with MissionRow (done with stars, current, locked), '
        'a locked chapter\'s teaser, LastRoomCard and RecallRoomCard.',
    shots: [
      CatalogShot(
        id: 'hero',
        label: 'Hero',
        build: (_) => _OnSky(
          children: [
            TowerHero(room: _rooms[2], onPlay: () {}),
            const SizedBox(height: BrandSpace.md),
            const RecallRoomCard(),
          ],
        ),
      ),
      CatalogShot(
        id: 'chapter',
        label: 'Chapter',
        build: (_) => _OnSky(
          children: [
            ChapterCard(
              chapter: chapters.first,
              rooms: _rooms.take(4).toList(),
              onTapRoom: (_) {},
            ),
          ],
        ),
      ),
      CatalogShot(
        id: 'locked',
        label: 'Locked',
        build: (_) => _OnSky(
          children: [
            ChapterCard(
              chapter: chapters[1],
              rooms: const [],
              onTapRoom: (_) {},
            ),
            const SizedBox(height: BrandSpace.md),
            const LastRoomCard(),
          ],
        ),
      ),
    ],
  );

  /// Missions 1–2 done (a strong and a middling run), 3 current, the rest locked.
  static final List<TowerRoom> _rooms = [
    for (final (i, m) in missions.indexed)
      TowerRoom(
        mission: m,
        state: i < 2
            ? RoomState.done
            : i == 2
            ? RoomState.current
            : RoomState.locked,
        best: switch (i) {
          0 => 86,
          1 => 64,
          _ => null,
        },
      ),
  ];
}

/// Components on the evening sky, centred, scrolling only at 2x.
class _OnSky extends StatelessWidget {
  const _OnSky({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const VividBackdrop(lights: false),
      SafeArea(
        child: AnchoredScroll(
          alignment: MainAxisAlignment.center,
          padding: const EdgeInsets.fromLTRB(
            BrandSpace.md,
            BrandSpace.xxl,
            BrandSpace.md,
            BrandSpace.lg,
          ),
          children: children,
        ),
      ),
    ],
  );
}
