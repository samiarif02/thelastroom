import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// What the interviewer's face is doing (brief 16). A scene sets it per beat: a smile on the
/// greeting, thinking while the player reads the cards, a nod when an answer lands, and "hmm"
/// on the follow-up.
enum InterviewerExpression {
  /// Listening: a small, friendly resting smile.
  neutral,

  /// A real smile: cheeks up, eyes crinkled.
  smile,

  /// Eyes up and away, one brow up, mouth to the side.
  thinking,

  /// A small double nod, pleased (the head moves; see [FaceGesture]).
  nod,

  /// The follow-up: one brow raised, lips pressed to one side. Curious, not cross.
  hmm,
}

/// The face's shape for one expression, in design units (the figure's 100 × 120 box). Every
/// expression is one of these, so a change of expression is a [lerp] between two.
@immutable
class FaceShape {
  const FaceShape({
    this.browLeft = 0,
    this.browRight = 0,
    this.browTilt = 0,
    this.eyeOpen = 1,
    this.lookX = 0,
    this.lookY = 0,
    this.mouthWidth = 6,
    this.mouthCurve = 1.2,
    this.mouthOpen = 0,
    this.mouthShift = 0,
    this.blush = 0,
    this.headTilt = 0,
  });

  /// How far each brow moves up (negative) or down.
  final double browLeft;
  final double browRight;

  /// The inner ends up (positive, worried/open) or down (negative, focused).
  final double browTilt;

  /// 1 open, 0 shut (the blink multiplies this).
  final double eyeOpen;

  /// Where the eyes look, -1…1 each way.
  final double lookX;
  final double lookY;
  final double mouthWidth;

  /// How far the mouth's middle dips below its corners (a smile), negative for a flat press.
  final double mouthCurve;

  /// 0 closed, 1 an open smile.
  final double mouthOpen;

  /// The mouth slides to one side ("hmm").
  final double mouthShift;
  final double blush;

  /// Radians: the head leans while thinking.
  final double headTilt;

  static FaceShape of(InterviewerExpression expression) => switch (expression) {
    InterviewerExpression.neutral => neutral,
    InterviewerExpression.smile => smile,
    InterviewerExpression.thinking => thinking,
    InterviewerExpression.nod => nod,
    InterviewerExpression.hmm => hmm,
  };

  static const FaceShape neutral = FaceShape();

  static const FaceShape smile = FaceShape(
    browLeft: -0.8,
    browRight: -0.8,
    browTilt: 0.3,
    eyeOpen: 0.72,
    mouthWidth: 9.5,
    mouthCurve: 3.4,
    mouthOpen: 0.7,
    blush: 0.32,
  );

  static const FaceShape thinking = FaceShape(
    browLeft: -0.3,
    browRight: -1.6,
    browTilt: -0.2,
    lookX: 0.75,
    lookY: -0.85,
    mouthWidth: 4.6,
    mouthCurve: 0.5,
    mouthShift: 1.8,
    headTilt: 0.06,
  );

  static const FaceShape nod = FaceShape(
    browLeft: -0.5,
    browRight: -0.5,
    eyeOpen: 0.85,
    mouthWidth: 7.6,
    mouthCurve: 2.6,
    mouthOpen: 0.2,
    blush: 0.18,
  );

  static const FaceShape hmm = FaceShape(
    browLeft: 0.4,
    browRight: -1.8,
    browTilt: -0.35,
    eyeOpen: 0.86,
    lookX: -0.35,
    mouthWidth: 4.4,
    mouthCurve: -0.35,
    mouthShift: -1.6,
    headTilt: -0.045,
  );

  static FaceShape lerp(FaceShape a, FaceShape b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return FaceShape(
      browLeft: l(a.browLeft, b.browLeft),
      browRight: l(a.browRight, b.browRight),
      browTilt: l(a.browTilt, b.browTilt),
      eyeOpen: l(a.eyeOpen, b.eyeOpen),
      lookX: l(a.lookX, b.lookX),
      lookY: l(a.lookY, b.lookY),
      mouthWidth: l(a.mouthWidth, b.mouthWidth),
      mouthCurve: l(a.mouthCurve, b.mouthCurve),
      mouthOpen: l(a.mouthOpen, b.mouthOpen),
      mouthShift: l(a.mouthShift, b.mouthShift),
      blush: l(a.blush, b.blush),
      headTilt: l(a.headTilt, b.headTilt),
    );
  }
}

/// The idle and the nod as pure functions of time, so tests can check any instant.
abstract final class FaceGesture {
  // A breath every ~4.6 s; the body sways round every ~13 s.
  static const double _breathPeriod = 4.6;
  static const double _swayPeriod = 13;

  /// The idle pose at [seconds]: (breath -1…1, turn -1…1).
  static ({double breath, double turn}) pose(double seconds) {
    final breath = math.sin(seconds * 2 * math.pi / _breathPeriod);
    // Cubing the sine holds near each end of the sway, then glides across: a person, not a
    // pendulum.
    final s = math.sin(seconds * 2 * math.pi / _swayPeriod);
    return (breath: breath, turn: s * s * s);
  }

  static const double _blinkPeriod = 4.2;
  static const double _blinkLength = 0.16;

  /// How open the eyes are at [seconds] of the idle: a blink every few seconds, at a slightly
  /// different moment each cycle so it never reads as a metronome. Open at 0, so a still frame
  /// (reduced motion stops the clock) is never caught mid-blink.
  static double blink(double seconds) {
    final cycle = (seconds / _blinkPeriod).floor();
    final at = _blinkPeriod - 0.4 - 0.9 * _jitter(cycle);
    final into = seconds - cycle * _blinkPeriod - at;
    if (into < 0 || into > _blinkLength) return 1;
    return 1 - math.sin(into / _blinkLength * math.pi);
  }

  /// How far the head dips at [progress] (0…1) through a nod: two small dips.
  static double nodDip(double progress) {
    if (progress <= 0 || progress >= 1) return 0;
    final s = math.sin(progress * 2 * math.pi);
    return _nodDepth * s * s;
  }

  static const double _nodDepth = 1.8;

  /// A repeatable 0…1 per blink cycle.
  static double _jitter(int cycle) {
    final x = math.sin(cycle * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }
}
