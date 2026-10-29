import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../mission_one.dart';
import '../shared/cue.dart';
import '../shared/timeline.dart';

/// B · title card. The title is the set: three condensed lines built edge to edge like walls,
/// flickering on like a bad tube, with a slot of door light cut through the last line.
class ConcreteNoirTitle extends StatelessWidget {
  const ConcreteNoirTitle({super.key});

  static const CinematicDirection _d = concreteNoir;
  static const List<String> _lines = ['GET', 'THROUGH', 'THE DOOR'];

  // Each line's cue window on the 0–1 clock.
  static const List<double> _lineAt = [0.08, 0.2, 0.32];
  static const double _lineLength = 0.3;
  static const double _trackFrom = 26;

  /// The tube flicker: on/off steps for the first part of each line's cue.
  static double _flicker(double t, int seed) {
    if (t <= 0) return 0;
    if (t >= 0.5) return 1;
    final step = (t * 24).floor();
    return math.Random(seed * 97 + step).nextDouble() > 0.45 ? 1 : 0.15;
  }

  @override
  Widget build(BuildContext context) {
    final p = _d.palette;
    final type = _d.type;
    final grade = _d.lobby;
    return ColoredBox(
      color: p.void_,
      child: Timeline(
        duration: _d.motion.titleCard,
        builder: (context, t, _) {
          final door = cue(t, 0.5, 0.75, _d.motion.cutCurve);
          final meta = cue(t, 0.7, 0.85);
          return Stack(
            fit: StackFit.expand,
            children: [
              // The door: a tall slot of light, opening behind the last line.
              Align(
                alignment: const Alignment(0.42, 0.55),
                child: FractionallySizedBox(
                  widthFactor: 0.16,
                  heightFactor: 0.62 * door,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [grade.key.withValues(alpha: 0.35), grade.key],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: grade.key.withValues(alpha: 0.35 * door),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.symmetric(horizontal: BrandSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: BrandSpace.md),
                    Opacity(
                      opacity: meta,
                      child: _Slug(
                        left: 'INT. NORTHSTAR LABS — LOBBY — NIGHT',
                        right: 'M.${MissionOne.missionIndex}',
                        style: type.label,
                        rule: p.line,
                      ),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: meta,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 3,
                            child: ColoredBox(color: grade.key),
                          ),
                          const SizedBox(width: BrandSpace.sm),
                          Text(MissionOne.chapterNumber, style: type.eyebrow),
                        ],
                      ),
                    ),
                    const SizedBox(height: BrandSpace.sm),
                    Semantics(
                      header: true,
                      label:
                          '${MissionOne.chapterNumber}: ${MissionOne.chapterTitle}',
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < _lines.length; i++)
                              _TitleLine(
                                text: _lines[i],
                                t: cue(t, _lineAt[i], _lineAt[i] + _lineLength),
                                flicker: _flicker(
                                  cue(t, _lineAt[i], _lineAt[i] + _lineLength),
                                  i,
                                ),
                                style: type.titleCard.copyWith(
                                  color: i == 1 ? grade.key : null,
                                ),
                                trackFrom: _trackFrom,
                                curve: _d.motion.cutCurve,
                                first: i == 0,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: BrandSpace.lg),
                    Opacity(
                      opacity: meta,
                      child: _Slug(
                        left: MissionOne.mission.toUpperCase(),
                        right: 'WITH ${MissionOne.interviewer.toUpperCase()}',
                        style: type.label,
                        rule: p.line,
                      ),
                    ),
                    const SizedBox(height: BrandSpace.md),
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

/// One line of the title, fitted edge to edge, tracking in as it flickers on.
class _TitleLine extends StatelessWidget {
  const _TitleLine({
    required this.text,
    required this.t,
    required this.flicker,
    required this.style,
    required this.trackFrom,
    required this.curve,
    required this.first,
  });

  final String text;
  final bool first;
  final double t;
  final double flicker;
  final TextStyle style;
  final double trackFrom;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final settle = curve.transform(t);
    return Opacity(
      opacity: flicker,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          text,
          maxLines: 1,
          // The tight 0.84 line height stacks the lines like bricks; on the top line it would
          // push the caps up into the eyebrow, so the top line keeps its full ascent.
          textHeightBehavior: TextHeightBehavior(
            applyHeightToFirstAscent: !first,
          ),
          style: style.copyWith(
            letterSpacing: mix(trackFrom, style.letterSpacing!, settle),
          ),
        ),
      ),
    );
  }
}

/// A screenplay-style slug line between two hairlines.
class _Slug extends StatelessWidget {
  const _Slug({
    required this.left,
    required this.right,
    required this.style,
    required this.rule,
  });

  final String left;
  final String right;
  final TextStyle style;
  final Color rule;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: 1, child: ColoredBox(color: rule)),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: BrandSpace.sm),
        child: Row(
          children: [
            Expanded(child: Text(left, style: style)),
            const SizedBox(width: BrandSpace.sm),
            Text(right, style: style),
          ],
        ),
      ),
      SizedBox(height: 1, child: ColoredBox(color: rule)),
    ],
  );
}
