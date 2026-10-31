import 'beat.dart';

/// How much of a beat's points a pick keeps, and why (wave 5: picking at random stops paying).
///
/// The rule, in the order it's checked:
///
/// 1. **Guessed** (picked before [guessThreshold]): the beat scores **0** on every dimension,
///    whatever line was picked. Nobody reads three interview answers in under a second and a
///    half, so a good line picked that fast is luck, not judgement.
/// 2. **Unsound reason** (the player picked a strongest line, then gave the wrong principle for
///    it when the interviewer asked "why that line?"): the beat keeps **60 %** of its points.
///    The line did its job in the room, but the player got lucky: they can't say why it works,
///    so they can't repeat it on purpose. The reason step never deepens a weak line
///    ([ReasonPick.counts] is false there): it scores its own points, and the debrief explains
///    the misconception instead.
/// 3. Otherwise (a sound reason, or no why step, or an attempt saved before wave 5): **full**
///    points.
///
/// The debrief names the credit of each beat, so a lower score is always explained.
enum PickCredit {
  full(100),
  unsoundReason(unsoundReasonKeepPercent),
  guessed(0);

  const PickCredit(this.keepPercent);

  /// The share of the line's points the beat keeps, in percent.
  final int keepPercent;

  /// The credit [pick] earns.
  static PickCredit of(BeatPick pick) {
    if (pick.guessed) return guessed;
    final reason = pick.reason;
    if (reason != null && reason.counts && !reason.sound) return unsoundReason;
    return full;
  }
}

/// The share of a beat's points a pick keeps when its reason is unsound: 60 %. The good line
/// still earns most of its points (it worked in the room), but losing 40 % is enough that the
/// player feels the reasoning matters: a perfect line misreasoned (1.8 a dimension) scores
/// below a solid line with the right reasoning (2).
const int unsoundReasonKeepPercent = 60;

/// [PickCredit.keepPercent] is out of this.
const int fullCreditPercent = 100;
