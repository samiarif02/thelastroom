import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/profile/profile_repository.dart';
import '../../ui/film_kit.dart';
import '../mission/mission_screen.dart';

/// The practice CV, on the desk before Mission 1 (brief 13): the content's character sheet,
/// headed with the player's name, so it reads as *your practice CV for this role*. The facts
/// belong to the scenario; the draft step is the player's own words.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  static const String eyebrow = 'YOUR PRACTICE CV';
  static const String premise =
      'Your practice CV for this role. The facts belong to the scenario: every line you '
      'pick in the room is built from them.';
  static const String yourWords =
      'Before the lines, you can start each answer in your own words, about yourself. That '
      'part is yours, and it stays on this device.';
  static const String enter = 'Step into the room';

  /// The first sentence of a fact: the CV line. The rest is for writers and the coach.
  static String cvLine(CharacterFact fact) {
    final end = fact.detail.indexOf('. ');
    return end < 0 ? fact.detail : fact.detail.substring(0, end + 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const grade = ChapterGrade.lobby;
    final name =
        ref.watch(profileProvider).value?.displayName ??
        PlayerProfile.fallbackName;
    return Stack(
      fit: StackFit.expand,
      children: [
        const VividBackdrop(grade: grade),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BrandSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  eyebrow,
                  textAlign: TextAlign.center,
                  style: BrandVividType.kicker.copyWith(
                    color: BrandVivid.accent,
                  ),
                ),
                const SizedBox(height: BrandSpace.lg),
                StaggeredEntrance(
                  index: 0,
                  child: _CvSheet(character: player, name: name),
                ),
                const SizedBox(height: BrandSpace.lg),
                const Text(
                  yourWords,
                  textAlign: TextAlign.center,
                  style: BrandVividType.body,
                ),
                const SizedBox(height: BrandSpace.lg),
                VividButton.play(
                  label: enter,
                  expand: true,
                  onPressed: () =>
                      context.go(Routes.mission(firstMissionNumber)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CvSheet extends StatelessWidget {
  const _CvSheet({required this.character, required this.name});

  final PlayerCharacter character;

  /// The player's name, at the head of the sheet.
  final String name;

  static const double _shadowBlur = 24;
  static const Offset _shadowOffset = Offset(-6, 14);
  static const double _tilt = -0.012;
  static const double _labelWidth = 92;

  @override
  Widget build(BuildContext context) {
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    return Transform.rotate(
      angle: _tilt,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.paper,
          boxShadow: [
            BoxShadow(
              color: BrandVivid.night.withValues(alpha: 0.6),
              blurRadius: _shadowBlur,
              offset: _shadowOffset,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(BrandSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: BrandType.display.copyWith(color: BrandColors.ink),
                ),
              ),
              const SizedBox(height: BrandSpace.sm),
              Text(
                CharacterScreen.premise,
                textAlign: TextAlign.center,
                style: BrandType.body.copyWith(color: BrandColors.inkSoft),
              ),
              const SizedBox(height: BrandSpace.md),
              const DoubleRule(color: BrandColors.inkSoft),
              for (final fact in character.facts)
                Padding(
                  padding: const EdgeInsets.only(top: BrandSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _labelWidth,
                        child: Text(fact.label.toUpperCase(), style: soft),
                      ),
                      Expanded(
                        child: Text(
                          CharacterScreen.cvLine(fact),
                          style: BrandType.body.copyWith(
                            color: BrandColors.ink,
                          ),
                        ),
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
