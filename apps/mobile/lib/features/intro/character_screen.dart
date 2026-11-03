import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/daylight/daylight_kit.dart';
import '../mission/mission_lookup.dart';
import '../mission/mission_screen.dart';

/// The practice CV, on the desk before Mission 1 (brief 13; Daylight in brief 48): the content's
/// character sheet, headed with the player's name, so it reads as *your practice CV for this
/// role*. On paper: a white sheet with the name beside an arch holding its initial, the facts
/// as label and line, then the first interviewer waiting in her arch and one honey way in. The
/// facts belong to the scenario; the draft step is the player's own words.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  static const String eyebrow = 'Your practice CV';
  static const String kicker = 'Before room 1';
  static const String back = 'Back to the tower';
  static const String premise =
      'Your practice CV for this role. The facts belong to the scenario: every line you '
      'pick in the room is built from them.';
  static const String yourWords =
      'Before the lines, you can start each answer in your own words, about yourself. That '
      'part is yours, and it stays on this device.';
  static const String enter = 'Step into the room';
  static String waiting(String who) => '$who is waiting in room 1.';

  /// The first sentence of a fact: the CV line. The rest is for writers and the coach.
  static String cvLine(CharacterFact fact) {
    final end = fact.detail.indexOf('. ');
    return end < 0 ? fact.detail : fact.detail.substring(0, end + 1);
  }

  static const double _maxWidth = 520;
  static const double _arch = 56;
  static const double _archHeight = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(profileProvider).value?.displayName ??
        PlayerProfile.fallbackName;
    final first = missions.firstWhere((m) => m.number == firstMissionNumber);
    final lead = first.lead;
    return DaylightGround(
      child: SafeArea(
        child: Column(
          children: [
            DaylightTopBar(
              leadingIcon: PhosphorBold.arrowLeft,
              leadingLabel: back,
              onLeading: () => context.go(Routes.tower()),
              kicker: kicker,
              title: eyebrow,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DaylightSpace.s16,
                  DaylightSpace.s16,
                  DaylightSpace.s16,
                  DaylightSpace.s24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(
                          child: _CvSheet(character: player, name: name),
                        ),
                        const SizedBox(height: DaylightSpace.s24),
                        Entrance(
                          index: 1,
                          child: Row(
                            children: [
                              ArchPortrait(
                                person: CastPeople.byId(lead.id),
                                expression: CastExpression.smile,
                                width: _arch,
                                height: _archHeight,
                                ground: DaylightFloors.one.soft,
                                idle: false,
                              ),
                              const SizedBox(width: DaylightSpace.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      waiting(lead.name),
                                      style: DaylightType.body1,
                                    ),
                                    const SizedBox(height: DaylightSpace.s2),
                                    Text(
                                      yourWords,
                                      style: DaylightType.body6.copyWith(
                                        color: DaylightColors.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DaylightSpace.s24),
                        Entrance(
                          index: 2,
                          child: TactileButton(
                            label: enter,
                            icon: PhosphorFill.door,
                            onPressed: () =>
                                context.go(Routes.mission(firstMissionNumber)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvSheet extends StatelessWidget {
  const _CvSheet({required this.character, required this.name});

  final PlayerCharacter character;

  /// The player's name, at the head of the sheet.
  final String name;

  static const double _arch = 56;
  static const double _archHeight = 68;
  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    const f = DaylightFloors.one;
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    return DaylightPanel(
      padding: const EdgeInsets.all(DaylightSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: _arch,
                height: _archHeight,
                child: ArchFrame(
                  ground: f.tint,
                  sill: f.base,
                  child: Center(
                    child: Text(
                      initial,
                      style: DaylightType.heading4.copyWith(color: f.deep),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DaylightSpace.s16),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(name, style: DaylightType.heading4),
                ),
              ),
            ],
          ),
          const SizedBox(height: DaylightSpace.s16),
          Text(
            CharacterScreen.premise,
            style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
          ),
          const SizedBox(height: DaylightSpace.s8),
          for (final fact in character.facts)
            Padding(
              padding: const EdgeInsets.only(top: DaylightSpace.s16),
              child: LayoutBuilder(
                builder: (context, box) {
                  final label = Text(
                    fact.label,
                    style: DaylightType.caption3.copyWith(color: f.deep),
                  );
                  final line = Text(
                    CharacterScreen.cvLine(fact),
                    style: DaylightType.body3,
                  );
                  // Side by side on a phone; stacked when large text leaves no room.
                  if (MediaQuery.textScalerOf(context).scale(_labelWidth) >
                      box.maxWidth / 2) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, line],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _labelWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(top: DaylightSpace.s4),
                          child: label,
                        ),
                      ),
                      Expanded(child: line),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
