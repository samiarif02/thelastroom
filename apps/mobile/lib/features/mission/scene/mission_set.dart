import 'dart:math' as math;

import 'package:brand/brand.dart';
import 'package:flutter/widgets.dart';

import '../../../ui/film_kit.dart';

/// The three framings the mission scene uses.
enum SceneShot {
  /// The room, before the question.
  wide,

  /// After the dolly push: the interviewer's head and shoulders in the upper half.
  close,

  /// The follow-up's hard cut: tighter, and higher, so the reply cards still fit beneath.
  tight,
}

/// The Boardroom set, framed for the mission player. The back and front planes are the kit's
/// ([BoardroomSet]); the middle plane (the interviewer in the lamp's pool) is placed here, so
/// [faceRect] knows exactly where the face is in every frame and the subtitles can be laid out
/// beneath it, never over it (owner's fix 1, 2026-10-30).
abstract final class MissionSet {
  /// The wide shot lifts the whole set a little, so the face sits clear of the subtitles before
  /// the push as well as after it. The strip it uncovers is under the desk, in shadow, and
  /// behind the letterbox bar.
  static const CameraShot wide = CameraShot(target: Alignment(0, -0.2));

  // The close-ups are the kit's framings carried higher in frame by [_lift], every plane by
  // the same amount so the interviewer stays seated behind the desk: the lower half is the
  // subtitles' and the answer cards', and on a small phone it needs every line it can get.
  static const double _lift = 0.31;

  static CameraShot _lifted(CameraShot shot) => CameraShot(
    scale: shot.scale,
    focus: shot.focus,
    target: Alignment(shot.target.x, shot.target.y - _lift),
  );

  static final CameraShot _backClose = _lifted(BoardroomSet.backClose);
  static final CameraShot _middleClose = _lifted(BoardroomSet.middleClose);
  static final CameraShot _frontClose = _lifted(BoardroomSet.frontClose);

  /// The follow-up's hard cut: tighter than the close-up, with the chin no lower on screen,
  /// so the reply cards fit beneath it as the beats' cards did.
  static const CameraShot tight = CameraShot(
    scale: 2,
    focus: Alignment(0.03, -0.12),
    target: Alignment(0, -0.6),
  );

  static const CameraShot _backTight = CameraShot(
    scale: 1.3,
    focus: Alignment(0, -0.2),
    target: Alignment(0, -0.5),
  );

  /// The figure is this share of the set's width.
  static const double figureWidth = 0.5;

  /// This share of the figure is hidden below the desk line.
  static const double sunk = 0.12;

  /// The face (head and hair) in the figure's design units: the union of every figure's head,
  /// with a little air, so one box serves Priya and Marcus.
  static const Rect faceInDesign = Rect.fromLTRB(29, 18, 72, 69);

  /// The figure's box in the set (before the camera), for a set of [size].
  static Rect figureRect(Size size) {
    final w = size.width * figureWidth;
    final h = w / SilhouetteFigure.aspectRatio;
    final deskY = size.height * BoardroomSet.deskLine;
    return Rect.fromLTWH((size.width - w) / 2, deskY - h + h * sunk, w, h);
  }

  /// The face in the set (before the camera).
  static Rect faceInSet(Size size) {
    final figure = figureRect(size);
    const design = SilhouetteFigure.designSize;
    final sx = figure.width / design.width;
    final sy = figure.height / design.height;
    return Rect.fromLTRB(
      figure.left + faceInDesign.left * sx,
      figure.top + faceInDesign.top * sy,
      figure.left + faceInDesign.right * sx,
      figure.top + faceInDesign.bottom * sy,
    );
  }

  /// The middle plane's framing for [shot].
  static CameraShot middle(SceneShot shot) => switch (shot) {
    SceneShot.wide => wide,
    SceneShot.close => _middleClose,
    SceneShot.tight => tight,
  };

  /// Where the face is on screen through [shot] (the same maths as the kit's `Framed`).
  static Rect faceRect(Size size, CameraShot shot) {
    final face = faceInSet(size);
    final focus = shot.focus.alongSize(size);
    final target = shot.target.alongSize(size);
    Offset map(Offset p) => target + (p - focus) * shot.scale;
    return Rect.fromPoints(map(face.topLeft), map(face.bottomRight));
  }

  static const int _samples = 24;

  /// The lowest the face's chin gets on screen while the camera moves through [shots] (every
  /// frame of each push between consecutive shots, and under reduced motion both ends of the
  /// cross-fade). Subtitles start below this.
  static double faceBottom(Size size, List<SceneShot> shots) {
    var bottom = 0.0;
    for (var i = 0; i < shots.length; i++) {
      final from = middle(shots[i]);
      final to = middle(shots[math.min(i + 1, shots.length - 1)]);
      for (var s = 0; s <= _samples; s++) {
        final shot = CameraShot.lerp(from, to, s / _samples);
        bottom = math.max(bottom, faceRect(size, shot).bottom);
      }
    }
    return bottom;
  }

  /// The planes, back to front, for the camera. [shot] picks the close framing the camera is
  /// heading to: the close-up, or the follow-up's tight shot (reached by a hard cut).
  static List<CameraLayer> layers({
    required SilhouetteFigure figure,
    required ChapterGrade grade,
    required String figureLabel,
    required bool tight,
    InterviewerExpression expression = InterviewerExpression.neutral,
  }) {
    final kit = BoardroomSet.layers(figure: figure, grade: grade);
    return [
      CameraLayer(
        wide: wide,
        close: tight ? _backTight : _backClose,
        child: kit[0].child,
      ),
      CameraLayer(
        wide: wide,
        close: tight ? MissionSet.tight : _middleClose,
        child: _Interviewer(
          figure: figure,
          grade: grade,
          label: figureLabel,
          expression: expression,
        ),
      ),
      // The desk takes the interviewer's framing on the tight shot, so it stays under her.
      CameraLayer(
        wide: wide,
        close: tight ? MissionSet.tight : _frontClose,
        child: kit[2].child,
      ),
    ];
  }
}

/// The middle plane: the lamp's pool and the interviewer behind the desk.
class _Interviewer extends StatelessWidget {
  const _Interviewer({
    required this.figure,
    required this.grade,
    required this.label,
    required this.expression,
  });

  final InterviewerExpression expression;

  final SilhouetteFigure figure;
  final ChapterGrade grade;
  final String label;

  static const Alignment _pool = Alignment(-0.72, 0.15);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final rect = MissionSet.figureRect(box.biggest);
      return Stack(
        fit: StackFit.expand,
        children: [
          Spotlight(grade: grade, center: _pool),
          Positioned.fromRect(
            rect: rect,
            child: InterviewerSilhouette(
              figure: figure,
              grade: grade,
              semanticLabel: label,
              expression: expression,
            ),
          ),
        ],
      );
    },
  );
}
