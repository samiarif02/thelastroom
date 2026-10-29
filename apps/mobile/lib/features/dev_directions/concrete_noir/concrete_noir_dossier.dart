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

/// B · dossier. A manila case file is thrown onto a black desk under a hard lamp. Four scores
/// are stamped into ruled boxes, UNDER REVIEW slams across it, and a red marker rings the
/// weakest score.
class ConcreteNoirDossier extends StatelessWidget {
  const ConcreteNoirDossier({super.key});

  static const CinematicDirection _d = concreteNoir;

  static const List<double> _stampAt = [0.24, 0.31, 0.38, 0.45];
  static const double _stampLength = 0.06;
  static const double _reviewAt = 0.56;
  static const double _markerFrom = 0.7;

  static const Duration _length = Duration(milliseconds: 3600);

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.void_,
      child: Timeline(
        duration: _length,
        cues: [
          for (final at in _stampAt)
            (at: at + _stampLength * 0.72, fire: stampThud),
          (at: _reviewAt + 0.08 * 0.72, fire: stampThud),
        ],
        builder: (context, t, _) {
          final slide = cue(t, 0, 0.2, _d.motion.dossierCurve);
          return Stack(
            fit: StackFit.expand,
            children: [
              // A hard lamp straight down on the desk.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.75,
                    colors: [
                      grade.key.withValues(alpha: 0.22),
                      grade.key.withValues(alpha: 0),
                    ],
                    stops: const [0.2, 1],
                  ),
                ),
              ),
              SafeArea(
                child: AnchoredScroll(
                  alignment: MainAxisAlignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandSpace.md,
                    vertical: BrandSpace.lg,
                  ),
                  children: [
                    Transform.translate(
                      offset: Offset(
                        mix(-MediaQuery.sizeOf(context).width * 1.2, 0, slide),
                        0,
                      ),
                      child: Transform.rotate(
                        angle: mix(-0.25, 0.025, slide),
                        child: _File(t: t),
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

class _File extends StatelessWidget {
  const _File({required this.t});

  final double t;

  static const CinematicDirection _d = concreteNoir;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final typed = type.body.copyWith(color: p.ink, fontWeight: FontWeight.w600);
    final field = type.label.copyWith(color: p.inkSoft);
    final review = cue(
      t,
      ConcreteNoirDossier._reviewAt,
      ConcreteNoirDossier._reviewAt + 0.08,
    );
    final note = cue(t, 0.86, 0.98);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The folder tab.
            Container(
              padding: const EdgeInsets.fromLTRB(
                BrandSpace.md,
                6,
                BrandSpace.md,
                4,
              ),
              color: p.paper,
              child: Text(
                'CASE Nº ${MissionOne.missionIndex} — ${MissionOne.interviewer.toUpperCase()}',
                style: field.copyWith(color: p.ink),
              ),
            ),
            Container(
              width: double.infinity,
              color: p.paper,
              padding: const EdgeInsets.all(BrandSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CANDIDATE FILE',
                    style: type.display.copyWith(color: p.ink, fontSize: 52),
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  _Field(
                    label: 'SUBJECT',
                    value: 'You',
                    labelStyle: field,
                    valueStyle: typed,
                  ),
                  _Field(
                    label: 'INTERVIEW',
                    value:
                        '${MissionOne.mission} / ${MissionOne.interviewer}, ${MissionOne.interviewerRole.toLowerCase()}',
                    labelStyle: field,
                    valueStyle: typed,
                  ),
                  _Field(
                    label: 'REFERENCE',
                    value: '',
                    labelStyle: field,
                    valueStyle: typed,
                    redacted: p.ink,
                  ),
                  const SizedBox(height: BrandSpace.md),
                  for (var row = 0; row < 2; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 2; col++)
                          Expanded(
                            child: _ScoreBox(index: row * 2 + col, t: t),
                          ),
                      ],
                    ),
                  const SizedBox(height: BrandSpace.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text('WEAKEST LINE', style: field)),
                      Text('TOTAL ', style: field),
                      Text(
                        '${MissionOne.total}',
                        style: type.score.copyWith(fontSize: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: BrandSpace.xs),
                  Text(MissionOne.weakLine, style: typed),
                  const SizedBox(height: BrandSpace.sm),
                  Opacity(
                    opacity: note,
                    child: Text(
                      MissionOne.note.toUpperCase(),
                      style: type.note,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: -BrandSpace.xs,
          top: -BrandSpace.md,
          child: StampIn(
            t: review,
            angle: -0.2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: p.redPen, width: 3),
              ),
              child: Text(
                'UNDER REVIEW',
                style: type.stamp.copyWith(fontSize: 26, letterSpacing: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.redacted,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  /// A redaction bar instead of the value.
  final Color? redacted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BrandSpace.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 92, child: Text(label, style: labelStyle)),
        Expanded(
          child: redacted == null
              ? Text(value, style: valueStyle)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 150,
                    height: 14,
                    child: ColoredBox(color: redacted!),
                  ),
                ),
        ),
      ],
    ),
  );
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.index, required this.t});

  final int index;
  final double t;

  static const CinematicDirection _d = concreteNoir;

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final score = MissionOne.scores[index];
    final at = ConcreteNoirDossier._stampAt[index];
    final stamp = cue(t, at, at + ConcreteNoirDossier._stampLength);
    final weakest = index == MissionOne.weakestIndex;
    final marker = cue(
      t,
      ConcreteNoirDossier._markerFrom,
      ConcreteNoirDossier._markerFrom + 0.14,
      BrandMotion.camera,
    );
    return Container(
      decoration: BoxDecoration(border: Border.all(color: p.ink, width: 1.5)),
      padding: const EdgeInsets.all(BrandSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score.dimension.toUpperCase(),
            style: type.display.copyWith(fontSize: 18, color: p.ink),
          ),
          const SizedBox(height: BrandSpace.xs),
          Stack(
            clipBehavior: Clip.none,
            children: [
              StampIn(
                t: stamp,
                angle: index.isEven ? -0.03 : 0.025,
                child: Text('${score.value}', style: type.score),
              ),
              if (weakest)
                Positioned(
                  left: -12,
                  top: -8,
                  width: 84,
                  bottom: -8,
                  child: PenStroke(
                    t: marker,
                    color: p.redPen,
                    width: 3.2,
                    path: (s) => penRing(Offset.zero & s, sweep: 6.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
