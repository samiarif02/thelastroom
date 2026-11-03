import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import '../progression/skill_badges.dart';
import '../tower/tower_door.dart';
import '../tower/tower_header.dart';
import 'floor_card_facts.dart';

/// The floor card ("Share your floor card", direction.md §6): a 4:5 picture of a cleared floor,
/// in Daylight Tower's reward look, made to be posted. The floor's colour with soft white rays;
/// the kicker and the floor's name; Northstar tower with this floor's doors lit; the skill
/// medals earned on it; then vs now and the total XP; the floor's three interviewers in
/// honey-lit arches, smiling; a small footer with the game's name and address.
///
/// It's laid out at [size] (logical) and drawn at [pixelRatio], which makes a 1080 × 1350 PNG.
/// It never animates: it's a still.
class FloorCard extends StatelessWidget {
  const FloorCard({super.key, required this.facts});

  final FloorCardFacts facts;

  /// The card's layout size; × [pixelRatio] it is 1080 × 1350 pixels.
  static const Size size = Size(432, 540);
  static const double pixelRatio = 2.5;

  static const String address = 'thelastroom-ten.vercel.app';
  static const String game = 'The Last Room';

  static String kicker(int floor, int rooms) =>
      'Floor $floor cleared · $rooms of $rooms rooms lit';
  static String clearedBy(String name) => 'Cleared by $name';
  static const String thenNow = 'Then → now';
  static String rooms(int first, int last) => 'Room $first to room $last';
  static const String totalXp = 'Total XP';
  static const String noHints = 'Earned with no hints';
  static const String roomsLit = 'rooms lit';
  static const String metHere = 'Your interviewers';
  static String delta(int then, int now) =>
      now >= then ? '+${now - then}' : '${now - then}';

  /// The one line that goes with the picture.
  static String shareText(FloorCardFacts f) =>
      'I cleared floor ${f.floor} of $game: ${f.title}. $address';

  /// The picture's file name.
  static String fileName(int floor) => 'the-last-room-floor-$floor.png';

  /// What a screen reader hears for the card (where it's shown on screen, as in the catalog).
  static String semantics(FloorCardFacts f) => [
    kicker(f.floor, f.rooms),
    f.title,
    if (f.name case final name?) clearedBy(name),
    for (final s in f.skills) '${SkillCopy.name(s)} earned',
    if (f.hasThenNow) 'Then ${f.then}, now ${f.now}',
    '${TowerHeader.xp(f.xp)} in total',
  ].join('. ');

  static const double _pad = DaylightSpace.s24;
  static const double _hero = 168;
  static const double _arch = 64;
  static const double _archHeight = 76;
  static const double _footer = 40;
  static const double _glyph = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[facts.floor - 1].floor;
    return Semantics(
      image: true,
      label: semantics(facts),
      excludeSemantics: true,
      child: ChapterTint(
        floor: f,
        child: SizedBox.fromSize(
          size: size,
          child: ColoredBox(
            color: f.base,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _Rays(centre: _raysFrom)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_pad, _pad, _pad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            PhosphorFill.buildings,
                            size: _glyph,
                            color: DaylightColors.honey,
                          ),
                          const SizedBox(width: DaylightSpace.s4),
                          Expanded(
                            child: Text(
                              kicker(facts.floor, facts.rooms),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DaylightType.caption3.copyWith(
                                color: f.on,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DaylightSpace.s8),
                      Text(
                        facts.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DaylightType.heading4.copyWith(
                          color: DaylightColors.raised,
                        ),
                      ),
                      if (facts.name case final name?) ...[
                        const SizedBox(height: DaylightSpace.s4),
                        Text(
                          clearedBy(name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DaylightType.body5.copyWith(color: f.on),
                        ),
                      ],
                      const SizedBox(height: DaylightSpace.s16),
                      SizedBox(
                        height: _hero,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CardTower(cleared: facts.floor),
                            const SizedBox(width: DaylightSpace.s16),
                            Expanded(
                              child: _Medals(facts: facts, floor: f),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DaylightSpace.s16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (facts.hasThenNow) ...[
                              Expanded(
                                child: _Tile(
                                  label: thenNow,
                                  value: '${facts.then} → ${facts.now}',
                                  badge: delta(facts.then!, facts.now!),
                                  under: rooms(
                                    facts.firstRoom ?? 1,
                                    facts.lastRoom ?? facts.rooms,
                                  ),
                                ),
                              ),
                              const SizedBox(width: DaylightSpace.s8),
                            ],
                            Expanded(
                              child: _Tile(
                                label: totalXp,
                                value: TowerHeader.xp(facts.xp)
                                    .replaceAll(' XP', ''),
                                under: kicker(
                                  facts.floor,
                                  facts.rooms,
                                ).split(' · ').last,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DaylightSpace.s16),
                      Row(
                        children: [
                          for (final (i, id) in facts.hosts.indexed) ...[
                            if (i > 0) const SizedBox(width: DaylightSpace.s8),
                            ArchPortrait(
                              person: CastPeople.byId(id),
                              expression: CastExpression.smile,
                              width: _arch,
                              height: _archHeight,
                              ground: DaylightColors.honey,
                              border: DaylightSpace.s4,
                              borderColor: DaylightColors.honeyTint,
                              idle: false,
                            ),
                          ],
                          const SizedBox(width: DaylightSpace.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metHere,
                                  style: DaylightType.caption4.copyWith(
                                    color: f.on,
                                  ),
                                ),
                                Text(
                                  [
                                    for (final id in facts.hosts)
                                      interviewerById(id).name,
                                  ].join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: DaylightType.body4.copyWith(
                                    color: DaylightColors.raised,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _footer,
                  child: ColoredBox(
                    color: f.deep,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _pad),
                      child: Row(
                        children: [
                          const Icon(
                            PhosphorFill.door,
                            size: _glyph,
                            color: DaylightColors.honey,
                          ),
                          const SizedBox(width: DaylightSpace.s8),
                          Text(
                            game,
                            style: DaylightType.body4.copyWith(
                              color: DaylightColors.raised,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              ' · $address',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DaylightType.caption4.copyWith(
                                color: f.on,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The rays fan from behind the medals.
  static const Offset _raysFrom = Offset(0.7, 0.36);
}

/// The medals earned on the floor (the reward screen's big arch with its ribbon), scaled to the
/// space; two sit side by side. A floor cleared without earning one (hints were used) shows the
/// rooms lit instead, never a missing medal.
class _Medals extends StatelessWidget {
  const _Medals({required this.facts, required this.floor});

  final FloorCardFacts facts;
  final FloorColours floor;

  /// The reward screen's medal width: the ribbon has room for the longest name there.
  static const double _medal = 184;

  @override
  Widget build(BuildContext context) {
    final skills = facts.skills;
    if (skills.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${facts.rooms}/${facts.rooms}',
            style: DaylightType.tabular(DaylightType.heading2)
                .copyWith(color: DaylightColors.raised),
          ),
          Text(
            FloorCard.roomsLit,
            style: DaylightType.body5.copyWith(color: floor.on),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            children: [
              for (final (i, s) in skills.indexed) ...[
                if (i > 0) const SizedBox(width: DaylightSpace.s4),
                Expanded(
                  child: FittedBox(
                    child: SkillMedal(
                      icon: SkillCopy.icon(s),
                      name: SkillCopy.name(s),
                      floor: floor,
                      width: _medal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: DaylightSpace.s8),
        Text(
          FloorCard.noHints,
          textAlign: TextAlign.center,
          style: DaylightType.caption4.copyWith(color: floor.on),
        ),
      ],
    );
  }
}

/// A number on the floor's deep colour: its label, the value, an optional honey badge and a
/// line under it.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.under,
    this.badge,
  });

  final String label;
  final String value;
  final String under;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: f.deep,
        borderRadius: BorderRadius.circular(DaylightRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DaylightSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: DaylightType.caption4.copyWith(color: f.on)),
            const SizedBox(height: DaylightSpace.s4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    style: DaylightType.tabular(DaylightType.heading5)
                        .copyWith(color: DaylightColors.raised),
                  ),
                ),
                if (badge case final badge?) ...[
                  const SizedBox(width: DaylightSpace.s8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: DaylightColors.honey,
                      borderRadius: BorderRadius.circular(DaylightRadius.tag),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DaylightSpace.s8,
                        vertical: DaylightSpace.s2,
                      ),
                      child: Text(
                        badge,
                        style: DaylightType.tabular(DaylightType.body4)
                            .copyWith(color: DaylightColors.onHoney),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: DaylightSpace.s2),
            Text(under, style: DaylightType.caption4.copyWith(color: f.on)),
          ],
        ),
      ),
    );
  }
}

/// Northstar tower in small, against the sky: the antenna's honey light, the roof, and the
/// three floors of seven doors (the top one at dusk). Every floor up to [cleared] is lit honey;
/// the floor just cleared wears a honey outline; the next floor is open (closed doors), and a
/// floor beyond that is pale and locked, with Sam's door lit at the top.
class _CardTower extends StatelessWidget {
  const _CardTower({required this.cleared});

  final int cleared;

  static const double _door = 14;
  static const double _cell = 20;
  static const double _light = 6;
  static const double _antenna = 10;
  static const double _roof = 12;
  static const double _ring = 2;

  static double get width =>
      _cell * _roomsPerFloor + DaylightSpace.s8 * 2 + DaylightSpace.s12 * 2;
  static const int _roomsPerFloor = 7;

  @override
  Widget build(BuildContext context) {
    final floors = [...chapters]..sort((a, b) => b.number.compareTo(a.number));
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DaylightColors.sky,
          borderRadius: BorderRadius.circular(DaylightRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DaylightSpace.s12,
            DaylightSpace.s8,
            DaylightSpace.s12,
            0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox.square(
                dimension: _light,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DaylightColors.honey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(
                width: DaylightSpace.s2,
                height: _antenna,
                child: ColoredBox(color: DaylightColors.dusk),
              ),
              SizedBox(
                height: _roof,
                width: double.infinity,
                child: CustomPaint(painter: _Roof(_CardInk.roof)),
              ),
              for (final c in floors) _floor(c),
              const SizedBox(
                height: DaylightSpace.s8,
                width: double.infinity,
                child: ColoredBox(color: DaylightColors.desk),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floor(Chapter chapter) {
    final n = chapter.number;
    final f = ChapterGrade.values[n - 1].floor;
    final top = n == chapters.length;
    final open = n <= cleared + 1;
    final done = n <= cleared;
    final ground = top
        ? DaylightColors.dusk
        : open
        ? f.base
        : f.soft;
    final (leaf, panel, frame) = top
        ? (_CardInk.duskWindow, _CardInk.duskPanel, _CardInk.roof)
        : open
        ? (
            f.deep,
            Color.alphaBlend(f.base.withValues(alpha: 0.7), f.deep),
            f.deep,
          )
        : (
            _CardInk.paleWindow(f),
            _CardInk.paleFrame(f),
            _CardInk.paleFrame(f),
          );
    final rooms = missions.where((m) => m.chapter == n).length;
    return Container(
      foregroundDecoration: n == cleared
          ? BoxDecoration(
              border: Border.all(color: DaylightColors.honey, width: _ring),
            )
          : null,
      color: ground,
      padding: const EdgeInsets.symmetric(
        horizontal: DaylightSpace.s8,
        vertical: DaylightSpace.s8,
      ),
      child: Row(
        children: [
          for (var i = 0; i < math.max(rooms, 1); i++)
            Expanded(
              child: Center(
                child: TowerDoor(
                  state: done
                      ? DoorState.done
                      : top && !open && i == rooms - 1
                      ? DoorState.waiting
                      : open
                      ? DoorState.closed
                      : DoorState.locked,
                  width: _door,
                  leaf: done ? DaylightColors.honey : leaf,
                  panel: !open && !done
                      ? (top ? _CardInk.duskText : f.deep)
                      : panel,
                  frame: frame,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The facade's colours, as Northstar tower mixes them: tokens, or tokens over ink or white.
abstract final class _CardInk {
  static final Color roof = Color.alphaBlend(
    DaylightColors.ink.withValues(alpha: 0.3),
    DaylightColors.dusk,
  );
  static final Color duskWindow = Color.alphaBlend(
    DaylightColors.ink.withValues(alpha: 0.35),
    DaylightColors.dusk,
  );
  static final Color duskPanel = Color.alphaBlend(
    DaylightColors.raised.withValues(alpha: 0.12),
    DaylightColors.dusk,
  );
  static final Color duskText = Color.alphaBlend(
    DaylightColors.raised.withValues(alpha: 0.85),
    DaylightColors.dusk,
  );
  static Color paleWindow(FloorColours f) =>
      Color.alphaBlend(DaylightColors.raised.withValues(alpha: 0.65), f.soft);
  static Color paleFrame(FloorColours f) =>
      Color.alphaBlend(f.base.withValues(alpha: 0.2), f.soft);
}

class _Roof extends CustomPainter {
  const _Roof(this.colour);

  final Color colour;

  static const double _slope = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-DaylightSpace.s4, size.height)
      ..lineTo(_slope, 0)
      ..lineTo(size.width - _slope, 0)
      ..lineTo(size.width + DaylightSpace.s4, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_Roof old) => old.colour != colour;
}

/// Soft white rays (7%, as on the reward screen) fanning from [centre], a fraction of the card.
class _Rays extends CustomPainter {
  const _Rays({required this.centre});

  final Offset centre;

  static const double _alpha = 0.07;
  static const int _count = 10;
  static const double _halfWidth = 0.11;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * centre.dx, size.height * centre.dy);
    final reach = size.longestSide * 1.5;
    final ray = Paint()
      ..color = DaylightColors.raised.withValues(alpha: _alpha);
    for (var i = 0; i < _count; i++) {
      final a = i * 2 * math.pi / _count;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(
            c.dx + math.cos(a - _halfWidth) * reach,
            c.dy + math.sin(a - _halfWidth) * reach,
          )
          ..lineTo(
            c.dx + math.cos(a + _halfWidth) * reach,
            c.dy + math.sin(a + _halfWidth) * reach,
          )
          ..close(),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(_Rays old) => old.centre != centre;
}
