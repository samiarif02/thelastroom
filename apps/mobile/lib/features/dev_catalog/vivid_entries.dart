import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_settings.dart';
import '../../ui/film_kit.dart';
import '../recall/recall_card_view.dart';
import '../recall/recall_controller.dart';
import '../recall/recall_deck.dart';
import '../settings/audio/audio_settings_section.dart';
import '../tower/tower_chapter_card.dart';
import '../tower/tower_extras.dart';
import '../tower/tower_hero.dart';
import '../tower/tower_rooms.dart';
import 'catalog_backdrops.dart';
import 'catalog_entry.dart';

/// The vivid layer (brief 17) in the catalog: the kit on the sky, and the tower's cards with
/// sample rooms (two done, one current, the rest locked).
abstract final class VividEntries {
  static final CatalogEntry kit = CatalogEntry(
    id: 'vivid',
    name: 'Vivid kit',
    note:
        'VividBackdrop, VividButton (.play, quiet, disabled), VividToggle, ProgressRing, '
        'InterviewerBadge, '
        'SkillRadar, LockGlyph: the home screens\' language (brief 17).',
    shots: [
      CatalogShot(
        id: 'buttons',
        label: 'Buttons',
        build: (_) => CatalogSky(
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
            const SizedBox(height: BrandSpace.md),
            VividToggle(label: 'Calm mode', value: true, onChanged: (_) {}),
            VividToggle(label: 'Sound', value: false, onChanged: (_) {}),
          ],
        ),
      ),
      CatalogShot(
        id: 'badges',
        label: 'Badges',
        build: (_) => CatalogSky(
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
        build: (_) => CatalogSky(
          children: [
            TowerHero(room: _rooms[2], onPlay: () {}),
            const SizedBox(height: BrandSpace.md),
            const RecallRoomCardView(due: 3),
          ],
        ),
      ),
      CatalogShot(
        id: 'chapter',
        label: 'Chapter',
        build: (_) => CatalogSky(
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
        build: (_) => CatalogSky(
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

  static final CatalogEntry themes = CatalogEntry(
    id: 'themes',
    name: 'Themes',
    note:
        'Every VividPalette side by side (brief 28): its sky, a Chapter 1 card with the accent, '
        'the three chapters. The THEME control in the pill re-colours the whole catalog.',
    shots: [
      CatalogShot(
        id: 'all',
        label: 'All',
        build: (_) => CatalogSky(
          children: [
            for (var i = 0; i < VividThemes.all.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSpace.md),
                child: Row(
                  children: [
                    for (final t in VividThemes.all.skip(i).take(2)) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ThemePreview(palette: t),
                            const SizedBox(height: BrandSpace.xs),
                            Text(t.name, style: BrandVividType.row),
                          ],
                        ),
                      ),
                      const SizedBox(width: BrandSpace.sm),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  static final CatalogEntry screens = CatalogEntry(
    id: 'vivid-screens',
    name: 'Settings and Recall',
    note:
        'The Settings audio section on a VividPanel, and a Recall Room card with the mission\'s '
        'answer cards, before and after an answer (brief 23).',
    shots: [
      CatalogShot(
        id: 'settings',
        label: 'Settings',
        build: (_) => ProviderScope(
          overrides: [audioSettingsProvider.overrideWith(_CatalogAudio.new)],
          child: const CatalogSky(
            children: [VividPanel(child: AudioSettingsSection())],
          ),
        ),
      ),
      for (final (id, label, chosen) in [
        ('recall', 'Recall', null),
        ('recall-answered', 'Answered', 'wrong'),
      ])
        CatalogShot(
          id: id,
          label: label,
          build: (_) => CatalogSky(
            children: [
              RecallCardView(
                playing: RecallPlaying(
                  round: const [_recallCard],
                  index: 0,
                  verdicts: chosen == null
                      ? const []
                      : const [RecallVerdict.missed],
                  chosenId: chosen,
                ),
                onAnswer: (_) {},
                onNext: () {},
              ),
            ],
          ),
        ),
    ],
  );

  static const RecallQuestion _recallCard = RecallQuestion(
    cardId: 'catalog-trap',
    kind: RecallCardKind.trap,
    kicker: 'YOU FELL FOR',
    prompt: 'Saying "we" sounds like a team player.',
    ask: 'What holds up better?',
    quote: 'We shipped it in two weeks.',
    choices: [
      RecallChoice(
        id: 'right',
        text: 'Say what you did, then credit the team.',
      ),
      RecallChoice(id: 'wrong', text: 'Keep it humble: the team did it.'),
      RecallChoice(id: 'other', text: 'Skip the detail, give the result.'),
    ],
    correctChoiceId: 'right',
    takeaway: 'They hire you, not the team: own your part.',
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

/// The audio settings without the saved ones (the catalog has no device store).
class _CatalogAudio extends AudioSettingsController {
  @override
  AudioSettings build() => const AudioSettings();
}
