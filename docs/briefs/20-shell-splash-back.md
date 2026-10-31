# Brief 20: Splash, title, intro and the back button (worktree w3)

Lead session, 2026-10-31. Worktree `../thelastroom-w3`, branch `feat/20-shell-splash-back` from
`origin/lead/wave-5`. Session: thelastroom-6c. Read `docs/briefs/wave-5.md` first.

## Why

The owner: **"When I press back, the app completely closes."** Sub-screens must go back to their
parent; the root must ask "press back again to exit". **"The splash screen is not nice."** First
impressions decide whether a reviewer keeps playing.

## Owns

`apps/mobile/lib/app/**` (router, app shell), `features/title/**`, `features/intro/**`,
`features/settings/**`, native splash and launch resources under `apps/mobile/android/` and
`apps/mobile/ios/`, `apps/mobile/web/index.html`, and their tests. Use brief 17's brand tokens
(ask thelastroom-1e for new ones).

## In scope

1. **Navigation that goes back.**
   - Restructure `router.dart` so screens have a parent: tower → mission, tower → progress,
     tower → settings, title → intro → character. Nested `GoRoute`s give `context.go` a real back
     stack, so the system back button pops to the parent instead of closing the app.
   - **At the root (the tower)**: `PopScope` + a brand-styled snackbar or toast, "Press back again
     to exit". A second press within 2 s exits.
   - The mission's own "leave and save" sheet is brief 18's. Make sure the router lets its
     `PopScope` decide.
   - Deep links (`/mission/3`) still open with the tower underneath.
   - Tests: back from each sub-screen lands on its parent; a single back at the root doesn't
     exit, a double back does.
2. **A splash worth showing.**
   - Android 12+ splash (`windowSplashScreen*` in `styles.xml` / `values-v31`) and the pre-12
     `launch_background`, plus the iOS `LaunchScreen`: the app icon on brief 17's brand colour,
     not white.
   - Then a short animated Flutter title (the tower lighting up, the name), at most about 1.5 s.
     A tap skips it.
   - The web loading screen (`index.html`) matches.
   - Brief 06b left a check open: the launcher icon and the Android 12 splash were never looked
     at on a device. Check both on the realme 8.
3. **Title, intro and character screens** in the new visual language (colour, motion, one
   obvious button). If the intro shows numbered scenes or cards, they read in order 1, 2, 3.
4. **Settings reachable** from the tower (a gear icon), with the audio section that already
   exists.

## Done when

On the realme 8:
- back never closes the app from a sub-screen;
- at the root, a double back exits with the hint;
- the splash and title look branded and animated.
Router tests cover the back stack. Gates green, before/after screenshots and a short recording of
the splash in the PR.
