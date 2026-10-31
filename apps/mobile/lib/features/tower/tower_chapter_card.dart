import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/film_kit.dart';
import 'tower_hero.dart';
import 'tower_rooms.dart';

/// One chapter of the tower (brief 17) as a card in its own strong colour: the big number, the
/// title, a ring of missions done, the interviewer who runs it. A playable chapter lists its
/// rooms 1, 2, 3 … top to bottom; a locked one teases its mission titles and what opens it.
class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.rooms,
    required this.onTapRoom,
    this.lit,
    this.lighting = 1,
    this.litRowKey,
  });

  final Chapter chapter;

  /// This chapter's rooms, in order; empty while it's locked.
  final List<TowerRoom> rooms;
  final ValueChanged<TowerRoom> onTapRoom;

  /// The mission just finished, and how far its row has lit (0 → 1).
  final int? lit;
  final double lighting;

  /// Put on the row that matters, so the tower can scroll it into view.
  final Key? litRowKey;

  static const String locked = 'Locked';
  static String opensAfter(int chapter) => 'Opens after Chapter $chapter';

  /// Which interviewer runs each chapter (the cast's order in onboarding).
  static const List<String> hostIds = ['priya', 'marcus', 'lena'];

  static const double _badge = 56;
  static const double _ring = 60;
  static const int _teaserTitles = 3;

  ChapterGrade get _grade => ChapterGrade.values[chapter.number - 1];

  @override
  Widget build(BuildContext context) {
    final grade = _grade;
    final total = chapter.missionTitles.length;
    final done = rooms.where((r) => r.state == RoomState.done).length;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BrandRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grade.cardGradient,
        ),
        border: Border.all(color: BrandVivid.hairline()),
        boxShadow: BrandVivid.cardShadow,
      ),
      padding: const EdgeInsets.all(BrandSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProgressRing(
                value: total == 0 ? 0 : done / total,
                color: grade.glow,
                size: _ring,
                child: Text(
                  '${chapter.number}',
                  style: BrandVividType.title.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: BrandSpace.md),
              Expanded(
                child: Semantics(
                  header: true,
                  label:
                      'Chapter ${chapter.number}, ${chapter.title}. $done of $total done.',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHAPTER ${chapter.number} · $done/$total',
                        style: BrandVividType.kicker,
                      ),
                      const SizedBox(height: 2),
                      Text(chapter.title, style: BrandVividType.title),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: BrandSpace.sm),
              InterviewerBadge(
                figure: FriendlyFigure.of(hostIds[chapter.number - 1]),
                ring: grade.glow,
                grade: grade,
                size: _badge,
              ),
            ],
          ),
          const SizedBox(height: BrandSpace.md),
          if (chapter.playable)
            for (final room in rooms)
              Padding(
                key: room.mission.number == lit ? litRowKey : null,
                padding: const EdgeInsets.only(top: BrandSpace.sm),
                child: MissionRow(
                  room: room,
                  grade: grade,
                  lighting: room.mission.number == lit ? lighting : 1,
                  onTap: () => onTapRoom(room),
                ),
              )
          else
            _LockedTeaser(chapter: chapter, grade: grade),
        ],
      ),
    );
  }
}

/// A locked chapter's tease: a lock pill and the first few mission titles as chips.
class _LockedTeaser extends StatelessWidget {
  const _LockedTeaser({required this.chapter, required this.grade});

  final Chapter chapter;
  final ChapterGrade grade;

  @override
  Widget build(BuildContext context) {
    final titles = chapter.missionTitles;
    final more = titles.length - ChapterCard._teaserTitles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pill(
          icon: const LockGlyph(color: BrandVivid.onDeep, size: 14),
          text: ChapterCard.opensAfter(chapter.number - 1),
          color: grade.deeper,
        ),
        const SizedBox(height: BrandSpace.sm),
        Wrap(
          spacing: BrandSpace.xs,
          runSpacing: BrandSpace.xs,
          children: [
            for (final t in titles.take(ChapterCard._teaserTitles))
              _Pill(text: t, color: BrandVivid.night.withValues(alpha: 0.35)),
            if (more > 0)
              _Pill(
                text: '+$more more',
                color: BrandVivid.night.withValues(alpha: 0.35),
              ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(BrandRadius.pill),
      border: Border.all(color: BrandVivid.hairline()),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.md - 4,
        vertical: BrandSpace.xs + 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final i?) ...[i, const SizedBox(width: BrandSpace.xs)],
          Flexible(
            child: Text(
              text,
              style: BrandVividType.body.copyWith(
                color: BrandVivid.onDeep,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One room in a chapter's list: its number (or a tick, or a lock), its title and what it
/// offers: stars and the best score once done, "Play" while current, what opens it while
/// locked. [lighting] runs 0 → 1 as a just-finished room lights up.
class MissionRow extends StatelessWidget {
  const MissionRow({
    super.key,
    required this.room,
    required this.grade,
    required this.onTap,
    this.lighting = 1,
  });

  final TowerRoom room;
  final ChapterGrade grade;
  final VoidCallback onTap;
  final double lighting;

  static const String play = 'Play';
  static String lockedLine(int before) => 'Finish Mission $before to open';

  static const double _disc = 40;
  static const double _lockedOpacity = 0.72;
  static const double _shade = 0.28;
  static const double _currentShade = 0.42;
  static const double _litGlow = 0.6;

  /// What a screen reader hears for the row.
  String get semantics {
    final m = room.mission;
    return switch (room.state) {
      RoomState.done =>
        'Mission ${m.number}, ${m.title}. Done, best score ${room.best}. Tap to play again.',
      RoomState.current => 'Mission ${m.number}, ${m.title}. Play.',
      RoomState.locked => 'Mission ${m.number}, ${m.title}. Locked.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final m = room.mission;
    final state = room.state;
    final current = state == RoomState.current;
    final lockedRow = state == RoomState.locked;
    final row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.sm + 4,
        vertical: BrandSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: BrandVivid.night.withValues(
          alpha: current ? _currentShade : _shade,
        ),
        borderRadius: BorderRadius.circular(BrandRadius.lg),
        border: Border.all(
          color: current ? BrandVivid.accent : BrandVivid.hairline(0.12),
          width: current ? 2 : 1,
        ),
        boxShadow: state == RoomState.done && lighting < 1
            ? [
                BoxShadow(
                  color: BrandVivid.accent.withValues(
                    alpha: _litGlow * (1 - lighting),
                  ),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _Disc(room: room, grade: grade, size: _disc),
          const SizedBox(width: BrandSpace.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: BrandVividType.row),
                if (lockedRow)
                  Text(
                    lockedLine(m.number - 1),
                    style: BrandVividType.body.copyWith(
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: BrandSpace.sm),
          switch (state) {
            RoomState.done => StarRow(
              stars: room.stars,
              best: room.best ?? 0,
              size: 14,
            ),
            RoomState.current => const _PlayChip(),
            RoomState.locked => const LockGlyph(
              color: BrandVivid.onDeepSoft,
              size: 18,
            ),
          },
        ],
      ),
    );
    return Pressable(
      label: semantics,
      onTap: onTap,
      child: Opacity(opacity: lockedRow ? _lockedOpacity : 1, child: row),
    );
  }
}

/// The number in a disc: lit in the chapter's glow once done (with a tick), the accent while
/// current, slate while locked.
class _Disc extends StatelessWidget {
  const _Disc({required this.room, required this.grade, required this.size});

  final TowerRoom room;
  final ChapterGrade grade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = switch (room.state) {
      RoomState.done => (grade.glow, grade.deeper),
      RoomState.current => (BrandVivid.accent, BrandVivid.onAccent),
      RoomState.locked => (BrandVivid.locked, BrandVivid.onDeepSoft),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: BrandVivid.hairline(0.3)),
      ),
      child: Text(
        '${room.mission.number}',
        style: BrandVividType.row.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlayChip extends StatelessWidget {
  const _PlayChip();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: BrandVivid.accent,
      borderRadius: BorderRadius.circular(BrandRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrandSpace.md,
        vertical: BrandSpace.xs + 2,
      ),
      child: Text(
        MissionRow.play.toUpperCase(),
        style: BrandVividType.kicker.copyWith(
          color: BrandVivid.onAccent,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
