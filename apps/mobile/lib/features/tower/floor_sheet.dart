import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import 'tower_rooms.dart';

/// A floor of the tower, opened from Home (the owner's playthrough: "show the other chapters
/// which are locked, so the user can see what else is there"). The floor's name and whether
/// it's open, who interviews on it, what it practises, how it's answered, its seven rooms (a
/// check on the ones lit, the one up next, a lock on the rest) and what opens it. An open room
/// is a button into it.
class FloorSheet extends StatelessWidget {
  const FloorSheet({
    super.key,
    required this.chapter,
    required this.rooms,
    required this.onRoom,
  });

  final Chapter chapter;

  /// This floor's rooms, in order.
  final List<TowerRoom> rooms;
  final ValueChanged<TowerRoom> onRoom;

  static String kicker(Chapter c, {required bool open}) =>
      'Floor ${c.number} · ${open ? 'open' : 'locked'}';
  static const String panel = 'Who you meet';
  static const String practise = 'What you practise';
  static const String answer = 'How you answer';
  static const String roomsTitle = 'The rooms';

  /// What the floor practises, as a player would say it.
  static String practises(int floor) => switch (floor) {
    1 =>
      'Getting through the first rounds: why this role, your story, and evidence that '
          'holds up.',
    2 =>
      'Holding up under pressure: conflict, a failure, unclear briefs, tight deadlines and '
          'hard requests.',
    _ =>
      'The final round: solving a problem live, being interrupted, saying "I don\'t know", '
          'pay, your questions, and the offer.',
  };

  /// How the floor's rooms are answered, from their content.
  static String answeredBy(List<Mission> floor) {
    final voice = floor.where((m) => m.answerMode == AnswerMode.voice).length;
    if (voice == 0) return 'You pick your lines, then say why they work.';
    if (voice == floor.length) {
      return 'Out loud: you say your answer, in your words.';
    }
    return 'Both: some rooms by choices, some out loud.';
  }

  /// The interviewers met on a floor, in the order they first speak.
  static List<String> faces(List<Mission> floor) => <String>{
    for (final m in floor) ...[
      m.question.speakerId,
      for (final l in m.scene) l.speakerId,
    ],
  }.where((id) => interviewers.any((i) => i.id == id)).toList();

  /// What opens a floor that isn't open yet.
  static String opensWhen(Mission last) =>
      'Opens when you finish room ${last.number}, “${last.title}”.';

  static String openLine(int lit, int of) => '$lit of $of rooms lit.';

  static const double _face = 56;
  static const double _faceHeight = 64;

  @override
  Widget build(BuildContext context) {
    final f = ChapterGrade.values[chapter.number - 1].floor;
    final open = floorIsOpen(rooms);
    final lit = rooms.where((r) => r.state == RoomState.done).length;
    final floorMissions = [for (final r in rooms) r.mission];
    final faces = FloorSheet.faces(floorMissions);
    final before = missions
        .where((m) => m.chapter == chapter.number - 1)
        .lastOrNull;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(
        top: DaylightSpace.s24,
        bottom: DaylightSpace.s8,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: DaylightType.body1),
      ),
    );
    return ChapterTint(
      floor: f,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: DaylightSpace.s40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(
                  label: kicker(chapter, open: open),
                  icon: open
                      ? PhosphorBold.lockSimpleOpen
                      : PhosphorBold.lockSimple,
                  tone: TagTone.floor(f),
                ),
                const SizedBox(height: DaylightSpace.s8),
                Semantics(
                  header: true,
                  child: Text(chapter.title, style: DaylightType.heading4),
                ),
                const SizedBox(height: DaylightSpace.s4),
                Text(
                  open || before == null
                      ? openLine(lit, rooms.length)
                      : opensWhen(before),
                  style: DaylightType.body5.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          heading(panel),
          Wrap(
            spacing: DaylightSpace.s12,
            runSpacing: DaylightSpace.s12,
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
          heading(practise),
          Text(practises(chapter.number), style: DaylightType.body6),
          heading(answer),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                floorMissions.any((m) => m.answerMode == AnswerMode.voice)
                    ? PhosphorBold.microphone
                    : PhosphorBold.cards,
                size: DaylightSpace.s16 + DaylightSpace.s4,
                color: f.deep,
              ),
              const SizedBox(width: DaylightSpace.s8),
              Expanded(
                child: Text(
                  answeredBy(floorMissions),
                  style: DaylightType.body6,
                ),
              ),
            ],
          ),
          heading(roomsTitle),
          for (final r in rooms)
            Padding(
              padding: const EdgeInsets.only(bottom: DaylightSpace.s8),
              child: _RoomRow(room: r, onTap: () => onRoom(r)),
            ),
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onTap});

  final TowerRoom room;
  final VoidCallback onTap;

  static const double _tile = 32;
  static const double _glyph = 16;

  @override
  Widget build(BuildContext context) {
    final f = ChapterTint.floorOf(context);
    final m = room.mission;
    final (ground, ink, glyph, aside) = switch (room.state) {
      RoomState.done => (
        DaylightColors.honey,
        DaylightColors.onHoney,
        PhosphorBold.check,
        room.best == null ? null : '${room.best}',
      ),
      RoomState.current => (
        f.base,
        DaylightColors.raised,
        PhosphorFill.play,
        room.inProgress ? 'In progress' : 'Up next',
      ),
      RoomState.locked => (
        DaylightColors.sand,
        DaylightColors.ink3,
        PhosphorBold.lockSimple,
        null,
      ),
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DaylightSpace.s12,
        vertical: DaylightSpace.s8,
      ),
      child: Row(
        children: [
          Container(
            width: _tile,
            height: _tile,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ground,
              borderRadius: BorderRadius.circular(DaylightRadius.inner),
            ),
            child: Icon(glyph, size: _glyph, color: ink),
          ),
          const SizedBox(width: DaylightSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${m.number}',
                  style: DaylightType.caption4.copyWith(
                    color: DaylightColors.ink2,
                  ),
                ),
                Text(
                  m.title,
                  style: DaylightType.body2.copyWith(
                    color: room.enterable
                        ? DaylightColors.ink
                        : DaylightColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (aside case final a?)
            Text(
              a,
              style: DaylightType.tabular(DaylightType.body4)
                  .copyWith(color: f.deep),
            ),
        ],
      ),
    );
    final label =
        'Room ${m.number}, ${m.title}, ${switch (room.state) {
          RoomState.done => 'lit',
          RoomState.current => 'up next',
          RoomState.locked => 'locked',
        }}';
    if (!room.enterable) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DaylightColors.paper,
            borderRadius: BorderRadius.circular(DaylightRadius.tile),
          ),
          child: row,
        ),
      );
    }
    return Tactile(
      label: label,
      onTap: onTap,
      style: TactileStyle(
        face: DaylightColors.raised,
        edge: DaylightColors.sand2,
        radius: BorderRadius.circular(DaylightRadius.tile),
        depth: DaylightSize.edgeSmall,
      ),
      child: row,
    );
  }
}
