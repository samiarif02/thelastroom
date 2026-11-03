import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'tower_rooms.dart';

/// Northstar tower (direction.md §1, mockup `01b`): the illustration is the progress bar.
/// Three floors of seven arched windows under the "NORTHSTAR LABS" roof, against the sky. A
/// room done is a honey window with a check; the room up next has its interviewer inside and a
/// glow ring; a room to come is the floor's deep colour. A floor not open yet is drawn pale
/// (floor 2) or at dusk (the top floor, with one lit window: "Sam waits here"), so the top is
/// visible from day one. Every open window is a button into its room.
///
/// [lit] is the room just finished and [lighting] its 0 → 1 moment (direction.md, motion 5):
/// honey fills the window from the sill up, one glow ring expands and fades, the check lands.
class NorthstarTower extends StatelessWidget {
  const NorthstarTower({
    super.key,
    required this.rooms,
    required this.onTapRoom,
    this.lit,
    this.lighting = 1,
    this.litKey,
  });

  final List<TowerRoom> rooms;
  final ValueChanged<TowerRoom> onTapRoom;
  final int? lit;
  final double lighting;

  /// On the floor with the lit room, so the tower can scroll it into view.
  final Key? litKey;

  static const String sign = 'NORTHSTAR LABS';
  static const String samWaits = 'Sam waits here';
  static String opensAfter(int floor) => 'Opens after floor $floor';
  static String floorLine(Chapter c) => 'Floor ${c.number} · ${c.title}';
  static String count(int done, int of) => '$done of $of';
  static String litCount(int done, int of) => '$done of $of rooms lit';

  /// The floors stand this far in from the sky's edges (the neighbours show either side).
  static const double _inset = DaylightSpace.s16;
  static const double _roof = 20;
  static const double _antenna = 22;
  static const double _ground = 20;

  @override
  Widget build(BuildContext context) {
    final byChapter = <int, List<TowerRoom>>{};
    for (final r in rooms) {
      (byChapter[r.mission.chapter] ??= []).add(r);
    }
    final done = rooms.where((r) => r.state == RoomState.done).length;
    // Top floor first, as it stands.
    final floors = [...chapters]..sort((a, b) => b.number.compareTo(a.number));
    return Semantics(
      label:
          'Northstar tower. ${litCount(done, rooms.length)}. '
          'The top floor is the final round.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DaylightRadius.panel),
        child: ColoredBox(
          color: DaylightColors.sky,
          child: Stack(
            children: [
              const Positioned(left: 8, top: 22, child: _Cloud(width: 48)),
              const Positioned(right: 8, top: 6, child: _Cloud(width: 56)),
              const Positioned(
                left: 0,
                bottom: 0,
                child: _Neighbour(width: 22, height: 90),
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: _Neighbour(width: 22, height: 110),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _inset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Roof(),
                    for (final c in floors)
                      _Floor(
                        key:
                            (byChapter[c.number] ?? const <TowerRoom>[]).any(
                              (r) => r.mission.number == lit,
                            )
                            ? litKey
                            : null,
                        chapter: c,
                        rooms: byChapter[c.number] ?? const [],
                        before: byChapter[c.number - 1],
                        lit: lit,
                        lighting: lighting,
                        onTapRoom: onTapRoom,
                      ),
                    const SizedBox(
                      height: _ground,
                      child: ColoredBox(color: DaylightColors.desk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 0.36,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.skyCloud,
        borderRadius: BorderRadius.vertical(top: Radius.circular(width)),
      ),
    ),
  );
}

class _Neighbour extends StatelessWidget {
  const _Neighbour({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: const ColoredBox(color: DaylightColors.cityFar),
  );
}

/// The antenna with its honey light, and the roof with the sign painted on it (the one place
/// capitals appear: it's lettering on a building, not a heading).
class _Roof extends StatelessWidget {
  const _Roof();

  static const double _light = 8;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: NorthstarTower._antenna + NorthstarTower._roof,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        const Positioned(
          top: _light / 2,
          child: SizedBox(
            width: 4,
            height: NorthstarTower._antenna,
            child: ColoredBox(color: DaylightColors.dusk),
          ),
        ),
        const Positioned(
          top: 0,
          child: SizedBox.square(
            dimension: _light,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DaylightColors.honey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Positioned(
          left: -DaylightSpace.s16,
          right: -DaylightSpace.s16,
          bottom: 0,
          height: NorthstarTower._roof,
          child: CustomPaint(
            painter: const _RoofPainter(),
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  NorthstarTower.sign,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: DaylightType.caption3.copyWith(
                    fontSize: 9,
                    height: 1,
                    letterSpacing: 2,
                    color: DaylightColors.deskTop,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoofPainter extends CustomPainter {
  const _RoofPainter();

  static const double _slope = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(_slope, 0)
      ..lineTo(size.width - _slope, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _TowerInk.roof);
  }

  @override
  bool shouldRepaint(_RoofPainter oldDelegate) => false;
}

/// The facade's colours: every one a token or a token mixed with ink or white.
abstract final class _TowerInk {
  static final Color roof = Color.alphaBlend(
    DaylightColors.ink.withValues(alpha: 0.3),
    DaylightColors.dusk,
  );
  static final Color duskWindow = Color.alphaBlend(
    DaylightColors.ink.withValues(alpha: 0.35),
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

/// One floor: its windows, then its name and its count (or when it opens).
class _Floor extends StatelessWidget {
  const _Floor({
    super.key,
    required this.chapter,
    required this.rooms,
    required this.before,
    required this.lit,
    required this.lighting,
    required this.onTapRoom,
  });

  final Chapter chapter;
  final List<TowerRoom> rooms;

  /// The floor below's rooms; null for floor 1.
  final List<TowerRoom>? before;
  final int? lit;
  final double lighting;
  final ValueChanged<TowerRoom> onTapRoom;

  bool get _top => chapter.number == chapters.length;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[chapter.number - 1].floor;
    final below = before;
    // A floor is open once a room on it can be entered: the floor below is finished.
    final open = rooms.any((r) => r.state != RoomState.locked);
    final done = rooms.where((r) => r.state == RoomState.done).length;
    final ground = _top
        ? DaylightColors.dusk
        : open
        ? f.base
        : f.soft;
    final onGround = _top || open;
    final labelInk = _top
        ? _TowerInk.duskText
        : open
        ? f.on
        : f.deep;
    final asideInk = _top && !open
        ? DaylightColors.honey
        : open
        ? DaylightColors.raised
        : f.deep;
    final aside = open
        ? NorthstarTower.count(done, rooms.length)
        : _top
        ? NorthstarTower.samWaits
        : NorthstarTower.opensAfter(chapter.number - 1);
    final label = NorthstarTower.floorLine(chapter);
    return ColoredBox(
      color: ground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DaylightSpace.s8,
          DaylightSpace.s16,
          DaylightSpace.s12,
          DaylightSpace.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                // Seven cells across whatever the phone gives; a window is 28 wide at most.
                final cell = box.maxWidth / math.max(rooms.length, 1);
                final w = (cell - DaylightSpace.s8).clamp(
                  _Room.minWidth,
                  _Room.width,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, r) in rooms.indexed)
                      Expanded(
                        child: _Room(
                          room: r,
                          floor: f,
                          top: _top,
                          open: open,
                          last: i == rooms.length - 1,
                          window: w,
                          lighting: r.mission.number == lit ? lighting : 1,
                          onTap: () => onTapRoom(r),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: DaylightSpace.s4),
            Padding(
              padding: const EdgeInsets.only(left: DaylightSpace.s4),
              child: Semantics(
                container: true,
                label: below == null || open
                    ? '$label. ${NorthstarTower.count(done, rooms.length)} rooms lit.'
                    : '$label. $aside.',
                excludeSemantics: true,
                // The name left, the count right; at large text they stack.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: DaylightSpace.s8,
                  children: [
                    Text(
                      label,
                      style: DaylightType.caption4.copyWith(color: labelInk),
                    ),
                    Text(
                      aside,
                      style: DaylightType.tabular(
                        onGround
                            ? DaylightType.caption3
                            : DaylightType.caption4,
                      ).copyWith(color: asideInk),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One room's window. 28 × 44 (the current room's ring takes 36 × 48), in a cell at least as
/// tall as a thumb, so the whole column is the target.
class _Room extends StatelessWidget {
  const _Room({
    required this.room,
    required this.floor,
    required this.top,
    required this.open,
    required this.last,
    required this.window,
    required this.lighting,
    required this.onTap,
  });

  final TowerRoom room;
  final FloorColours floor;
  final bool top;
  final bool open;
  final bool last;

  /// This window's width (28 where there's room); its height keeps the 28 × 44 arch.
  final double window;
  final double lighting;
  final VoidCallback onTap;

  static const double width = 28;
  static const double minWidth = 20;
  static const double _aspect = 44 / 28;
  double get height => window * _aspect;
  static const double _ring = 4;
  static const double _check = 16;

  /// When in the lighting moment the check lands and the ring flares.
  static const double _checkFrom = 0.75;
  static const double _ringFrom = 0.55;

  String get _semantics {
    final m = room.mission;
    final what = switch (room.state) {
      RoomState.done => 'lit${room.best == null ? '' : ', best ${room.best}'}',
      RoomState.current => room.inProgress ? 'in progress' : 'up next',
      RoomState.locked => 'locked',
    };
    return 'Room ${m.number}, ${m.title}, $what';
  }

  @override
  Widget build(BuildContext context) {
    final shape = switch (room.state) {
      RoomState.done => _lit(),
      RoomState.current => _current(),
      RoomState.locked => _closed(),
    };
    // A seventh of the facade is 42–48 wide on a phone; for a screen reader each room is
    // announced over a 48 target (it overlaps its neighbours' margins, never their windows).
    final tall = math.max(height + DaylightSpace.s8, DaylightSize.hit);
    return SizedBox(
      height: tall,
      child: LayoutBuilder(
        builder: (context, box) {
          final target = math.max(box.maxWidth, DaylightSize.hit);
          return OverflowBox(
            minWidth: target,
            maxWidth: target,
            minHeight: tall,
            maxHeight: tall,
            child: Semantics(
              button: room.enterable,
              label: _semantics,
              excludeSemantics: true,
              onTap: onTap,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Align(alignment: Alignment.bottomCenter, child: shape),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _arch(Color ground, {Widget? child, Color? frame}) => SizedBox(
    width: window,
    height: height,
    child: ArchFrame(
      ground: ground,
      bottomRadius: 0,
      border: frame == null ? 0 : 2,
      borderColor: frame ?? DaylightColors.raised,
      child: child ?? const SizedBox.shrink(),
    ),
  );

  Color get _unlit => top ? _TowerInk.duskWindow : floor.deep;

  Widget _lit() {
    final t = lighting.clamp(0.0, 1.0);
    if (t >= 1) {
      return _arch(
        DaylightColors.honey,
        child: const Icon(
          PhosphorBold.check,
          size: _check,
          color: DaylightColors.onHoney,
        ),
      );
    }
    // The moment: honey rises from the sill, the ring flares and fades, the check lands.
    final fill = Curves.easeOut.transform(t);
    final ringT = ((t - _ringFrom) / (1 - _ringFrom)).clamp(0.0, 1.0);
    final checkT = ((t - _checkFrom) / (1 - _checkFrom)).clamp(0.0, 1.0);
    return SizedBox(
      width: window,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          if (ringT > 0)
            Positioned.fill(
              child: Transform.scale(
                scale: 1 + ringT * 0.5,
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: 1 - ringT,
                  child: const ArchFrame(
                    ground: BrandColors.clear,
                    border: 2,
                    borderColor: DaylightColors.honey,
                    bottomRadius: 0,
                    child: SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ArchFrame(
            ground: _unlit,
            bottomRadius: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fill,
                widthFactor: 1,
                child: const ColoredBox(color: DaylightColors.honey),
              ),
            ),
          ),
          if (checkT > 0)
            Positioned.fill(
              child: Opacity(
                opacity: checkT,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * checkT,
                  child: const Icon(
                    PhosphorBold.check,
                    size: _check,
                    color: DaylightColors.onHoney,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _current() {
    final person = CastPeople.byId(room.mission.question.speakerId);
    final inside = SizedBox(
      width: window,
      height: height,
      child: ArchFrame(
        ground: DaylightColors.honeyTint,
        bottomRadius: 0,
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minWidth: window * 1.5,
          maxWidth: window * 1.5,
          minHeight: window * 1.5,
          maxHeight: window * 1.5,
          child: CastFigure(person: person, idle: false),
        ),
      ),
    );
    return SizedBox(
      width: window + _ring * 2,
      height: height + _ring,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: ArchFrame(
              ground: BrandColors.clear,
              border: 2,
              borderColor: DaylightColors.raised.withValues(alpha: 0.7),
              bottomRadius: 0,
              child: const SizedBox.shrink(),
            ),
          ),
          inside,
        ],
      ),
    );
  }

  Widget _closed() {
    if (top && last && !open) {
      // The last room, lit from day one: someone is waiting at the top.
      return _arch(
        DaylightColors.honey,
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: _Silhouette(),
        ),
      );
    }
    if (top || open) return _arch(_unlit);
    return _arch(
      _TowerInk.paleWindow(floor),
      frame: _TowerInk.paleFrame(floor),
    );
  }
}

/// Sam in the lit window at the top: a head and shoulders in the dusk colour.
class _Silhouette extends StatelessWidget {
  const _Silhouette();

  static const double _head = 10;
  static const double _shoulders = 20;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox.square(
        dimension: _head,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DaylightColors.dusk,
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(height: 2),
      SizedBox(
        width: _shoulders,
        height: _shoulders / 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DaylightColors.dusk,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(math.max(_shoulders / 2, 1)),
            ),
          ),
        ),
      ),
    ],
  );
}
