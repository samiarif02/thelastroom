import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'explainer_copy.dart';

/// A piece of explainer art (issue 75): drawn from the Daylight kit, inert (nothing in it is a
/// button) and read as one [label] by a screen reader.
class ExplainerArt extends StatelessWidget {
  const ExplainerArt({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    excludeSemantics: true,
    child: IgnorePointer(child: child),
  );
}

/// Page 1: Northstar tower in miniature (three floors of seven arched windows, room 1 open with
/// Priya inside, Sam's lit window at dusk on the top floor), and the four faces you'll meet.
class TowerArt extends StatelessWidget {
  const TowerArt({super.key});

  static const int _rooms = 7;
  static const double _windowAspect = 44 / 28;
  static const double _portrait = 48;
  static const double _portraitHeight = 58;

  /// Sam's window on the top floor: the middle one.
  static const int _samWindow = 3;

  @override
  Widget build(BuildContext context) => ExplainerArt(
    label: ExplainerCopy.towerArt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DaylightRadius.panel),
          child: ColoredBox(
            color: DaylightColors.sky,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DaylightSpace.s24,
                DaylightSpace.s16,
                DaylightSpace.s24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: DaylightSpace.s4,
                    ),
                    decoration: const BoxDecoration(
                      color: DaylightColors.ink,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(DaylightRadius.tile),
                      ),
                    ),
                    child: Text(
                      ExplainerCopy.sign,
                      textAlign: TextAlign.center,
                      style: DaylightType.caption3.copyWith(
                        color: DaylightColors.honey,
                      ),
                    ),
                  ),
                  _floor(DaylightColors.dusk, (i) {
                    return i == _samWindow
                        ? ArchWindowState.lit
                        : ArchWindowState.dark;
                  }, DaylightFloors.three),
                  _floor(
                    DaylightFloors.two.soft,
                    (_) => ArchWindowState.unlit,
                    DaylightFloors.two,
                  ),
                  _floor(
                    DaylightFloors.one.soft,
                    (i) => i == 0
                        ? ArchWindowState.current
                        : ArchWindowState.unlit,
                    DaylightFloors.one,
                    person: CastPeople.priya,
                  ),
                  const SizedBox(
                    height: DaylightSpace.s12,
                    child: ColoredBox(color: DaylightColors.desk),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DaylightSpace.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, p) in [
              CastPeople.priya,
              CastPeople.marcus,
              CastPeople.lena,
            ].indexed) ...[
              ArchPortrait(
                person: p,
                expression: CastExpression.smile,
                width: _portrait,
                height: _portraitHeight,
                ground: DaylightFloors.all[i].soft,
                idle: false,
              ),
              const SizedBox(width: DaylightSpace.s8),
            ],
            const ArchPortrait(
              person: CastPeople.sam,
              width: _portrait,
              height: _portraitHeight,
              ground: DaylightColors.dusk,
              idle: false,
            ),
          ],
        ),
        const SizedBox(height: DaylightSpace.s8),
        const Center(
          child: Tag(
            label: ExplainerCopy.towerFacts,
            icon: PhosphorBold.buildings,
            tone: TagTone.honey,
          ),
        ),
      ],
    ),
  );

  Widget _floor(
    Color face,
    ArchWindowState Function(int room) state,
    FloorColours floor, {
    CastPerson? person,
  }) => ColoredBox(
    color: face,
    child: Padding(
      padding: const EdgeInsets.all(DaylightSpace.s8),
      child: LayoutBuilder(
        builder: (context, box) {
          final width =
              (box.maxWidth - DaylightSpace.s4 * (_rooms - 1)) / _rooms;
          return Row(
            children: [
              for (var i = 0; i < _rooms; i++) ...[
                if (i > 0) const SizedBox(width: DaylightSpace.s4),
                ArchWindow(
                  state: state(i),
                  floor: floor,
                  person: person,
                  width: width,
                  height: width * _windowAspect,
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

/// Page 2: a room in miniature. Marcus asks, two lines to pick from (the strong one picked),
/// then the "why?" step, with floor 2's microphone.
class RoomArt extends StatelessWidget {
  const RoomArt({super.key});

  static const double _portrait = 56;
  static const double _portraitHeight = 68;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    const f = DaylightFloors.two;
    return ExplainerArt(
      label: ExplainerCopy.roomArt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArchPortrait(
                person: CastPeople.marcus,
                expression: CastExpression.talk,
                width: _portrait,
                height: _portraitHeight,
                ground: f.soft,
                idle: false,
              ),
              const SizedBox(width: DaylightSpace.s16),
              const Expanded(
                child: SpeechBubble(
                  speaker: ExplainerCopy.askSpeaker,
                  line: ExplainerCopy.askLine,
                  tail: BubbleTail.left,
                  floor: f,
                ),
              ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s16),
          const PickCard(
            text: ExplainerCopy.answerStrong,
            letter: 'A',
            state: PickState.selected,
            floor: f,
          ),
          const SizedBox(height: DaylightSpace.s8),
          const PickCard(
            text: ExplainerCopy.answerWeak,
            letter: 'B',
            state: PickState.dimmed,
            floor: f,
          ),
          const SizedBox(height: DaylightSpace.s16),
          DaylightPanel(
            color: DaylightColors.honeyTint,
            edge: DaylightColors.honeyEdge,
            radius: DaylightRadius.card,
            child: Row(
              children: [
                const Icon(
                  PhosphorFill.lightbulbFilament,
                  size: _iconSize,
                  color: DaylightColors.honeyInk,
                ),
                const SizedBox(width: DaylightSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ExplainerCopy.whyKicker,
                        style: DaylightType.caption3.copyWith(
                          color: DaylightColors.honeyInk,
                        ),
                      ),
                      Text(ExplainerCopy.whyLine, style: DaylightType.body4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DaylightSpace.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: Tag(
              label: ExplainerCopy.voiceTag,
              icon: PhosphorBold.microphone,
              tone: TagTone.floor(f),
            ),
          ),
        ],
      ),
    );
  }
}
