# Brief 13: Onboarding, the Tower home, progress, and the first-play fixes (worktree w2)

Written by the lead session, 2026-10-30 (Fri), after the owner's first play and a feedback
session. Worktree `../thelastroom-w2`, branch `feat/13-onboarding-tower` (from `main` with the
mission player, PR #12). **Target: PR up Sat 31 Oct, evening.**

## Goal

Turn the playable missions into a game you come back to. A first-time player gets a proper,
friendly onboarding (researched from Duolingo's), tells us their name and experience, and lands
on **the Tower**: every mission as a room, finished rooms lit with their score, the current one
glowing, the rest locked. A **progress** screen shows mission by mission how they're doing. And
the two problems the owner hit on the phone are fixed.

Read first: brief §2, §6, §7, §9 (`docs/product-brief.md`), `DESIGN.md` (chosen direction),
`docs/requirements.md` FR-1, FR-4, FR-5, FR-16, FR-31, FR-41, FR-42, NFR-1, NFR-2, NFR-8, and the
mission player (`features/{intro,mission,debrief}`).

## The owner's feedback this brief answers (2026-10-30)

1. **The Skip/next arrow on Priya's lines is too small and often needs two taps.** Make it a
   clear, labelled control (at least 48 dp, the whole lower third tappable to advance), and fix
   the first-tap miss (find the cause: hit area, gesture conflict with tap-to-complete, or the
   button appearing before it's interactive; test it).
2. **Lines should move on by themselves.** After a line has finished typing, auto-advance after
   **6 seconds**, with a visible countdown on the Next control. Touching the screen pauses it.
   A setting turns auto-advance off (accessibility, slow readers). Auto-advance applies only to
   interviewer lines, never to choosing an answer (Mission 1 stays untimed).
3. **"The answer I save doesn't show up."** Show the player's own first try on the dossier,
   beside the line that scored best: "Your first try" / "A stronger version".
4. **A proper onboarding, not straight into the mission.**
5. **See progress like Duolingo:** what's done, what's next, what's locked.
6. The candidate-file screens (assessment, dossier) are the owner's favourite. Reuse that look
   for the progress screen.

## In scope

1. **Onboarding** (first launch only; a returning player goes straight to the Tower). Research
   Duolingo's onboarding first and write 5–8 bullet findings in `docs/status/13.md` (what they
   ask, in what order, how they show value before asking, how long it takes). Then build, using
   06's components and motion: a welcome that shows what the game is (2–3 short animated cards,
   skippable) → **your first name** → **your experience** (student, fresh graduate, 1–2 years,
   switching careers) → **the role you're aiming for** (choices, plus "not sure yet") → **how
   nervous interviews make you** (1–5; 4–5 turns calm mode on) → **a weekly goal** (e.g. 3
   sessions) → "Your first interview is waiting" → the Tower. Under 60 seconds, every step
   skippable except the name (which can be "Skip, call me Candidate"). Fires
   `onboarding_completed` (registered).
2. **Using the name:** interviewers greet the player by their first name ("Hi Sami, I'm Priya").
   The CV the options draw on stays the practice CV from content; present it as "your practice
   CV for this role", so the player understands the facts belong to the scenario, while the
   draft step is their own words.
3. **Profile storage:** create `apps/mobile/lib/core/profile/profile_repository.dart`: an
   interface (name, experience, target role, nerves level, calm mode, weekly goal, auto-advance
   on/off), a **local** implementation (persists on the device: `shared_preferences` if brief
   09 has merged it, otherwise ask the lead) and its provider. Brief 08 syncs it to Supabase
   later. **No sign-up, no login screen** (owner, 2026-10-30): the silent guest account from
   brief 05 is the only account.
4. **The Tower home** (FR-31, brief §9 "the building"): a tall tower at night, chapter floors
   stacked, Chapter 1 at the bottom with its seven rooms. Each room shows state:
   - **done**: lit window, the best score as a small stamp; tap to replay;
   - **current**: glowing, with an "Enter" label (Duolingo's START bubble); tap to play;
   - **locked**: dark, with a lock and the mission title as a teaser.
   Chapters 2 and 3 are dark floors above with their titles; **the last room** sits at the top,
   always visible. The next mission unlocks when the current one is finished (any score).
   Entering a room plays a short elevator transition (about 1.2 s, skippable, cross-fade under
   reduced motion) into the mission. After the dossier, "Back to the tower" shows the newly
   lit room and the next one glowing (a small reward moment).
5. **Progress screen** (FR-16, FR-41), styled like the candidate file: per mission, best and
   latest score, the four dimension scores, attempts, and the lesson still to work on; a
   Chapter 1 summary at the top (missions done of 7, average score, change since Mission 1).
   Reached from the Tower.
6. **Events:** register before firing (enum + `docs/EVENTS.md`): opening the Tower, entering a
   room, opening progress. No names or typed text in any property.
7. **Sound hooks:** add methods to `core/audio/game_sounds.dart` for the elevator, entering a
   room, tapping a locked room and opening the Tower (each with a no-op in `SilentGameSounds`),
   and call them. Brief 09 wires real cues; additions only, never rename.
8. **Colours:** use brand tokens only. The owner wants a brighter, friendlier palette and a
   friendlier character look (a separate design brief), so nothing here may hard-code a colour
   or assume the dark look.

## Out of scope

- Supabase sync of the profile and attempts (brief 08). The AI coach (12). Notifications (11).
- Recall Room (it gets a door on the Tower, shown as "coming soon" if not built yet).
- The palette and character redesign (separate brief).

## File ownership

- `apps/mobile/lib/features/{onboarding,tower,progress}/**` (new), `features/{intro,mission,debrief}/**`
  (fixes 1–3 and the name greeting), `apps/mobile/lib/core/profile/**` (new),
  `apps/mobile/lib/core/audio/game_sounds.dart` (additions only), `apps/mobile/lib/app/router.dart`,
  the events enum + `docs/EVENTS.md`, matching tests, `docs/status/13.md`, `.pr-screenshots/13/**`,
  your own `.claude-logs/` files.

**Not yours:** `ui/**` and `packages/brand` (ask the lead for component or token changes),
`packages/content` (content changes go to the lead), `core/{audio except game_sounds.dart,db,sync,backend}`,
`supabase/`, pubspecs (ask the lead if you need a package), CI, `scripts/`, `AGENTS.md`,
`DESIGN.md`, `docs/HANDOFF.md`, `docs/requirements.md`.

## Acceptance criteria

- [ ] First launch: onboarding → Tower in under 60 s; second launch goes straight to the Tower.
- [ ] Tower shows done / current / locked rooms correctly after playing Missions 1 and 2 (test).
- [ ] Finishing a mission lights its room and unlocks the next (test).
- [ ] Progress screen numbers equal the stored attempts' engine scores (test).
- [ ] The Next control: ≥ 48 dp, first tap always works (test), auto-advances 6 s after a line
      finishes, pauses on touch, and can be switched off (tests).
- [ ] The dossier shows the player's first try when there is one.
- [ ] Priya greets the player by name; no name ever reaches analytics (test).
- [ ] Reduced motion and 2x text pass on onboarding, Tower and progress.
- [ ] PR: a Chrome recording (compressed) of first launch → onboarding → Tower → Mission 1 →
      dossier → back to the Tower with the next room unlocked; compressed stills of each screen.
- [ ] All local-review gates green; CI green; `docs/status/13.md` current.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/13.md`: done, half-done, next.
- No phone: Chrome and widget tests; the lead checks Android on the realme in review.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
