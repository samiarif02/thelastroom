# Brief 42: retention, reminders you can see and reasons to come back (worktree w9)

From the coordinator, 2026-11-02. Worktree `../thelastroom-w9`, branch `feat/42-retention` from
`main` b1d1edf. Background worker.

## Why

The owner's theme is a fun, professional way to learn that brings players back on **day 3 and
day 5**. They say they have "not received any notification". Local reminders exist (brief 26,
PR #33), but by design nobody testing on Chrome, or on the day they installed, ever sees one:
phones only, permission after Mission 1, never the same day, days 1, 2, 3 then 6.

## Scope

1. **"Send a test reminder"** in the Settings reminders panel: on Android and iOS it shows
   tomorrow's real reminder now (the plugin's `show()`), in the interviewer's voice, and a tap
   deep-links like a real one. On the web it explains reminders are phone-only. Without
   permission it asks first, behind the existing explainer.
2. **The schedule, visible:** one line under the switch with the next reminder's day, time and
   sender ("Next: tomorrow at 19:40, from Priya"), or why there is none (off, no permission,
   web).
3. **Welcome back:** after one or more days away, the tower shows a short card in an
   interviewer's voice: what's waiting (Recall cards due, the next room, the weekly goal) and
   one button to it. Dismissible, once per return, never shaming. A new widget in
   `features/tower/` plus a one-line insertion in `tower_screen.dart` (brief 33 is restyling
   the tower in w7: kit components only, no new colours).
4. **Days 3 and 5:** a schedule covering days 1, 3 and 5, then backing off, within FR-51.

New events registered first. Tests: the plan, the next-reminder line, the welcome-back rules;
widget tests for the test button on web and mobile (fake scheduler), at 2x text and reduced
motion.

## Done when

local-review, then ship: a PR to `main` with green CI and the steps for the owner to see a
reminder on their Android phone. The owner reviews the UI before merge.
