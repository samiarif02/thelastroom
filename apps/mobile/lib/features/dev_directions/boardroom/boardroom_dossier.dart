import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';
import '../mission_one.dart';

/// C · dossier: the kit's [Dossier] sliding across a walnut desk into the lamp's pool.
class BoardroomDossier extends StatelessWidget {
  const BoardroomDossier({super.key});

  static const ChapterGrade _grade = ChapterGrade.lobby;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Walnut, and the lamp's warm pool on it.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.6),
              radius: 1.3,
              colors: [_grade.tint, BrandColors.surface, BrandColors.void_],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        const Spotlight(center: Alignment(-0.7, -0.6), intensity: 0.4),
        const SafeArea(
          child: AnchoredScroll(
            alignment: MainAxisAlignment.center,
            padding: EdgeInsets.all(BrandSpace.lg),
            children: [
              Dossier(
                title: 'Candidate assessment',
                subtitle:
                    '${MissionOne.mission} · with ${MissionOne.interviewer}',
                scores: MissionOne.scores,
                total: MissionOne.total,
                note: MissionOne.note,
                markedIndex: MissionOne.weakestIndex,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
