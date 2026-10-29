import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/anchored_scroll.dart';
import '../shared/cue.dart';
import '../shared/haptics.dart';
import '../shared/pen_stroke.dart';
import '../shared/stamp.dart';
import '../shared/timeline.dart';

/// C · dossier. Heavy cream letterhead slides across a walnut desk into the lamp's pool. The
/// scores are set like a ledger, the total is sealed in oxblood, and a fountain pen writes in
/// the margin.
class BoardroomDossier extends StatelessWidget {
  const BoardroomDossier({super.key});

  static const CinematicDirection _d = boardroom;

  static const List<double> _stampAt = [0.34, 0.41, 0.48, 0.55];
  static const double _stampLength = 0.07;
  static const double _sealAt = 0.64;
  static const double _penFrom = 0.76;

  static const Duration _length = Duration(milliseconds: 4600);

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
          (at: _sealAt + 0.1 * 0.72, fire: stampThud),
        ],
        builder: (context, t, _) {
          final slide = cue(t, 0, 0.3, _d.motion.dossierCurve);
          return Stack(
            fit: StackFit.expand,
            children: [
              // Walnut, and the lamp's warm pool on it.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.6),
                    radius: 1.3,
                    colors: [grade.tint, p.surface, p.void_],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
              SafeArea(
                child: AnchoredScroll(
                  alignment: MainAxisAlignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandSpace.lg,
                    vertical: BrandSpace.lg,
                  ),
                  children: [
                    Opacity(
                      opacity: cue(slide, 0, 0.4),
                      child: Transform.translate(
                        offset: Offset(
                          mix(MediaQuery.sizeOf(context).width, 0, slide),
                          0,
                        ),
                        child: Transform.rotate(
                          angle: mix(0.12, 0.02, slide),
                          child: _Letterhead(t: t),
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

class _Letterhead extends StatelessWidget {
  const _Letterhead({required this.t});

  final double t;

  static const CinematicDirection _d = boardroom;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final ink = type.body.copyWith(color: p.ink);
    final soft = type.label.copyWith(color: p.inkSoft);
    final seal = cue(
      t,
      BoardroomDossier._sealAt,
      BoardroomDossier._sealAt + 0.1,
    );
    final pen = cue(t, BoardroomDossier._penFrom, 0.92, BrandMotion.camera);
    final note = cue(t, 0.84, 1, BrandMotion.enter);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.paper,
        boxShadow: [
          BoxShadow(
            color: p.void_.withValues(alpha: 0.8),
            blurRadius: 30,
            offset: const Offset(-8, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The monogram.
            Center(
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.inkSoft, width: 0.8),
                ),
                child: Text(
                  'N',
                  style: type.display.copyWith(color: p.ink, fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: BrandSpace.sm),
            Text(MissionOne.company, textAlign: TextAlign.center, style: soft),
            const SizedBox(height: BrandSpace.md),
            Text(
              'Candidate assessment',
              textAlign: TextAlign.center,
              style: type.display.copyWith(color: p.ink, fontSize: 30),
            ),
            Text(
              '${MissionOne.mission} · with ${MissionOne.interviewer}',
              textAlign: TextAlign.center,
              style: ink.copyWith(color: p.inkSoft),
            ),
            const SizedBox(height: BrandSpace.md),
            _DoubleRule(color: p.inkSoft),
            for (var i = 0; i < MissionOne.scores.length; i++)
              _LedgerRow(index: i, t: t, pen: pen),
            _DoubleRule(color: p.inkSoft),
            const SizedBox(height: BrandSpace.md),
            Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: note,
                    child: Transform.rotate(
                      angle: -0.05,
                      alignment: Alignment.centerLeft,
                      child: Text(MissionOne.note, style: type.note),
                    ),
                  ),
                ),
                const SizedBox(width: BrandSpace.sm),
                StampIn(
                  t: seal,
                  angle: -0.12,
                  child: _Seal(value: MissionOne.total, palette: p, type: type),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.index, required this.t, required this.pen});

  final int index;
  final double t;
  final double pen;

  static const CinematicDirection _d = boardroom;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final score = MissionOne.scores[index];
    final at = BoardroomDossier._stampAt[index];
    final weakest = index == MissionOne.weakestIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  score.dimension,
                  style: type.display.copyWith(fontSize: 22, color: p.ink),
                ),
                if (weakest)
                  Positioned.fill(
                    child: PenStroke(
                      t: pen,
                      color: p.redPen,
                      width: 1.4,
                      path: (s) => Path()
                        ..moveTo(-2, s.height - 2)
                        ..cubicTo(
                          s.width * 0.2,
                          s.height + 2,
                          s.width * 0.5,
                          s.height - 1,
                          s.width * 0.75,
                          s.height + 1,
                        ),
                    ),
                  ),
              ],
            ),
          ),
          StampIn(
            t: cue(t, at, at + BoardroomDossier._stampLength),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${score.value}',
                    style: type.score.copyWith(fontSize: 34),
                  ),
                  TextSpan(
                    text: ' /100',
                    style: type.label.copyWith(color: p.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleRule extends StatelessWidget {
  const _DoubleRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 0.8,
        width: double.infinity,
        child: ColoredBox(color: color),
      ),
      const SizedBox(height: 2),
      SizedBox(
        height: 0.4,
        width: double.infinity,
        child: ColoredBox(color: color),
      ),
    ],
  );
}

/// A wax seal in oxblood with the total pressed into it.
class _Seal extends StatelessWidget {
  const _Seal({required this.value, required this.palette, required this.type});

  final int value;
  final DirectionPalette palette;
  final DirectionType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.redPen,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: palette.paper.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        // The seal is a fixed size; at large text sizes its contents shrink to fit it.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: type.score.copyWith(color: palette.paper, fontSize: 30),
              ),
              Text(
                'OVERALL',
                style: type.label.copyWith(
                  color: palette.paper,
                  fontSize: 7,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
