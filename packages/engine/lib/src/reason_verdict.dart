import 'beat.dart';

/// How the player's answer to "why that line?" landed, for its XP (brief 55). The feedback
/// sheet after the why step shows the same verdict as its tone: "That's the principle." (sound),
/// "Close, but not quite." (close), "You barely looked at those." (guessed).
///
/// The rule, in the order it's checked ([of]):
///
/// 1. **No why step** (a built beat, where putting the parts in order is the reasoning; an
///    attempt saved before wave 5; or a reason stored on a beat that never asked, see
///    [ReasonPick.asked]): no verdict, no XP.
/// 2. **Guessed** (the line was picked before [guessThreshold]): **0 XP** whatever the reason.
///    Fast clicking never pays, as in `PickCredit.guessed`.
/// 3. **Sound** (the right principle for the line): [reasonSoundXp].
/// 4. Otherwise **close** (a considered reason, but the wrong principle): [reasonCloseXp].
///
/// The verdict is a pure function of the attempt's final picks, so XP is too: a resumed attempt,
/// a restored one or one scored twice earns its reasons once, exactly.
enum ReasonVerdict {
  sound(reasonSoundXp),
  close(reasonCloseXp),
  guessed(0);

  const ReasonVerdict(this.xp);

  /// What this verdict earns.
  final int xp;

  /// The verdict on [pick]'s reason, or null when the beat had no why step.
  static ReasonVerdict? of(BeatPick pick) {
    final reason = pick.reason;
    if (reason == null || !reason.asked) return null;
    if (pick.guessed) return guessed;
    return reason.sound ? sound : close;
  }
}

/// XP for the right principle: the mockup's "+10 XP" on the feedback sheet.
///
/// Why 10: a room is worth 20–100 XP (`missionXp`: 20 base, up to 50 for the score, 30 on a
/// first clear). A choice room asks why two or three times, so its reasons add at most 30, under
/// a third of a perfect first clear: enough that explaining is worth doing on purpose, not so
/// much that it outweighs the answer itself. A sound reason on the strongest line also keeps the
/// beat at full credit, so getting the reasoning right pays twice, as it should.
const int reasonSoundXp = 10;

/// XP for a considered but wrong principle: half of [reasonSoundXp].
///
/// XP rewards practice (showing up earns `missionBaseXp`; a missed Recall card still earns
/// `recallTriedXp`); correctness is what the score is for. Thinking through the why step is the
/// practice, so it earns something, but the right principle earns twice as much. Picking reasons
/// at random (one sound of three) averages 6.7 a step against 10 for knowing.
const int reasonCloseXp = 5;

/// XP for each listen-for point a spoken answer makes (a voice room has no why step).
///
/// Saying a point out loud is the player explaining the principle in their own words, the
/// spoken equivalent of a sound reason, and voice rooms score on content only (which points were
/// made, never delivery), so the XP reads the same input as the score. Voice rooms listen for 6–7
/// points, so a full answer earns 30–35, level with a choice room's 20–30 for its reasons: a
/// voice room is never the worse deal for being harder. A point missed earns nothing, like a
/// guess: there's no "close" in a spoken answer the engine can see.
const int voicePointXp = 5;
