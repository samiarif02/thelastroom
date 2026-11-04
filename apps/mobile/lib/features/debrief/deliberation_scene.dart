import 'dart:async';
import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';

import '../../ui/daylight/daylight_kit.dart';
import 'debrief_facts.dart';

/// What the recruiter is doing with the answer: reading a chosen one, or listening to a spoken
/// one. Only the words change; the scene is the same.
enum DeliberationKind { reading, listening }

/// While the AI recruiter scores (the owner, 4 Nov: "show the character who is scoring, like
/// checking the file"): the room's interviewer at the desk in the `thinking` face, the candidate
/// file on a clipboard in front of them. A honey highlight runs along the answer as they read,
/// a pen ticks the four skills one by one, writes a line, and the page turns; then again. The
/// words under it follow the same beats in the interviewer's name, and past [longAfter] add
/// [almost], so a slow verdict never feels stuck.
///
/// Reduced motion: one still frame (three skills ticked, the pen on the fourth) and the first
/// line. A screen reader hears [announce] once, politely.
class DeliberationScene extends StatefulWidget {
  const DeliberationScene({
    super.key,
    required this.person,
    this.grade = ChapterGrade.lobby,
    this.kind = DeliberationKind.reading,
  });

  final CastPerson person;
  final ChapterGrade grade;
  final DeliberationKind kind;

  static const String announce = 'The recruiter is scoring your answer';
  static const String readingLine =
      'A senior recruiter is reading your answer and your reasons.';
  static const String listeningLine =
      'Your answer is being transcribed and scored on what you said. If it takes too long, '
      "you'll tick your own points instead.";
  static const String almost = 'Almost there…';
  static const String fileLabel = 'Candidate file';
  static const String scoringTag = 'Scoring';

  /// The three beats, in [name]'s voice.
  static List<String> steps(String name, DeliberationKind kind) => [
    switch (kind) {
      DeliberationKind.reading => '$name is reading your answer…',
      DeliberationKind.listening => '$name is listening to your answer…',
    },
    switch (kind) {
      DeliberationKind.reading => '$name is weighing your reasons…',
      DeliberationKind.listening => '$name is weighing what you said…',
    },
    '$name is writing it up…',
  ];

  /// When [almost] joins the words.
  static const Duration longAfter = Duration(seconds: 4);

  /// One pass of the file: read, tick, write, turn.
  static const Duration period = Duration(seconds: 6);

  @override
  State<DeliberationScene> createState() => _DeliberationSceneState();
}

/// Where each beat sits in one pass (0 → 1).
abstract final class _Beat {
  static const double readTo = 0.3;
  static const double tickFrom = 0.3;
  static const double tickEach = 0.105;
  static const double writeFrom = 0.72;
  static const double writeTo = 0.88;
  static const double turnFrom = 0.9;

  /// The reduced-motion frame: three skills ticked, the pen on the fourth.
  static const double still = 0.652;

  static double span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  /// Which words show at [t]: reading, weighing, writing.
  static int step(double t) => t < tickFrom ? 0 : (t < writeFrom ? 1 : 2);
}

class _DeliberationSceneState extends State<DeliberationScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pass = AnimationController(
    vsync: this,
    duration: DeliberationScene.period,
  )..addListener(_stepped);
  late final Timer _long = Timer(DeliberationScene.longAfter, () {
    if (mounted) setState(() => _slow = true);
  });
  bool _slow = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _long;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pass
        ..stop()
        ..value = _Beat.still;
      _step = 0;
    } else if (!_pass.isAnimating) {
      unawaited(_pass.repeat());
    }
  }

  void _stepped() {
    if (!_pass.isAnimating) return;
    final step = _Beat.step(_pass.value);
    if (step != _step) setState(() => _step = step);
  }

  @override
  void dispose() {
    _long.cancel();
    _pass.dispose();
    super.dispose();
  }

  static const double _maxWidth = 360;
  static const double _stage = RoomStage.defaultHeight;

  /// How far the clipboard rises over the desk.
  static const double _overlap = 48;
  static const double _tilt = -0.03;

  @override
  Widget build(BuildContext context) {
    final f = widget.grade.floor;
    final steps = DeliberationScene.steps(widget.person.name, widget.kind);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: DeliberationScene.announce,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: _stage,
                    child: RoomStage(
                      person: widget.person,
                      expression: CastController.forCue(CastCue.awaitingScore),
                      floor: f,
                      overlays: const [
                        Positioned(
                          left: DaylightSpace.s12,
                          top: DaylightSpace.s12,
                          child: Tag(
                            label: DeliberationScene.scoringTag,
                            icon: PhosphorBold.notebook,
                            tone: TagTone.raised,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DaylightSpace.s32,
                      _stage - _overlap,
                      DaylightSpace.s32,
                      0,
                    ),
                    child: Transform.rotate(
                      angle: _tilt,
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1,
                        child: AnimatedBuilder(
                          animation: _pass,
                          builder: (context, _) =>
                              _Clipboard(t: _pass.value, floor: f),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DaylightSpace.s24),
            ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: still ? Duration.zero : DaylightMotion.colour,
                // The old words go at once and the new fade in: never two lines on top of
                // each other.
                switchOutCurve: const Threshold(1),
                child: Text(
                  steps[_step],
                  key: ValueKey(_step),
                  textAlign: TextAlign.center,
                  style: DaylightType.heading6,
                ),
              ),
            ),
            const SizedBox(height: DaylightSpace.s8),
            Text(
              switch (widget.kind) {
                DeliberationKind.reading => DeliberationScene.readingLine,
                DeliberationKind.listening => DeliberationScene.listeningLine,
              },
              textAlign: TextAlign.center,
              style: DaylightType.body6.copyWith(color: DaylightColors.ink2),
            ),
            const SizedBox(height: DaylightSpace.s12),
            // Laid out from the start, so nothing moves when it shows.
            AnimatedOpacity(
              opacity: _slow ? 1 : 0,
              duration: still ? Duration.zero : DaylightMotion.move,
              curve: DaylightMotion.ease,
              child: Text(
                DeliberationScene.almost,
                textAlign: TextAlign.center,
                style: DaylightType.caption3.copyWith(color: f.deep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The clipboard: a board in the floor's colour, a honey clip, and the page. In the turn the
/// written page lifts away over the clip and a fresh one is under it.
class _Clipboard extends StatelessWidget {
  const _Clipboard({required this.t, required this.floor});

  final double t;
  final FloorColours floor;

  static const double _board = DaylightSpace.s8;
  static const double _clipW = 64;
  static const double _clipH = 16;
  static const double _perspective = 0.0016;
  static const double _turnShade = 0.18;

  @override
  Widget build(BuildContext context) {
    final turn = _Beat.span(t, _Beat.turnFrom, 1);
    final turning = turn > 0 && turn < 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: floor.base,
            borderRadius: BorderRadius.circular(DaylightRadius.tile),
            boxShadow: DaylightElevation.lift,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _board,
              _board + DaylightSpace.s4,
              _board,
              _board,
            ),
            child: Stack(
              children: [
                // The fresh page under the one being turned.
                _Page(t: turning ? 0 : t, floor: floor),
                if (turning)
                  Positioned.fill(
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _perspective)
                        ..rotateX(turn * math.pi / 2),
                      child: Opacity(
                        opacity: 1 - turn * 0.5,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _Page(t: t, floor: floor),
                            ColoredBox(
                              color: DaylightColors.shadow.withValues(
                                alpha: turn * _turnShade,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The clip holds the page at the top.
        Positioned(
          top: -_clipH / 2,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: _clipW,
              height: _clipH,
              decoration: BoxDecoration(
                color: DaylightColors.honey,
                borderRadius: BorderRadius.circular(DaylightRadius.tag),
                boxShadow: DaylightElevation.edgeOf(
                  DaylightColors.honeyEdge,
                  depth: DaylightSpace.s2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One page of the file at [t]: the answer (highlighted as it's read), the four skills (ticked
/// one by one), and the line being written.
class _Page extends StatelessWidget {
  const _Page({required this.t, required this.floor});

  final double t;
  final FloorColours floor;

  /// The answer's printed lines, as fractions of the width.
  static const List<double> _lines = [0.94, 0.82, 0.58];

  @override
  Widget build(BuildContext context) {
    final read = _Beat.span(t, 0, _Beat.readTo);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DaylightColors.raised,
        borderRadius: BorderRadius.circular(DaylightRadius.inner),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DaylightSpace.s16,
          DaylightSpace.s16,
          DaylightSpace.s16,
          DaylightSpace.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DeliberationScene.fileLabel,
              style: DaylightType.caption3.copyWith(color: DaylightColors.ink2),
            ),
            const SizedBox(height: DaylightSpace.s8),
            for (final (i, width) in _lines.indexed) ...[
              if (i > 0) const SizedBox(height: DaylightSpace.s4),
              _AnswerLine(
                width: width,
                read: (read * _lines.length - i).clamp(0.0, 1.0),
              ),
            ],
            const SizedBox(height: DaylightSpace.s12),
            for (final (i, d) in Dimension.values.indexed)
              _SkillRow(
                label: dimensionLabel(d),
                tick: _Beat.span(
                  t,
                  _Beat.tickFrom + i * _Beat.tickEach,
                  _Beat.tickFrom + (i + 1) * _Beat.tickEach,
                ),
                floor: floor,
              ),
            const SizedBox(height: DaylightSpace.s8),
            SizedBox(
              height: DaylightSpace.s16,
              child: CustomPaint(
                painter: _ScribblePainter(
                  written: _Beat.span(t, _Beat.writeFrom, _Beat.writeTo),
                  ink: floor.deep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A printed line of the answer, with the reader's honey highlight run along [read] of it.
class _AnswerLine extends StatelessWidget {
  const _AnswerLine({required this.width, required this.read});

  final double width;
  final double read;

  static const double _height = 6;
  static const double _highlight = 0.55;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: DaylightColors.sand2,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: read,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DaylightColors.honey.withValues(alpha: _highlight),
              borderRadius: BorderRadius.circular(_height / 2),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A skill on the file and its box; [tick] runs the pen in, draws the check and lifts it.
class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.label,
    required this.tick,
    required this.floor,
  });

  final String label;
  final double tick;
  final FloorColours floor;

  static const double _box = 16;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DaylightSpace.s2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DaylightType.body6.copyWith(color: DaylightColors.ink),
          ),
        ),
        SizedBox.square(
          dimension: _box,
          child: CustomPaint(
            painter: _TickPainter(tick: tick, ink: floor.deep),
          ),
        ),
      ],
    ),
  );
}

/// The pen: a nib at the point, the body up and to the right, a honey band near the end.
void _paintPen(Canvas canvas, Offset nib, double opacity) {
  if (opacity <= 0) return;
  const length = 30.0;
  const width = 5.0;
  const tipLength = 6.0;
  canvas
    ..save()
    ..translate(nib.dx, nib.dy)
    ..rotate(-math.pi / 4);
  final body = Paint()..color = DaylightColors.ink.withValues(alpha: opacity);
  final band = Paint()..color = DaylightColors.honey.withValues(alpha: opacity);
  canvas
    ..drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(tipLength, -width / 2)
        ..lineTo(tipLength, width / 2)
        ..close(),
      body,
    )
    ..drawRRect(
      RRect.fromLTRBR(
        tipLength,
        -width / 2,
        length,
        width / 2,
        const Radius.circular(width / 2),
      ),
      body,
    )
    ..drawRect(
      const Rect.fromLTRB(length - 9, -width / 2, length - 6, width / 2),
      band,
    )
    ..restore();
}

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.tick, required this.ink});

  final double tick;
  final Color ink;

  static const double _approach = 0.35;
  static const double _drawn = 0.85;
  static const double _stroke = 2.2;

  /// The check, in a 16 box.
  static const List<Offset> _check = [
    Offset(3.5, 8.5),
    Offset(6.8, 11.8),
    Offset(12.8, 4.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(DaylightRadius.tag / 2),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = DaylightColors.sand2,
    );
    if (tick <= 0) return;
    final drawn = _Beat.span(tick, _approach, _drawn);
    final points = [for (final p in _check) p * k];
    final first = (points[1] - points[0]).distance;
    final second = (points[2] - points[1]).distance;
    final along = drawn * (first + second);
    final tip = along <= first
        ? Offset.lerp(points[0], points[1], along / first)!
        : Offset.lerp(points[1], points[2], (along - first) / second)!;
    if (drawn > 0) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      if (along <= first) {
        path.lineTo(tip.dx, tip.dy);
      } else {
        path
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(tip.dx, tip.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke * k
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ink,
      );
    }
    // The pen comes in from above right, follows the stroke, and lifts away.
    if (tick < 1) {
      const away = Offset(14, -14);
      if (tick < _approach) {
        final a = tick / _approach;
        _paintPen(canvas, points[0] + away * (1 - a), a);
      } else if (tick < _drawn) {
        _paintPen(canvas, tip, 1);
      } else {
        final l = (tick - _drawn) / (1 - _drawn);
        _paintPen(canvas, points[2] + away * l, 1 - l);
      }
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.tick != tick || old.ink != ink;
}

/// The line the recruiter writes under the skills: a hand's wave, the pen at its end.
class _ScribblePainter extends CustomPainter {
  const _ScribblePainter({required this.written, required this.ink});

  final double written;
  final Color ink;

  static const double _reach = 0.72;
  static const double _waves = 9;
  static const double _lift = 2.2;
  static const int _steps = 60;

  @override
  void paint(Canvas canvas, Size size) {
    if (written <= 0) return;
    final mid = size.height / 2;
    final end = size.width * _reach * written;
    Offset at(double x) => Offset(
      x,
      mid + math.sin(x / size.width * _waves * math.pi * 2) * _lift,
    );
    final path = Path()..moveTo(0, at(0).dy);
    for (var i = 1; i <= _steps; i++) {
      final p = at(end * i / _steps);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
    if (written < 1) _paintPen(canvas, at(end), 1);
  }

  @override
  bool shouldRepaint(_ScribblePainter old) =>
      old.written != written || old.ink != ink;
}
