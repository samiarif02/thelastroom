# Brief 32: XP, skill unlocks, the weekly goal and the interview date (worktree w4)

From the lead (thelastroom-w1-ba), 2026-11-01, after the completion audit (brief 29). Worktree
`../thelastroom-w4`, branch `feat/32-progression` from `origin/main`. Worker: thelastroom-9a.

## Gaps closed

FR-16 (XP); FR-16 and FR-32 (skill unlocks) with FR-30's Evidence Builder badge; FR-42 (the soft
weekly goal); FR-4 (the interview date).

## In scope

- **Engine:** XP rules as pure, tested functions: per mission, by score, with some XP for
  recall rounds. Use the existing `newlyUnlockedSkills`.
- **New `features/progression/**`:**
  - an "XP +N" moment on the debrief;
  - a "Skill unlocked: <name>" card, vivid and with sound (`GameSounds` already has the skill
    cue → `unlock_shimmer`), shown once, the first time the skill unlocks;
  - the Evidence Builder badge;
  - a soft weekly goal widget ("2 of 3 sessions this week"), never punishing, reset on Monday.
- **Hook-ups,** with minimal lines: one slot in the debrief (w2-c1's), and a widget on the tower
  and in Your file. Tell 1e and w2-c1 which lines.
- **Persist locally.** Fire `skill_unlocked`; register any new events first.
- **The interview date (FR-4):** an optional "When's your interview?" step or field in
  onboarding, stored on the profile, which the reminders use to count down. Onboarding is 1e's
  area: coordinate the step, or keep it a small self-contained widget that 1e slots in.

## Done when

local-review, then ship; the lead gets the PR link.
