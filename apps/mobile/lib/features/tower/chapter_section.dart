import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../../ui/daylight/daylight_route.dart';
import '../mission/mission_lookup.dart';
import 'floor_sheet.dart';
import 'tower_door.dart';
import 'tower_rooms.dart';

/// One floor on the chapters list (the owner, 4 Nov: "a new view, chapter-wise, with the
/// missions accordingly, and missions the user hasn't reached locked, as you've done on the
/// tower"): in the floor's colours, its name, whether it's open and its count, a strip of its
/// doors; opened, what it practises, how it's answered, who you meet, and a row per room with
/// the tower's door. The doors and the locks follow the tower's own rules ([doorStateOf],
/// [opensAfter]).
class ChapterSection extends StatelessWidget {
  const ChapterSection({
    super.key,
    required this.chapter,
    required this.rooms,
    required this.expanded,
    required this.onToggle,
    required this.onRoom,
    this.note,
  });

  final Chapter chapter;

  /// This floor's rooms, in order.
  final List<TowerRoom> rooms;
  final bool expanded;
  final VoidCallback onToggle;

  /// A room tapped: an open one starts, a locked one says what opens it.
  final ValueChanged<TowerRoom> onRoom;

  /// The locked room whose note is showing, by number.
  final int? note;

  static String title(Chapter c) => 'Floor ${c.number} · ${c.title}';
  static String count(int lit, int of) => '$lit of $of';
  static const String allLit = 'Every room lit';
  static const String openNow = 'Open';
  static const String expand = 'Show its rooms';
  static const String collapse = 'Hide its rooms';
  static const String meet = 'Who you meet';

  static String headerLabel(Chapter c, {required int lit, required int of}) =>
      '${title(c)}, ${count(lit, of)} rooms lit';

  /// The header's door: icon size.
  static const double doorIcon = 18;
  static const double _caret = 16;
  static const double _strip = 16;
  static const double _face = 40;
  static const double _faceHeight = 46;

  /// A quarter turn: the caret points down when the floor is open.
  static const double _caretOpen = 0.25;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[chapter.number - 1].floor;
    final open = floorIsOpen(rooms);
    final lit = rooms.where((r) => r.state == RoomState.done).length;
    final floor = [for (final r in rooms) r.mission];
    final before = missions
        .where((m) => m.chapter == chapter.number - 1)
        .lastOrNull;
    final top = chapter.number == chapters.length;
    final still = MediaQuery.disableAnimationsOf(context);
    final status = !open && before != null
        ? FloorSheet.opensWhen(before)
        : lit == rooms.length
        ? allLit
        : openNow;
    final header = Semantics(
      button: true,
      header: true,
      expanded: expanded,
      label:
          '${headerLabel(chapter, lit: lit, of: rooms.length)}. $status. '
          '${expanded ? collapse : expand}.',
      excludeSemantics: true,
      onTap: onToggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: DaylightSize.hit),
          child: Row(
            children: [
              // The floor's door in its colour: shut on an open floor, honey once every
              // room is lit, pale and locked on a floor not open yet.
              _floorDoor(f, open: open, allLit: lit == rooms.length),
              const SizedBox(width: DaylightSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title(chapter),
                      style: DaylightType.title3.copyWith(color: f.deep),
                    ),
                    const SizedBox(height: DaylightSpace.s2),
                    Text(
                      status,
                      style: DaylightType.caption4.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DaylightSpace.s8),
              Tag(
                label: count(lit, rooms.length),
                icon: open
                    ? PhosphorBold.lockSimpleOpen
                    : PhosphorBold.lockSimple,
                tone: open ? TagTone.floor(f) : TagTone.sand,
              ),
              const SizedBox(width: DaylightSpace.s8),
              AnimatedRotation(
                turns: expanded ? _caretOpen : 0,
                duration: still ? Duration.zero : DaylightMotion.colour,
                curve: DaylightMotion.ease,
                child: const Icon(
                  PhosphorBold.caretRight,
                  size: _caret,
                  color: DaylightColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Widget door(TowerRoom r, double width, {required bool last}) =>
        _door(r, f, width: width, open: open, topLast: top && last);
    final strip = ExcludeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: DaylightSpace.s12,
          left: doorIcon + DaylightSpace.s12,
        ),
        child: Wrap(
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s8,
          children: [
            for (final (i, r) in rooms.indexed)
              door(r, _strip, last: i == rooms.length - 1),
          ],
        ),
      ),
    );
    final faces = FloorSheet.faces(floor);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DaylightSpace.s12),
        Text(FloorSheet.practises(chapter.number), style: DaylightType.body5),
        const SizedBox(height: DaylightSpace.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              floor.any((m) => m.answerMode == AnswerMode.voice)
                  ? PhosphorBold.microphone
                  : PhosphorBold.cards,
              size: DaylightSpace.s16 + DaylightSpace.s4,
              color: f.deep,
            ),
            const SizedBox(width: DaylightSpace.s8),
            Expanded(
              child: Text(
                FloorSheet.answeredBy(floor),
                style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
              ),
            ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s16),
        Semantics(
          label:
              '$meet: ${faces.map((id) => interviewerById(id).name).join(', ')}',
          excludeSemantics: true,
          child: Wrap(
            spacing: DaylightSpace.s12,
            runSpacing: DaylightSpace.s8,
            children: [
              for (final id in faces)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ArchPortrait(
                      person: CastPeople.byId(id),
                      expression: open
                          ? CastExpression.smile
                          : CastExpression.neutral,
                      width: _face,
                      height: _faceHeight,
                      ground: f.soft,
                      idle: false,
                    ),
                    const SizedBox(height: DaylightSpace.s4),
                    Text(
                      interviewerById(id).name,
                      style: DaylightType.caption4.copyWith(
                        color: DaylightColors.ink2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: DaylightSpace.s16),
        for (final (i, r) in rooms.indexed) ...[
          if (i > 0) const SizedBox(height: DaylightSpace.s8),
          _RoomRow(
            room: r,
            door: door(r, _RoomRow.doorWidth, last: i == rooms.length - 1),
            floorOpen: open,
            noted: note == r.mission.number,
            onTap: () => onRoom(r),
          ),
        ],
      ],
    );
    final swap = AnimatedSwitcher(
      duration: DaylightMotion.colour,
      switchInCurve: DaylightMotion.ease,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(
        key: ValueKey(expanded),
        child: expanded ? body : strip,
      ),
    );
    return ChapterTint(
      floor: f,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          // The fold: the height eases open with motion on; reduced motion only cross-fades.
          ClipRect(
            child: still
                ? swap
                : AnimatedSize(
                    duration: DaylightMotion.move,
                    curve: DaylightMotion.ease,
                    alignment: Alignment.topCenter,
                    child: swap,
                  ),
          ),
        ],
      ),
    );
  }
}

/// A floor's header icon: the tower's door at icon size, in the floor's colours.
Widget _floorDoor(FloorColours f, {required bool open, required bool allLit}) {
  final ink = open ? DoorInk.open(f) : DoorInk.pale(f);
  final state = !open
      ? DoorState.locked
      : allLit
      ? DoorState.done
      : DoorState.closed;
  return TowerDoor(
    state: state,
    width: ChapterSection.doorIcon,
    leaf: state == DoorState.done ? DaylightColors.honey : ink.leaf,
    panel: state == DoorState.locked ? f.deep : ink.panel,
    frame: ink.frame,
  );
}

/// [room]'s door at [width], in the tower's colours for its floor: honey once played, ajar with
/// the interviewer for the room to play, closed on an open floor, pale with a lock on one not
/// open yet, and the very last room lit with Sam in it.
Widget _door(
  TowerRoom room,
  FloorColours f, {
  required double width,
  required bool open,
  required bool topLast,
}) {
  final state = doorStateOf(room, floorOpen: open, topLast: topLast);
  final ink = open ? DoorInk.open(f) : DoorInk.pale(f);
  return TowerDoor(
    state: state,
    width: width,
    leaf: state == DoorState.done ? DaylightColors.honey : ink.leaf,
    panel: state == DoorState.locked ? f.deep : ink.panel,
    frame: ink.frame,
    person: state == DoorState.next
        ? CastPeople.byId(room.mission.question.speakerId)
        : null,
  );
}

/// One room: its door, the number and who interviews, the title, how it's answered, and the
/// best score once played. An open room is the way in; a locked one, tapped, says what opens it.
class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.room,
    required this.door,
    required this.floorOpen,
    required this.noted,
    required this.onTap,
  });

  final TowerRoom room;
  final Widget door;
  final bool floorOpen;
  final bool noted;
  final VoidCallback onTap;

  static const double doorWidth = 28;
  static const double _score = 48;

  static String mode(Mission m) =>
      m.answerMode == AnswerMode.voice ? 'Voice' : 'Choices';

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final m = room.mission;
    final locked = !room.enterable;
    final tail = switch (room.state) {
      RoomState.done =>
        'played${room.best == null ? '' : ', best ${room.best}'}. Play again',
      RoomState.current =>
        room.inProgress ? 'in progress. Continue' : 'up next. Play',
      RoomState.locked =>
        'locked: opens after ${opensAfter(m, floorOpen: floorOpen)}',
    };
    final label =
        'Room ${m.number}, ${m.title}, with ${m.lead.name}, '
        '${mode(m).toLowerCase()}, $tail.';
    BuildContext? doorAt;
    void tap() {
      // An open door says where the room grows from (brief 50), as on the tower.
      if (doorAt case final c? when c.mounted && !locked) {
        if (DoorOrigin.of(c) case final origin?) {
          DoorTapped(origin).dispatch(context);
        }
      }
      onTap();
    }

    final best = room.best;
    final row = Padding(
      padding: const EdgeInsets.all(DaylightSpace.s12),
      child: Row(
        children: [
          // Clear of the light the open door spills on its sill.
          Padding(
            padding: const EdgeInsets.only(bottom: DaylightSpace.s8),
            child: Builder(
              builder: (c) {
                doorAt = c;
                return door;
              },
            ),
          ),
          const SizedBox(width: DaylightSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${m.number} · ${m.lead.name}',
                  style: DaylightType.tabular(DaylightType.caption4)
                      .copyWith(color: DaylightColors.ink2),
                ),
                const SizedBox(height: DaylightSpace.s2),
                Text(
                  m.title,
                  style: DaylightType.body1.copyWith(
                    color: locked ? DaylightColors.ink2 : DaylightColors.ink,
                  ),
                ),
                const SizedBox(height: DaylightSpace.s4),
                Wrap(
                  spacing: DaylightSpace.s8,
                  runSpacing: DaylightSpace.s4,
                  children: [
                    Tag(
                      label: mode(m),
                      icon: m.answerMode == AnswerMode.voice
                          ? PhosphorBold.microphone
                          : PhosphorBold.cards,
                      tone: locked ? TagTone.sand : TagTone.floor(f),
                    ),
                    if (room.state == RoomState.current)
                      Tag(
                        label: room.inProgress
                            ? _Words.inProgress
                            : _Words.upNext,
                        icon: PhosphorFill.play,
                        tone: TagTone.honey,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: DaylightSpace.s8),
          if (best != null)
            Container(
              constraints: const BoxConstraints(minWidth: _score),
              padding: const EdgeInsets.symmetric(
                horizontal: DaylightSpace.s8,
                vertical: DaylightSpace.s4,
              ),
              decoration: BoxDecoration(
                color: f.tint,
                borderRadius: BorderRadius.circular(DaylightRadius.inner),
              ),
              child: Column(
                children: [
                  Text(
                    _Words.best,
                    style: DaylightType.caption4.copyWith(color: f.deep),
                  ),
                  Text(
                    '$best',
                    style: DaylightType.tabular(DaylightType.heading6)
                        .copyWith(color: f.deep),
                  ),
                ],
              ),
            )
          else
            Icon(
              locked ? PhosphorBold.lockSimple : PhosphorBold.caretRight,
              size: DaylightSpace.s16,
              color: locked ? DaylightColors.ink3 : f.deep,
            ),
        ],
      ),
    );
    final card = Tactile(
      label: label,
      onTap: tap,
      style: switch (room.state) {
        RoomState.done => TactileStyle(
          face: DaylightColors.raised,
          edge: DaylightColors.sand2,
          radius: BorderRadius.circular(DaylightRadius.card),
        ),
        RoomState.current => TactileStyle(
          face: DaylightColors.raised,
          edge: f.base,
          radius: BorderRadius.circular(DaylightRadius.card),
          ring: f.base,
        ),
        RoomState.locked => TactileStyle(
          face: DaylightColors.sand,
          edge: DaylightColors.sand2,
          radius: BorderRadius.circular(DaylightRadius.card),
          depth: DaylightSize.edgeSmall,
        ),
      },
      child: row,
    );
    final still = MediaQuery.disableAnimationsOf(context);
    final note = noted
        ? _LockedNote(text: lockedNote(m, floorOpen: floorOpen))
        : const SizedBox(width: double.infinity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        if (still)
          note
        else
          AnimatedSize(
            duration: DaylightMotion.colour,
            curve: DaylightMotion.ease,
            alignment: Alignment.topCenter,
            child: note,
          ),
      ],
    );
  }
}

/// Why a locked room is shut, in a line: the tower's rule ("Opens after room 7") and what to
/// finish for it.
String lockedNote(Mission m, {required bool floorOpen}) {
  final after = 'Opens after ${opensAfter(m, floorOpen: floorOpen)}';
  final before = floorOpen
      ? missionByNumber(m.number - 1)
      : missions.where((x) => x.chapter == m.chapter - 1).lastOrNull;
  if (before == null) return '$after.';
  return floorOpen
      ? '$after: finish “${before.title}” first.'
      : '$after: finish its last room, “${before.title}”.';
}

abstract final class _Words {
  static const String upNext = 'Up next';
  static const String inProgress = 'In progress';
  static const String best = 'Best';
}

/// The note under a locked room: a lock and the line, in the floor's tint, read out as it
/// appears.
class _LockedNote extends StatelessWidget {
  const _LockedNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: DaylightSpace.s8),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: f.tint,
            borderRadius: BorderRadius.circular(DaylightRadius.tile),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DaylightSpace.s12,
              vertical: DaylightSpace.s8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: DaylightSpace.s2),
                  child: Icon(
                    PhosphorFill.lockSimple,
                    size: DaylightSpace.s16,
                    color: f.deep,
                  ),
                ),
                const SizedBox(width: DaylightSpace.s8),
                Expanded(
                  child: Text(
                    text,
                    style: DaylightType.body5.copyWith(color: f.deep),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
