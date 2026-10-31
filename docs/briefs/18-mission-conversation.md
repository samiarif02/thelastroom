# Brief 18: The mission plays like a conversation, not a quiz (worktree w2)

Lead session, 2026-10-31. Worktree `../thelastroom-w2`, branch `feat/18-mission-conversation` from
`origin/lead/wave-5`. Session: thelastroom-w2-c1 (you built the mission player in brief 10).
Read `docs/briefs/wave-5.md` first, especially **the contract**.

## Why

The owner: **"I randomly clicked the options and she scored me. I'm not interested."** They also
had to scroll to find "double tap to select your answer". A mission must hold attention: the
player reads, decides, explains themselves and sees the interviewer react. Clicking at random
must be visibly punished in the story.

## Owns

`apps/mobile/lib/features/mission/**`, `features/debrief/**`, their tests and goldens. Use
brief 17's tokens and `lib/ui` (ask 1e for changes), brief 19's content and engine (the
contract), and `GameSounds` (19 owns `core/audio`; ask 9a for a new hook).

## In scope

1. **One tap, no scrolling.**
   - The question and all answer cards fit on the realme 8 screen (and at 2x text, by scrolling
     only the cards).
   - **A single tap picks** an answer; no "double tap to select". If you need protection against
     mis-taps, use a short undo ("Tap again to change", 2 s) rather than a hidden gesture.
   - Remove any instruction text the player has to scroll to find.
2. **The options appear after the question is heard.**
   - The cards fade in once the interviewer's line has finished typing (or is tapped to
     complete).
   - Start a stopwatch then, and pass `decidedIn` in the `BeatPick`.
3. **Guessing is seen.**
   - A pick with `pick.guessed` gets `beat.reaction.guessed` from the interviewer (for example
     "You didn't even read those, did you?").
   - The trust meter drops, a short "Too fast: read before you answer" cue appears, and the beat
     scores as the engine says (19).
4. **"Why that line?"** When `beat.why != null`:
   - after the pick, the interviewer asks `why.line`;
   - the player taps one of `why.reasons` (same one-tap cards);
   - build `reason.pickFor(option.id)` into the `BeatPick`.
   It must feel like part of the conversation, not a form.
5. **Live reactions.** After each beat, show `beat.reaction.forQuality(judgePick(...))` as the
   interviewer's next subtitle, with her expression changing:
   - warm, leaning in on `strong`;
   - cooler, checking her watch on `weak`.
   Add a visible trust/attention meter that moves.
6. **Back button inside a mission** (`PopScope`): a small sheet, "Leave the interview? Your
   progress is saved", with Resume and Leave.
   - Leaving saves the in-progress attempt (current beat and picks so far) locally
     (`shared_preferences` is already a dependency).
   - Opening that mission again offers "Continue where you left off".
7. **Debrief**: show the player's reasoning beside each pick (sound or not), and the right
   reasoning, so the lesson lands. Guessed beats are marked.

## Done when

On the realme 8:
- Mission 1 plays with one tap per choice and no scrolling;
- random fast tapping is called out in the scene and scores low;
- every beat with content asks why;
- the interviewer visibly reacts;
- back mid-mission offers to save and leave.
Tests cover the guess path, the why step and the resume path. Gates green, screenshots and a
short screen recording in the PR.
