import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import 'tower_rooms.dart';

/// The up-next card (direction.md §1, mockup `01-home`): the room to play next on its floor's
/// colour, r24, with its interviewer's arch window breaking 48 above the card's top edge. The
/// kicker "Up next · room 4 of 21", the title (Heading 5), what kind of room it is, the
/// interviewer's question on the floor's deep colour, and one honey button: one tap starts it
/// (brief 17). [quiet] leaves the question out (the welcome-back card is up, and the button
/// stays above the fold).
class TowerHero extends StatelessWidget {
  const TowerHero({
    super.key,
    required this.room,
    required this.onPlay,
    this.quiet = false,
  });

  final TowerRoom room;
  final VoidCallback onPlay;
  final bool quiet;

  static const String continueLabel = 'Continue';
  static const String playAgain = 'Play again';
  static const String outLoud = 'Out loud';
  static const String timed = 'Timed';

  static String upNext(int number) =>
      'Up next · room $number of ${missions.length}';
  static String beatYourBest(int number, int best) =>
      'Beat your best · room $number · $best';
  static String beats(int n) => '$n beats';

  /// What the button says ("Start room 4").
  static String buttonLabel(TowerRoom room) {
    final n = room.mission.number;
    if (room.inProgress) return '$continueLabel room $n';
    if (room.state == RoomState.done) return '$playAgain: room $n';
    return 'Start room $n';
  }

  /// What the button says to a screen reader.
  static String playLabel(TowerRoom room) =>
      '${buttonLabel(room)}, ${room.mission.title}';

  /// The window that breaks out of the card's top edge.
  static const double _window = 112;
  static const double _windowHeight = 136;
  static const double _breakOut = DaylightSpace.s48;
  static const double _frame = 4;

  @override
  Widget build(BuildContext context) {
    final m = room.mission;
    final f = m.grade.floor;
    final lead = m.lead;
    final replay = room.state == RoomState.done;
    final kicker = replay && room.best != null
        ? beatYourBest(m.number, room.best!)
        : upNext(m.number);
    final voice = m.answerMode == AnswerMode.voice;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: DaylightType.caption3.copyWith(color: f.on)),
        const SizedBox(height: DaylightSpace.s8),
        Semantics(
          header: true,
          child: Text(
            m.title,
            style: DaylightType.heading5.copyWith(color: DaylightColors.raised),
          ),
        ),
        const SizedBox(height: DaylightSpace.s12),
        Wrap(
          spacing: DaylightSpace.s8,
          runSpacing: DaylightSpace.s8,
          children: [
            if (voice)
              Tag(
                label: outLoud,
                icon: PhosphorBold.microphone,
                tone: TagTone(f.deep, DaylightColors.raised),
              )
            else
              Tag(
                label: beats(m.beats.length),
                icon: PhosphorBold.cards,
                tone: TagTone(f.deep, DaylightColors.raised),
              ),
            if (m.timed)
              Tag(
                label: timed,
                icon: PhosphorBold.timer,
                tone: TagTone(f.deep, DaylightColors.raised),
              ),
          ],
        ),
      ],
    );
    return ChapterTint(
      floor: f,
      child: Padding(
        padding: const EdgeInsets.only(top: _breakOut),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: f.base,
                borderRadius: BorderRadius.circular(DaylightRadius.panel),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DaylightSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: _window + DaylightSpace.s12,
                        top: DaylightSpace.s4,
                      ),
                      child: copy,
                    ),
                    if (!quiet) ...[
                      const SizedBox(height: DaylightSpace.s12),
                      _Says(line: m.question.text, who: lead, floor: f),
                    ],
                    const SizedBox(height: DaylightSpace.s16),
                    Semantics(
                      label: playLabel(room),
                      button: true,
                      excludeSemantics: true,
                      child: TactileButton(
                        label: buttonLabel(room),
                        icon: PhosphorFill.play,
                        compact: true,
                        tone: TactileTone.floor,
                        onPressed: onPlay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: DaylightSpace.s16,
              top: -_breakOut,
              child: ArchPortrait(
                person: CastPeople.byId(lead.id),
                expression: CastExpression.listening,
                width: _window,
                height: _windowHeight,
                border: _frame,
                sill: f.deep,
                semanticLabel: '${lead.name}, ${lead.role}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The interviewer's question on the floor's deep colour (r8 inside the r24 card).
class _Says extends StatelessWidget {
  const _Says({required this.line, required this.who, required this.floor});

  final String line;
  final Interviewer who;
  final FloorColours floor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: floor.deep,
      borderRadius: BorderRadius.circular(DaylightRadius.inner),
    ),
    child: Padding(
      padding: const EdgeInsets.all(DaylightSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$line”',
            style: DaylightType.body5.copyWith(color: DaylightColors.raised),
          ),
          const SizedBox(height: DaylightSpace.s4),
          Text(
            '${who.name} · ${who.role.toLowerCase()}',
            style: DaylightType.caption4.copyWith(color: floor.on),
          ),
        ],
      ),
    ),
  );
}
