import 'dart:async';

import 'package:brand/brand.dart';
import 'package:flutter/foundation.dart';

/// What just happened in a scene, as far as the interviewer's face is concerned.
enum CastCue {
  /// The interviewer's line starts typing out.
  questionShown,

  /// The line has finished typing.
  lineTyped,

  /// The player is choosing a card or speaking.
  choosing,

  /// A sound pick or reason.
  pickSound,

  /// A weak or tempting pick, or a guess.
  pickWeak,

  /// Waiting on a score (any latency reads as thought).
  awaitingScore,

  /// The debrief, a strong answer.
  debriefStrong,

  /// The debrief, a weak answer.
  debriefWeak,

  /// Nothing to react to.
  rest,
}

/// The small state machine behind an interviewer's face (direction.md, "Characters"): mission
/// cues in, one of the seven expressions out. A nod is a gesture, so after
/// [nodHold] the face settles back to [CastExpression.listening]. Feed `value` to a
/// `CastFigure`'s `expression` (a `ValueListenableBuilder`).
class CastController extends ValueNotifier<CastExpression> {
  CastController([super.value = CastExpression.neutral]);

  /// How long a nod holds before the face goes back to listening.
  static const Duration nodHold = Duration(milliseconds: 1200);

  Timer? _settle;

  /// The expression [cue] leads to.
  static CastExpression forCue(CastCue cue) => switch (cue) {
    CastCue.questionShown => CastExpression.talk,
    CastCue.lineTyped || CastCue.choosing => CastExpression.listening,
    CastCue.pickSound => CastExpression.nod,
    CastCue.pickWeak || CastCue.debriefWeak => CastExpression.hmm,
    CastCue.awaitingScore => CastExpression.thinking,
    CastCue.debriefStrong => CastExpression.smile,
    CastCue.rest => CastExpression.neutral,
  };

  /// React to [cue].
  void on(CastCue cue) {
    _settle?.cancel();
    value = forCue(cue);
    if (value == CastExpression.nod) {
      _settle = Timer(nodHold, () => value = CastExpression.listening);
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }
}
