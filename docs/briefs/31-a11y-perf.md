# Brief 31: Accessibility and performance pass (worktree w1)

Lead session (thelastroom-w1-ba), 2026-11-01. Worktree `../thelastroom-w1`, branch
`fix/31-a11y-perf` from `origin/main`. Session: thelastroom-1e. Covers NFR-2 and NFR-3 in the
plan: part of completing every stage before new ideas.

## Owns

`packages/brand`, `apps/mobile/lib/ui/**`, `features/tower`, `features/onboarding`,
`features/settings`, `features/title`, `features/recall` (visual), and their tests. Tell w2-c1
before touching `features/mission` or `features/debrief` (they're doing the playthrough fixes
there).

## In scope

1. **Accessibility, every screen** (tower, onboarding, mission, build mode, debrief, report,
   Recall Room, file, settings, title):
   - 2x text with no overflow;
   - reduced motion swaps camera moves for cross-fades;
   - every tappable is at least 44 pt, with a semantic label;
   - screen-reader order makes sense;
   - contrast is AA in all four themes.

   Add widget tests for the worst offenders.
2. **Performance:** a profile pass on the heaviest screens (the mission scene, the tower list,
   theme switching). Look for jank in the timeline and for rebuild storms (for example, a theme
   change rebuilding everything twice), and fix what you find. Record before/after frame times
   in `docs/status/31.md`. The realme is the owner's; the lead does the on-device check.
3. **Leftovers:** the `/dev/sound` board's white-on-cream audio section, and any screen still
   not following the theme.

## Done when

Every screen passes the checks above in tests, the profile numbers are in the status file, the
leftovers are fixed, and the gates are green.
