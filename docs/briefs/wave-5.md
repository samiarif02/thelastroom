# Wave 5: make it beautiful and make it impossible to play on autopilot

Written by the lead session (w1-ba), 2026-10-31 (Sat), after the owner played merged `main`
(#15, #16, #17) on the realme 8. **Four briefs run in parallel. Target: every PR open, green and
phone-checked by Sat 31 Oct, 22:00.** The project is judged on this; it is the top priority.

## What the owner said (their words, condensed)

- "Just the theme changed." Onboarding and the tower are **white screens with grey text, basic
  UI, no attraction**. Users get bored; reviewers won't accept it. Redevelop the UI so it is
  beautiful and attractive, not just re-ordered.
- Tower order is upside down: **Mission 1 sits at the bottom.** Chapters must read 1, 2, 3 and
  missions 1, 2, 3 … top to bottom.
- **Too many steps:** scroll to find "double tap to select your answer", tap Mission 1, scroll,
  tap Start. **Everything should be one tap.**
- **The Android back button closes the app.** Inside a sub-screen it must go back to the parent;
  at the root it must say "press back again to exit" (`PopScope`). Inside a mission, leaving must
  save the player's progress.
- **The splash screen is not nice.**
- **Random clicking still gets a score.** "I randomly clicked and she scored me." The player must
  have to think: focused, interactive, fun, learning, not tapping options at random.

## The four briefs

| Brief | Worktree | Session | Owns |
| --- | --- | --- | --- |
| 17 vivid UI: tower, onboarding, progress, brand | `../thelastroom-w1` | thelastroom-1e | `packages/brand`, `apps/mobile/lib/ui`, `features/tower`, `features/onboarding`, `features/progress` |
| 18 the mission plays like a conversation | `../thelastroom-w2` | thelastroom-w2-c1 | `features/mission`, `features/debrief` |
| 19 reasons, reactions and fair scoring | `../thelastroom-w4` | thelastroom-9a | `packages/engine`, `packages/content`, `core/audio` |
| 20 splash, title, intro and the back button | `../thelastroom-w3` | thelastroom-6c | `app/`, `features/title`, `features/intro`, `features/settings`, `android/`, `ios/`, `web/` |

Every branch starts from `lead/wave-5`. That holds this plan, the four briefs and **the
contract** (below), so all four PRs carry identical lead commits and merge cleanly in any order.

**Shared files, append-only:** `AnalyticsEvent` + `docs/EVENTS.md` (add new events at the end of
the list; the lead resolves order at merge) and `pubspec.yaml`/`pubspec.lock` (add a dependency
only if you must, and say so in the PR). Anything else outside your list: message the lead
(thelastroom-w1-ba) and the owning session. Never edit another brief's files.

**Merge order:** 19 → 18 → 17 → 20. Whoever merges later rebases on `main` and re-runs the gates.
The lead merges only on the owner's word.

## The contract (already committed on `lead/wave-5`, briefs 18 and 19 both build on it)

- `packages/engine/lib/src/beat.dart`:
  - `BeatPick` gains `decidedIn` (`Duration?`, measured by the player, the engine never reads a
    clock) and `reason` (`ReasonPick?`).
  - `ReasonPick(reasonId, sound)`.
  - `guessThreshold` (1.5 s), `isGuess()` and `BeatPick.guessed`.
  - `enum PickQuality { strong, weak, guessed }` and
    `judgePick(BeatPick, {required bool strongestOption})`.
- `packages/content/lib/src/mission.dart`:
  - `Beat` gains `why` (`ReasonPrompt?`: the interviewer's "why that line?" and 3–4 `Reason`s,
    each with `soundFor` option ids) and `reaction` (`BeatReaction?`: a strong, weak or guessed
    line).
  - `Reason.pickFor(optionId)` builds the `ReasonPick`.
- All new fields are optional, so today's content and tests compile unchanged. Brief 19 fills
  them and changes scoring; brief 18 plays them. **Signature changes go through the lead.**

## Rules for every brief

- Start of session: read `AGENTS.md`, your brief, this file, `DESIGN.md` and the rule files for
  what you touch.
- Keep `docs/status/NN.md` current (done, half-done, next, decisions, needs). The lead reads it.
- Gates: the `local-review` skill, then the `ship` skill (PR, not a draft, real description,
  green CI). **Never merge.**
- UI changes: before/after screenshots from the realme 8 (`flutter run -d RMX3085`; one phone,
  so take turns and keep installs short) in `.pr-screenshots/<brief>/`.
- When your PR is green, message the lead with the link.
