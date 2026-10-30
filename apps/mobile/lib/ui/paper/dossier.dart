import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../film/cue.dart';
import '../film/timeline.dart';
import '../haptics.dart';
import '../ornament/brass.dart';
import 'pen.dart';
import 'stamp_in.dart';
import 'wax_seal.dart';

/// One stamped line in the dossier's ledger.
@immutable
class DossierScore {
  const DossierScore({required this.label, required this.value});

  /// The dimension: "Relevance".
  final String label;

  /// 0–100.
  final int value;
}

/// The debrief as a candidate file: heavy cream letterhead slides across the desk into the
/// lamp's pool, each score is stamped into the ledger, the total is sealed in oxblood wax, and
/// a fountain pen underlines the weakest line and writes a note in the margin.
///
/// Beats for sound and haptics (brief 09/10): [onStamp] per score, [onSeal], [onPen] as the pen
/// touches paper, then [onFinished]. Stamps and the seal thud (haptics) by themselves. Under
/// reduced motion the file is already on the desk, settled; no beats fire but [onFinished].
///
/// It's only the sheet: put it on a desk (and in a scroll view, for 2x text) yourself.
class Dossier extends StatelessWidget {
  const Dossier({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scores,
    required this.total,
    this.letterhead = 'NORTHSTAR LABS',
    this.monogram = 'N',
    this.totalLabel = 'OVERALL',
    this.note,
    this.markedIndex,
    this.play = true,
    this.onStamp,
    this.onSeal,
    this.onPen,
    this.onFinished,
  });

  /// "Candidate assessment".
  final String title;

  /// "The Opportunity · with Priya".
  final String subtitle;
  final List<DossierScore> scores;
  final int total;

  /// The company line under the monogram.
  final String letterhead;
  final String monogram;
  final String totalLabel;

  /// The pen's note in the margin. Null: the pen stays capped.
  final String? note;

  /// The ledger line the pen underlines (the weakest).
  final int? markedIndex;
  final bool play;
  final ValueChanged<int>? onStamp;
  final VoidCallback? onSeal;
  final VoidCallback? onPen;
  final VoidCallback? onFinished;

  // The cue sheet, as shares of [BrandMotion.dossier].
  static const double _slideEnd = 0.3;
  static const double _stampsFrom = 0.34;
  static const double _stampsSpan = 0.21;
  static const double _stampLength = 0.07;
  static const double _sealAt = 0.64;
  static const double _sealLength = 0.1;
  static const double _penFrom = 0.76;
  static const double _penTo = 0.92;
  static const double _noteFrom = 0.84;

  static const double _tiltFrom = 0.12;
  static const double _tiltTo = 0.02;

  /// When score [i] of [n] starts to drop.
  static double stampAt(int i, int n) =>
      _stampsFrom +
      i * math.min(_stampLength, _stampsSpan / math.max(1, n - 1));

  @override
  Widget build(BuildContext context) {
    const hit = StampIn.hitAt;
    return Timeline(
      duration: BrandMotion.dossier,
      play: play,
      onFinished: onFinished,
      cues: [
        for (var i = 0; i < scores.length; i++)
          (
            at: stampAt(i, scores.length) + _stampLength * hit,
            fire: () {
              stampThud();
              onStamp?.call(i);
            },
          ),
        (
          at: _sealAt + _sealLength * hit,
          fire: () {
            stampThud();
            onSeal?.call();
          },
        ),
        if (note != null || markedIndex != null)
          (at: _penFrom, fire: () => onPen?.call()),
      ],
      builder: (context, t, _) {
        final slide = cue(t, 0, _slideEnd, BrandMotion.paperSlide);
        return Opacity(
          opacity: cue(slide, 0, 0.4),
          child: Transform.translate(
            offset: Offset(mix(MediaQuery.sizeOf(context).width, 0, slide), 0),
            child: Transform.rotate(
              angle: mix(_tiltFrom, _tiltTo, slide),
              child: _Letterhead(dossier: this, t: t),
            ),
          ),
        );
      },
    );
  }
}

class _Letterhead extends StatelessWidget {
  const _Letterhead({required this.dossier, required this.t});

  final Dossier dossier;
  final double t;

  static const double _monogram = 40;
  static const double _monogramSize = 24;
  static const double _titleSize = 30;
  static const double _shadowBlur = 30;
  static const Offset _shadowOffset = Offset(-8, 20);
  static const double _sealAngle = -0.12;

  @override
  Widget build(BuildContext context) {
    final d = dossier;
    final seal = cue(t, Dossier._sealAt, Dossier._sealAt + Dossier._sealLength);
    final pen = cue(t, Dossier._penFrom, Dossier._penTo, BrandMotion.camera);
    final note = cue(t, Dossier._noteFrom, 1, BrandMotion.enter);
    final soft = BrandType.label.copyWith(color: BrandColors.inkSoft);
    return DecoratedBox(
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
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _monogram,
                height: _monogram,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: BrandColors.inkSoft, width: 0.8),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    d.monogram,
                    style: BrandType.display.copyWith(
                      color: BrandColors.ink,
                      fontSize: _monogramSize,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BrandSpace.sm),
            Text(d.letterhead, textAlign: TextAlign.center, style: soft),
            const SizedBox(height: BrandSpace.md),
            Semantics(
              header: true,
              child: Text(
                d.title,
                textAlign: TextAlign.center,
                style: BrandType.display.copyWith(
                  color: BrandColors.ink,
                  fontSize: _titleSize,
                ),
              ),
            ),
            Text(
              d.subtitle,
              textAlign: TextAlign.center,
              style: BrandType.body.copyWith(color: BrandColors.inkSoft),
            ),
            const SizedBox(height: BrandSpace.md),
            const DoubleRule(color: BrandColors.inkSoft),
            for (var i = 0; i < d.scores.length; i++)
              _LedgerRow(
                score: d.scores[i],
                stamp: cue(
                  t,
                  Dossier.stampAt(i, d.scores.length),
                  Dossier.stampAt(i, d.scores.length) + Dossier._stampLength,
                ),
                pen: i == d.markedIndex ? pen : null,
              ),
            const DoubleRule(color: BrandColors.inkSoft),
            const SizedBox(height: BrandSpace.md),
            Row(
              children: [
                Expanded(
                  child: d.note == null
                      ? const SizedBox.shrink()
                      : PenNote(text: d.note!, t: note),
                ),
                const SizedBox(width: BrandSpace.sm),
                StampIn(
                  t: seal,
                  angle: _sealAngle,
                  child: WaxSeal(value: d.total, label: d.totalLabel),
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
  const _LedgerRow({required this.score, required this.stamp, this.pen});

  final DossierScore score;

  /// The stamp's progress.
  final double stamp;

  /// The pen's progress if this is the marked line.
  final double? pen;

  static const double _labelSize = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${score.label}: ${score.value} out of 100',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    score.label,
                    style: BrandType.display.copyWith(
                      fontSize: _labelSize,
                      color: BrandColors.ink,
                    ),
                  ),
                  if (pen case final p?)
                    Positioned.fill(
                      child: PenStroke(t: p, path: PenStroke.underline),
                    ),
                ],
              ),
            ),
            StampIn(
              t: stamp,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${score.value}', style: BrandType.score),
                    TextSpan(
                      text: ' /100',
                      style: BrandType.label.copyWith(
                        color: BrandColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
