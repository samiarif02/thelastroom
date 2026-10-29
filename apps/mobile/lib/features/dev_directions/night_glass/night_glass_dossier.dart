import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/anchored_scroll.dart';
import '../shared/cue.dart';
import '../shared/haptics.dart';
import '../shared/pen_ring.dart';
import '../shared/pen_stroke.dart';
import '../shared/stamp.dart';
import '../shared/timeline.dart';

/// A · dossier. A single, very clean sheet glides onto a dark glass desk; the four scores are
/// stamped into hairline boxes, and one red ring and an italic note mark the weak line.
class NightGlassDossier extends StatelessWidget {
  const NightGlassDossier({super.key});

  static const CinematicDirection _d = nightGlass;

  /// Where on the 0–1 timeline each score is stamped, then the pen.
  static const List<double> _stampAt = [0.36, 0.44, 0.52, 0.6];
  static const double _stampLength = 0.08;
  static const double _penFrom = 0.72;

  static const Duration _length = Duration(milliseconds: 4200);

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.surface,
      child: Timeline(
        duration: _length,
        cues: [
          for (final at in _stampAt)
            (at: at + _stampLength * 0.72, fire: stampThud),
        ],
        builder: (context, t, _) {
          final slide = cue(t, 0, 0.32, _d.motion.dossierCurve);
          return Stack(
            fit: StackFit.expand,
            children: [
              // The downlight pooling on the glass desk.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.1, -0.2),
                    radius: 0.9,
                    colors: [
                      grade.key.withValues(alpha: 0.16),
                      grade.key.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: AnchoredScroll(
                  alignment: MainAxisAlignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandSpace.lg,
                    vertical: BrandSpace.xl,
                  ),
                  children: [
                    Opacity(
                      opacity: cue(slide, 0, 0.3),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          mix(
                            MediaQuery.sizeOf(context).height * 0.6,
                            0,
                            slide,
                          ),
                        ),
                        child: Transform.rotate(
                          angle: mix(-0.09, -0.018, slide),
                          child: _Sheet(t: t),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.t});

  final double t;

  static const CinematicDirection _d = nightGlass;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final ink = type.body.copyWith(color: p.ink);
    final soft = type.label.copyWith(color: p.inkSoft);
    final pen = cue(t, NightGlassDossier._penFrom, 0.9, BrandMotion.camera);
    final note = cue(t, 0.86, 1, BrandMotion.enter);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.paper,
        boxShadow: [
          BoxShadow(
            color: p.void_.withValues(alpha: 0.7),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(MissionOne.company, style: soft)),
                Text('FILE  M.${MissionOne.missionIndex}', style: soft),
              ],
            ),
            const SizedBox(height: BrandSpace.sm),
            SizedBox(height: 0.6, child: ColoredBox(color: p.inkSoft)),
            const SizedBox(height: BrandSpace.lg),
            Text(
              MissionOne.mission,
              style: type.display.copyWith(color: p.ink),
            ),
            const SizedBox(height: BrandSpace.xs),
            Text(
              'Interviewed by ${MissionOne.interviewer}, ${MissionOne.interviewerRole.toLowerCase()}',
              style: ink.copyWith(color: p.inkSoft),
            ),
            const SizedBox(height: BrandSpace.lg),
            for (var row = 0; row < 2; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: BrandSpace.md),
                child: Row(
                  children: [
                    for (var col = 0; col < 2; col++) ...[
                      if (col > 0) const SizedBox(width: BrandSpace.md),
                      Expanded(
                        child: _ScoreCell(index: row * 2 + col, t: t),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: BrandSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('OVERALL', style: soft)),
                Text(
                  '${MissionOne.total}',
                  style: type.score.copyWith(fontSize: 56),
                ),
              ],
            ),
            const SizedBox(height: BrandSpace.md),
            SizedBox(height: 0.6, child: ColoredBox(color: p.inkSoft)),
            const SizedBox(height: BrandSpace.md),
            Text('WEAKEST LINE', style: soft),
            const SizedBox(height: BrandSpace.xs),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(MissionOne.weakLine, style: ink),
                Positioned.fill(
                  child: PenStroke(
                    t: pen,
                    color: p.redPen,
                    width: 1.6,
                    path: _underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BrandSpace.sm),
            Opacity(
              opacity: note,
              child: Transform.rotate(
                angle: -0.035,
                alignment: Alignment.centerLeft,
                child: Text(MissionOne.note, style: type.note),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A quick, slightly wavering pen underline.
  static Path _underline(Size s) => Path()
    ..moveTo(0, s.height + 2)
    ..cubicTo(
      s.width * 0.3,
      s.height + 4,
      s.width * 0.6,
      s.height,
      s.width * 0.92,
      s.height + 3,
    );
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.index, required this.t});

  final int index;
  final double t;

  static const CinematicDirection _d = nightGlass;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final score = MissionOne.scores[index];
    final at = NightGlassDossier._stampAt[index];
    final stamp = cue(t, at, at + NightGlassDossier._stampLength);
    final weakest = index == MissionOne.weakestIndex;
    final ring = cue(
      t,
      NightGlassDossier._penFrom - 0.06,
      NightGlassDossier._penFrom + 0.08,
      BrandMotion.camera,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          score.dimension.toUpperCase(),
          style: type.label.copyWith(color: p.inkSoft),
        ),
        const SizedBox(height: BrandSpace.xs),
        Stack(
          clipBehavior: Clip.none,
          children: [
            StampIn(
              t: stamp,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: p.ink, width: 0.8),
                ),
                child: Text('${score.value}', style: type.score),
              ),
            ),
            if (weakest)
              Positioned(
                left: -10,
                top: -10,
                right: -10,
                bottom: -10,
                child: PenStroke(
                  t: ring,
                  color: p.redPen,
                  width: 1.8,
                  path: _ring,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Path _ring(Size s) => penRing(Offset.zero & s);
}
