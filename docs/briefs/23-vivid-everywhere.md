# Brief 23: Finish the vivid look everywhere (worktree w1)

Lead session (thelastroom-w1-ba), 2026-11-01. Worktree `../thelastroom-w1`, branch
`feat/23-vivid-everywhere` from `origin/main`. Session: thelastroom-1e.

## Why

The owner's first review scored Design 6/10. The tower, onboarding, your file, the mission and
the debrief are vivid (briefs 17, 18b, 20), but some screens are still in the old cream and
white style, so the app doesn't read as one product.

## Owns

`features/recall` (visual only; brief 21's logic stays untouched), `features/settings`,
`features/title`, `features/intro`, `apps/mobile/lib/ui/**`, `packages/brand`, and their tests
and goldens. Not `features/mission` or `features/debrief` (w2-c1).

## In scope

1. Every screen still in the old cream/white style moves to the vivid kit:
   - the Recall Room's answer cards (plain white today): the same `ChoiceCard` look as the
     mission;
   - the Settings screen and its audio section;
   - the wrong-floor (404) and offline/error screens;
   - the character/CV screen, if anything is left;
   - the dev catalog entries for each.
2. A consistency pass: one button style, one card elevation, the same kickers and spacing, and
   a press state on every tappable.
3. Check 2x text and reduced motion. Update goldens (on Linux).

## Done when

No cream/white screen is left outside the mission's own room. Gates green, goldens updated,
before/after screenshots in the PR. The lead checks it on the realme 8.
