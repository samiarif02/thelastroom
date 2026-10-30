import 'package:brand/brand.dart';
import 'package:content/content.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../ui/film_kit.dart';
import '../mission/mission_screen.dart';
import '../mission/widgets/cue_button.dart';

/// The character card: the candidate you play (the content's character sheet), as their CV on
/// the desk, before Mission 1. The answers are Jordan's; the draft step is the player's own.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  static const String eyebrow = 'THE CANDIDATE';
  static const String yourWords =
      "When the interviewer asks, you pick Jordan's lines. Before them, you can write the "
      'answer in your own words, about yourself. That part is yours, and it stays on this '
      'device.';
  static const String enter = 'Step into the room';

  /// The first sentence of a fact: the CV line. The rest is for writers and the coach.
  static String cvLine(CharacterFact fact) {
    final end = fact.detail.indexOf('. ');
    return end < 0 ? fact.detail : fact.detail.substring(0, end + 1);
  }

  @override
  Widget build(BuildContext context) {
    const grade = ChapterGrade.lobby;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.6, -0.7),
              radius: 1.3,
              colors: [grade.tint, BrandColors.surface, BrandColors.void_],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BrandSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrassOrnament(text: eyebrow),
                const SizedBox(height: BrandSpace.lg),
                const _CvSheet(character: player),
                const SizedBox(height: BrandSpace.lg),
                Text(
                  yourWords,
                  textAlign: TextAlign.center,
                  style: BrandType.body.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: BrandSpace.lg),
                CueButton(
                  label: enter,
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
  const _CvSheet({required this.character});

  final PlayerCharacter character;

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
              color: BrandColors.void_.withValues(alpha: 0.8),
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
                  character.name,
                  textAlign: TextAlign.center,
                  style: BrandType.display.copyWith(color: BrandColors.ink),
                ),
              ),
              const SizedBox(height: BrandSpace.sm),
              Text(
                character.premise,
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
