# Brief 28: Colour themes the owner can switch (worktree w1)

Lead session (thelastroom-w1-ba), 2026-11-01. Worktree `../thelastroom-w1`, branch
`feat/28-themes` from `origin/main`. Session: thelastroom-1e.

## Why

The owner asked whether the colours can still change. They can, and the owner should be able
to pick on the phone.

## Owns

`packages/brand`, `apps/mobile/lib/ui/**`, `features/settings`, `features/title`,
`features/recall` (visual), and their tests and goldens. 9a is adding a notifications row to
Settings: coordinate the order.

## In scope

1. **Themes.** Turn the vivid palette into a theme set in `packages/brand`: today's "Evening
   Forest" (the default), plus 2–3 genuinely different alternatives, for example:
   - "Sunset City": coral, violet, gold;
   - "Ocean Night": deep navy, teal, aqua;
   - "Morning Light": bright, but not white-and-grey.

   Each keeps the chapter colours climbing in tension, and every text pair passes the AA
   contrast tests.
2. **Live switching.** A "Theme" row in Settings with swatches; it switches live and persists
   (`shared_preferences`).
3. **Every screen follows the theme**, including the splash colour where practical (the native
   splash can stay on the default). The goldens use the default.
4. **The catalog** gets a theme switcher, so all four can be compared side by side.

## Done when

The owner can pick a theme in Settings on the realme 8, every screen follows it, it survives a
restart, and all four pass AA. Gates green, PR with screenshots of each theme.
