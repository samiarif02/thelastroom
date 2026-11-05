import 'package:brand/brand.dart';
import 'package:engine/engine.dart' show reasonCloseXp, reasonSoundXp;
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'catalog_entry.dart';
import 'daylight_backdrop.dart';

/// The Daylight kit in the catalog (`/dev/catalog/daylight-*`), every component in every state,
/// with the mockups' real copy.
abstract final class DaylightEntries {
  static final List<CatalogEntry> all = [
    type,
    actions,
    picks,
    room,
    scores,
    tower,
  ];

  static final CatalogEntry type = CatalogEntry(
    id: 'daylight-type',
    name: 'Daylight type and colour',
    note:
        'DaylightType (Bricolage Grotesque for display, Geist for reading; every size a '
        'Tailwind step) and DaylightColors, each floor with its five colours.',
    shots: [
      CatalogShot(
        id: 'styles',
        label: 'Styles',
        build: (_) => const _TypeSheet(),
      ),
      CatalogShot(
        id: 'colours',
        label: 'Colours',
        build: (_) => const _Colours(),
      ),
    ],
  );

  static final CatalogEntry actions = CatalogEntry(
    id: 'daylight-actions',
    name: 'Buttons, tiles, tags',
    note:
        'TactileButton (honey, recall, compact, pressed, disabled), IconTile (raised, quiet, '
        'pressed, disabled), Tag in every tone.',
    shots: [
      CatalogShot(
        id: 'buttons',
        label: 'Buttons',
        build: (_) => const _Buttons(),
      ),
      CatalogShot(id: 'tags', label: 'Tags', build: (_) => const _Tags()),
    ],
  );

  static final CatalogEntry picks = CatalogEntry(
    id: 'daylight-picks',
    name: 'Picks and progress',
    note:
        'BeatProgress, TrustPips, PickCard (idle, pressed, selected, dimmed, locked, with a '
        'letter or a principle\'s icon), the answer-so-far strip.',
    shots: [
      CatalogShot(
        id: 'answers',
        label: 'Answers',
        build: (_) => const _Answers(),
      ),
      CatalogShot(
        id: 'reasons',
        label: 'Reasons',
        build: (_) => const _Reasons(),
      ),
    ],
  );

  static final CatalogEntry room = CatalogEntry(
    id: 'daylight-room',
    name: 'Room, bubble, sheet',
    note:
        'RoomStage (168, and the 96 strip at large text), SpeechBubble (tail up, tail left, '
        'flat), FeedbackSheet (sound +10 XP, close +5 XP, each counted up).',
    shots: [
      CatalogShot(id: 'stage', label: 'Stage', build: (_) => const _Stage()),
      CatalogShot(
        id: 'sheet-sound',
        label: 'Sound pick',
        build: (_) => const _Sheet(tone: FeedbackTone.sound),
        settle: _xpCounted,
      ),
      CatalogShot(
        id: 'sheet-close',
        label: 'Close pick',
        build: (_) => const _Sheet(tone: FeedbackTone.close),
        settle: _xpCounted,
      ),
    ],
  );

  static final CatalogEntry scores = CatalogEntry(
    id: 'daylight-scores',
    name: 'Scores and rings',
    note:
        'ScoreDial (counts up), DimensionRow (the weakest in clay), ProgressTrack, WeeklyRing '
        '(empty, part, closed).',
    shots: [
      CatalogShot(
        id: 'debrief',
        label: 'Debrief',
        settle: DaylightMotion.countUp + DaylightMotion.move,
        build: (_) => const _Debrief(),
      ),
      CatalogShot(id: 'rings', label: 'Rings', build: (_) => const _Rings()),
    ],
  );

  static final CatalogEntry tower = CatalogEntry(
    id: 'daylight-tower',
    name: 'Windows, skills, tabs',
    note:
        'ArchWindow (lit, current, unlit, dark), SkillBadge (earned, next, locked), '
        'SkillMedal, FloatingTabBar.',
    shots: [
      CatalogShot(id: 'skills', label: 'Skills', build: (_) => const _Skills()),
      CatalogShot(id: 'medal', label: 'Medal', build: (_) => const _Medal()),
    ],
  );
}

class _TypeSheet extends StatelessWidget {
  const _TypeSheet();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    gap: DaylightSpace.s4,
    children: [
      for (final MapEntry(key: name, value: style) in DaylightType.all.entries)
        Text(
          name.startsWith('Heading') ? name : '$name · Pick your evidence',
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      const SizedBox(height: DaylightSpace.s8),
      Text(
        '78 · 1,247 XP · 0:47',
        style: DaylightType.tabular(DaylightType.heading4),
      ),
    ],
  );
}

class _Colours extends StatelessWidget {
  const _Colours();

  static const double _swatch = 40;

  Widget _row(String name, List<Color> colours) => Row(
    children: [
      SizedBox(width: 72, child: Text(name, style: DaylightType.caption4)),
      for (final c in colours) ...[
        Container(
          width: _swatch,
          height: _swatch,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(DaylightRadius.inner),
            border: Border.all(color: DaylightColors.sand2),
          ),
        ),
        const SizedBox(width: DaylightSpace.s4),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => CatalogPaper(
    gap: DaylightSpace.s8,
    children: [
      _row('Ground', const [
        DaylightColors.paper,
        DaylightColors.sand,
        DaylightColors.sand2,
        DaylightColors.raised,
        DaylightColors.ink,
        DaylightColors.ink2,
      ]),
      for (final (i, f) in DaylightFloors.all.indexed)
        _row('Floor ${i + 1}', [f.base, f.deep, f.tint, f.soft, f.on]),
      _row('Honey', const [
        DaylightColors.honey,
        DaylightColors.honeyEdge,
        DaylightColors.onHoney,
        DaylightColors.honeyTint,
        DaylightColors.honeyInk,
      ]),
      _row('Recall', const [
        DaylightColors.recall,
        DaylightColors.recallDeep,
        DaylightColors.recallTint,
        DaylightColors.recallSoft,
      ]),
      _row('Trap', const [DaylightColors.trap, DaylightColors.trapTint]),
      _row('Sky', const [
        DaylightColors.sky,
        DaylightColors.skyCloud,
        DaylightColors.cityFar,
        DaylightColors.dusk,
      ]),
    ],
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    gap: DaylightSpace.s12,
    children: [
      TactileButton(
        label: 'Start room 4',
        icon: PhosphorFill.play,
        onPressed: () {},
      ),
      TactileButton(
        label: 'Lock in line B',
        icon: PhosphorBold.lockSimple,
        onPressed: () {},
        pressed: true,
      ),
      const TactileButton(
        label: 'Lock in line B',
        icon: PhosphorBold.lockSimple,
        onPressed: null,
      ),
      TactileButton(
        label: 'Open the Recall Room',
        icon: PhosphorBold.cards,
        tone: TactileTone.recall,
        compact: true,
        onPressed: () {},
      ),
      const CatalogLabel('Icon tiles: raised, pressed, quiet, disabled'),
      Row(
        children: [
          IconTile(
            icon: PhosphorBold.x,
            semanticLabel: 'Leave the room',
            onPressed: () {},
          ),
          const SizedBox(width: DaylightSpace.s8),
          IconTile(
            icon: PhosphorBold.x,
            semanticLabel: 'Leave the room',
            onPressed: () {},
            pressed: true,
          ),
          const SizedBox(width: DaylightSpace.s8),
          IconTile.quiet(
            icon: PhosphorBold.x,
            semanticLabel: 'Dismiss',
            onPressed: () {},
          ),
          const SizedBox(width: DaylightSpace.s8),
          const IconTile(
            icon: PhosphorBold.arrowRight,
            semanticLabel: 'Next',
            onPressed: null,
          ),
        ],
      ),
      const CatalogLabel('Compact, as wide as its label'),
      Align(
        alignment: Alignment.centerLeft,
        child: TactileButton(
          label: 'Take the lift',
          icon: PhosphorBold.elevator,
          expand: false,
          compact: true,
          onPressed: () {},
        ),
      ),
    ],
  );
}

class _Tags extends StatelessWidget {
  const _Tags();

  @override
  Widget build(BuildContext context) {
    const f = DaylightFloors.one;
    return CatalogPaper(
      gap: DaylightSpace.s12,
      children: [
        const Wrap(
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s8,
          children: [
            Tag(
              label: '1,247 XP',
              icon: PhosphorFill.lightning,
              tone: TagTone.honey,
            ),
            Tag(label: 'Interview in 9 days', icon: PhosphorBold.calendarBlank),
            Tag(
              label: '+40 XP',
              icon: PhosphorFill.lightning,
              tone: TagTone.honeySolid,
            ),
            Tag(label: 'Due today', tone: TagTone.recall),
            Tag(
              label: 'The line that cost the most',
              icon: PhosphorBold.pushPin,
              tone: TagTone.trap,
            ),
            Tag(
              label: 'Recording',
              dot: DaylightColors.trap,
              tone: TagTone.raised,
            ),
          ],
        ),
        Wrap(
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s8,
          children: [
            Tag(
              label: '+14 since room 1',
              icon: PhosphorBold.trendUp,
              tone: TagTone.floor(f),
            ),
            Tag(
              label: 'Listening',
              icon: PhosphorBold.ear,
              tone: TagTone.floor(DaylightFloors.two),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(DaylightSpace.s16),
          decoration: BoxDecoration(
            color: f.base,
            borderRadius: BorderRadius.circular(DaylightRadius.panel),
          ),
          child: Wrap(
            spacing: DaylightSpace.s8,
            children: [
              Tag(
                label: '5 min',
                icon: PhosphorBold.timer,
                tone: TagTone.onFloor(f),
              ),
              Tag(
                label: '3 beats',
                icon: PhosphorBold.copySimple,
                tone: TagTone.onFloor(f),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Answers extends StatelessWidget {
  const _Answers();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    ground: DaylightFloors.one.tint,
    gap: DaylightSpace.s8,
    children: [
      const Row(
        children: [
          Expanded(
            child: BeatProgress(
              beats: ['Open', 'Evidence', 'Land'],
              current: 1,
              progress: 0.45,
            ),
          ),
          SizedBox(width: DaylightSpace.s12),
          TrustPips(trust: 3, icon: PhosphorFill.handshake),
        ],
      ),
      PickCard(
        letter: 'A',
        text: 'We went through a month of tickets and cut resets by a quarter.',
        onTap: () {},
      ),
      PickCard(
        letter: 'B',
        text: 'I tagged 600 tickets from one month. One in three were password resets.',
        state: PickState.selected,
        onTap: () {},
      ),
      PickCard(
        letter: 'C',
        text: 'I looked through lots of tickets and suggested fixes.',
        state: PickState.dimmed,
        onTap: () {},
      ),
      PickCard(
        letter: 'A',
        text: 'Pressed: it sinks onto its edge.',
        pressed: true,
        onTap: () {},
      ),
      const PickCard(
        letter: 'B',
        lockedIcon: PhosphorBold.check,
        text: 'Locked in: a check, no longer tappable.',
        state: PickState.locked,
      ),
    ],
  );
}

class _Reasons extends StatelessWidget {
  const _Reasons();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    ground: DaylightFloors.one.tint,
    gap: DaylightSpace.s8,
    children: [
      const _SoFar(),
      Text('What makes it work?', style: DaylightType.heading6),
      PickCard(
        icon: PhosphorBold.hash,
        text: 'He asked about data, so give the actual numbers and what I did with them.',
        state: PickState.selected,
        onTap: () {},
      ),
      PickCard(
        icon: PhosphorBold.usersThree,
        text: 'Sharing credit with the team is the safest way to sound modest.',
        onTap: () {},
      ),
      const ChapterTint(
        floor: DaylightFloors.two,
        child: Row(
          children: [
            Expanded(
              child: BeatProgress(
                beats: ['Open', 'Evidence', 'Land'],
                current: 3,
              ),
            ),
            SizedBox(width: DaylightSpace.s12),
            TrustPips(trust: 5, icon: PhosphorFill.handshake),
          ],
        ),
      ),
      const ChapterTint(
        floor: DaylightFloors.three,
        child: Row(
          children: [
            Expanded(
              child: BeatProgress(
                beats: ['Open', 'Evidence', 'Land'],
                current: 0,
                progress: 0.2,
              ),
            ),
            SizedBox(width: DaylightSpace.s12),
            TrustPips(trust: 1, icon: PhosphorFill.handshake),
          ],
        ),
      ),
    ],
  );
}

/// The answer-so-far strip: what the player said in the beat before.
class _SoFar extends StatelessWidget {
  const _SoFar();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DaylightSpace.s12,
      vertical: DaylightSpace.s8,
    ),
    decoration: BoxDecoration(
      color: DaylightColors.raised.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(DaylightRadius.tile),
    ),
    child: Row(
      children: [
        Icon(
          PhosphorFill.checkCircle,
          size: 20,
          color: DaylightFloors.one.base,
        ),
        const SizedBox(width: DaylightSpace.s8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Your line  ', style: DaylightType.body4),
                const TextSpan(text: '“I tagged 600 tickets from one month.”'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
        ),
      ],
    ),
  );
}

class _Stage extends StatelessWidget {
  const _Stage();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    ground: DaylightFloors.one.tint,
    gap: DaylightSpace.s12,
    children: [
      Column(
        children: [
          const RoomStage(
            person: CastPeople.marcus,
            semanticLabel: 'Marcus listens',
          ),
          Transform.translate(
            offset: const Offset(0, -DaylightSpace.s32),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: DaylightSpace.s8),
              child: SpeechBubble(
                speaker: 'Marcus · hiring manager',
                line: 'Now the data. What did you actually do?',
              ),
            ),
          ),
        ],
      ),
      const ChapterTint(
        floor: DaylightFloors.two,
        child: RoomStage(
          person: CastPeople.lena,
          expression: CastExpression.talk,
          height: RoomStage.compactHeight,
          overlays: [
            Positioned(
              left: DaylightSpace.s12,
              top: DaylightSpace.s12,
              child: Tag(
                label: 'Recording',
                dot: DaylightColors.trap,
                tone: TagTone.raised,
              ),
            ),
          ],
        ),
      ),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ArchPortrait(
            person: CastPeople.priya,
            expression: CastExpression.smile,
            width: 88,
            height: 104,
            ground: DaylightColors.recallSoft,
          ),
          SizedBox(width: DaylightSpace.s16),
          Expanded(
            child: SpeechBubble(
              speaker: 'Priya',
              line: 'Welcome back, Sami. Marcus caught you on this one.',
              tail: BubbleTail.left,
              flat: true,
              floor: FloorColours(
                base: DaylightColors.recall,
                deep: DaylightColors.recall,
                tint: DaylightColors.recallTint,
                soft: DaylightColors.recallSoft,
                on: DaylightColors.raised,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// The feedback sheet's XP has counted up (and its sheet risen) before the golden is taken.
final Duration _xpCounted = DaylightMotion.countUp + DaylightMotion.move;

class _Sheet extends StatelessWidget {
  const _Sheet({required this.tone});

  final FeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final sound = tone == FeedbackTone.sound;
    return CatalogPaper(
      ground: DaylightFloors.one.tint,
      bottom: FeedbackSheet(
        person: CastPeople.marcus,
        tone: tone,
        title: sound ? "That's the principle." : 'Close, but not quite.',
        note: sound
            ? 'Marcus nods. Trust goes up one.'
            : 'Modesty tempts, but he asked what you did.',
        // The reason's XP (brief 55): sound +10, close +5.
        xp: sound ? reasonSoundXp : reasonCloseXp,
        lesson: sound
            ? 'An actual number and your own action prove more than a summary of what '
                  'the team found.'
            : 'Say what you did first. Credit the team after.',
        lessonIcon: PhosphorFill.lightbulbFilament,
        actionLabel: 'Next: land the answer',
        actionIcon: PhosphorBold.arrowRight,
        onAction: () {},
      ),
      children: [
        Text('What makes it work?', style: DaylightType.heading6),
        Text(
          'Pick the principle. It is the part you keep.',
          style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
        ),
      ],
    );
  }
}

class _Debrief extends StatelessWidget {
  const _Debrief();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    children: [
      Container(
        padding: const EdgeInsets.all(DaylightSpace.s16),
        decoration: BoxDecoration(
          color: DaylightColors.raised,
          borderRadius: BorderRadius.circular(DaylightRadius.panel),
          boxShadow: DaylightElevation.edge,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const ScoreDial(score: 78),
                const SizedBox(width: DaylightSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A strong answer', style: DaylightType.heading6),
                      const SizedBox(height: DaylightSpace.s8),
                      Wrap(
                        spacing: DaylightSpace.s8,
                        runSpacing: DaylightSpace.s8,
                        children: [
                          Tag(
                            label: '+14 since room 1',
                            icon: PhosphorBold.trendUp,
                            tone: TagTone.floor(DaylightFloors.one),
                          ),
                          const Tag(
                            label: '+40 XP',
                            icon: PhosphorFill.lightning,
                            tone: TagTone.honeySolid,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DaylightSpace.s16),
            for (final (i, (name, score, basis)) in const [
              (
                'Relevance',
                84,
                'You answered what he asked: your part, with data.',
              ),
              (
                'Specificity',
                81,
                'A count (600), a share (one in three) and your own action.',
              ),
              (
                'Structure',
                76,
                'Open, evidence, land in order. The close ran a little long.',
              ),
              (
                'Adaptability',
                63,
                'Your reply to his follow up said “we” twice.',
              ),
            ].indexed) ...[
              if (i > 0) const SizedBox(height: DaylightSpace.s12),
              DimensionRow(
                name: name,
                score: score,
                basis: basis,
                weakest: i == 3,
                delay: Duration(milliseconds: 80 * i),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _Rings extends StatelessWidget {
  const _Rings();

  @override
  Widget build(BuildContext context) => const CatalogPaper(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          WeeklyRing(done: 0, caption: 'this week'),
          WeeklyRing(done: 2, caption: 'this week'),
          WeeklyRing(done: 3, caption: 'closed'),
        ],
      ),
      ChapterTint(
        floor: DaylightFloors.two,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ScoreDial(score: 41, size: 96, animate: false),
            ScoreDial(score: 92, size: 96, animate: false),
          ],
        ),
      ),
      CatalogLabel('Progress track'),
      ProgressTrack(value: 0.3, animate: false),
      ProgressTrack(value: 0.7, fill: DaylightColors.recall, animate: false),
      ProgressTrack(value: 1, fill: DaylightColors.honey, animate: false),
    ],
  );
}

class _Skills extends StatelessWidget {
  const _Skills();

  @override
  Widget build(BuildContext context) => CatalogPaper(
    bottom: Padding(
      padding: const EdgeInsets.fromLTRB(
        DaylightSpace.s16,
        0,
        DaylightSpace.s16,
        DaylightSpace.s24,
      ),
      child: FloatingTabBar(
        current: 0,
        onSelect: (_) {},
        items: const [
          TabItem(icon: PhosphorBold.buildings, label: 'Tower'),
          TabItem(icon: PhosphorBold.cards, label: 'Recall', badge: 2),
          TabItem(icon: PhosphorBold.medal, label: 'Skills'),
          TabItem(icon: PhosphorBold.trophy, label: 'Leaderboard'),
          TabItem(icon: PhosphorBold.userCircle, label: 'You'),
        ],
      ),
    ),
    children: [
      const CatalogLabel('Tower windows: lit, current, unlit, dark'),
      Container(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        color: DaylightFloors.one.base,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ArchWindow(state: ArchWindowState.lit, check: PhosphorBold.check),
            ArchWindow(state: ArchWindowState.lit, check: PhosphorBold.check),
            ArchWindow(
              state: ArchWindowState.current,
              person: CastPeople.marcus,
            ),
            ArchWindow(state: ArchWindowState.unlit),
            ArchWindow(state: ArchWindowState.dark),
          ],
        ),
      ),
      const CatalogLabel('Skills: earned, next, locked'),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkillBadge(
            icon: PhosphorFill.chartBar,
            name: 'Evidence builder',
            hint: 'Earned',
            state: SkillState.earned,
          ),
          SkillBadge(
            icon: PhosphorFill.hand,
            name: 'Clear intros',
            hint: 'Room 7',
            state: SkillState.next,
          ),
          SkillBadge(
            icon: PhosphorFill.handshake,
            name: 'Conflict navigator',
            hint: 'Floor 2',
          ),
        ],
      ),
    ],
  );
}

class _Medal extends StatelessWidget {
  const _Medal();

  @override
  Widget build(BuildContext context) {
    const f = DaylightFloors.one;
    return CatalogPaper(
      ground: f.base,
      children: [
        Text(
          'Floor 1 cleared · 7 of 7 rooms lit',
          style: DaylightType.caption3.copyWith(color: f.on),
        ),
        Text(
          'You got through the door.',
          style: DaylightType.heading3.copyWith(color: DaylightColors.raised),
        ),
        const Center(
          child: SkillMedal(
            icon: PhosphorFill.chartBar,
            name: 'Evidence builder',
          ),
        ),
        Text(
          'Earned in room 7, with no hints.',
          textAlign: TextAlign.center,
          style: DaylightType.body5.copyWith(color: f.on),
        ),
      ],
    );
  }
}
