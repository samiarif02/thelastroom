# Brief 10: Mission player: Chapter 1 playable offline (wave 3, worktree w2)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w2`, branch
`feat/10-mission-player` (from `main` with 06a and 07 merged). **Starts Fri 30 Oct. Target:
Mission 1 playable end to end by Sat night, PR up by Sun 1 Nov midday.** The owner's
rule: Mission 1 must not slip to Monday.

## Goal

The game. From a fresh clone, `flutter run -d chrome` goes title card → a short intro → "you
play this candidate" → Mission 1: scene, draft first, three beats, the follow-up, the dossier
debrief. Then Missions 2–7 in order, each one a film scene. No account, no network, no keys.

Read first: brief §3, §7, §9, `docs/requirements.md` FR-1, FR-10–FR-17, FR-20–FR-22, NFR-1,
NFR-2, NFR-4, NFR-8, `DESIGN.md` "Chosen direction", 06a's PR (component API note),
`packages/engine` and `packages/content` (including the player character sheet from 07).

## The owner's fixes from the 06a phone review (2026-10-30): must-haves

1. **The subtitle never covers Priya's face**, at any moment, including after the push-in. Compose
   the shot so the face sits clear of the subtitle block (move the framing or the subtitle, or a
   scrim *below* the face, never over it). A widget test checks the subtitle's rect against the
   face's rect through the whole push-in, at 375×667 and 2x text.
2. **No stray rim-light dot.** After the push-in, the silhouette's rim highlight shows as a lone
   bright dot beside the subtitle (seen on the realme next to "applied"). Fix it in
   `apps/mobile/lib/ui/figure/silhouette_figure.dart` / `interviewer_silhouette.dart` (those two
   files are yours this wave; 06b won't touch them).
3. **Edge to edge in the mission player:** the scene draws under the status and navigation bars
   (transparent bars, light icons; `SystemUiMode.edgeToEdge`), with content kept clear of the
   insets. No flat black bands. This moves from 06b to you, including the Android side
   (`android/app/src/main/res/values*/styles.xml` if needed).

## Hard rules

- Zero setup, fully offline (AGENTS.md 6). The engine does all scoring; the UI never computes a
  score. Every screen uses 06's components and brand tokens only; no stock Material.
- Reduced motion swaps every camera move for a cross-fade; 44 pt targets; 2x text survives.
- Events registered before they fire (they already are; add to the enum + `docs/EVENTS.md` first
  if you need a new one).

## In scope

1. **Flow:** title card → 3-screen intro (skippable from frame one; `intro_completed`) →
   **character card** ("You are <name>, a fresh graduate…" from content's character sheet; the
   draft step is for *your own* words) → Mission 1.
2. **Mission scene** (FR-10–FR-16): letterbox in, Priya in the spotlight, typewriter setup lines
   and question (tap to complete), the camera cut when the question lands; **draft first**
   (optional, stays on the device; `draft_completed`); three beats, Open → Evidence → Land, on
   answer cards; the **trust meter heartbeat** from `trustAfter`; the follow-up from the engine,
   landing on the black-frame hard cut; the reply; the **dossier**: four stamped scores, the
   wax-seal total, the red pen on `optionIdsByCost`'s first line, and that line's lesson.
3. **Options shuffled on screen** (owner's note): a seeded order per attempt, reproducible from
   the attempt's seed, never the file order. Add a pure helper (engine or a small app util) with
   a test that the best option isn't always first.
4. **Timer:** none in untimed missions (`Mission.timed == false`, Mission 1). Timed missions dim
   the light; `answer_timer_expired` when it runs out (the timer never forces a choice or costs
   score, per FR-13).
5. **Progress through Chapter 1:** after the dossier, continue to the next mission (a simple
   cut for now; the elevator and tower are brief 13). Mission 1's first completion records the
   baseline (`baseline_recorded`, `user_activated`); `mission_started`, `follow_up_answered`,
   `mission_completed`.
6. **Saving progress, before brief 08 lands:** create
   `apps/mobile/lib/core/progress/progress_repository.dart`: an interface (`recordAttempt`,
   `attempts`, `baseline`), an in-memory implementation and its provider. Brief 08 implements it
   on drift and overrides the provider; your screens never change.
7. **Sound:** `apps/mobile/lib/core/audio/game_sounds.dart` is already on this branch (the lead
   wrote it; the identical file is on brief 09's branch, which runs **in parallel** and
   implements it). Call `gameSoundsProvider` at every moment it names, and wire
   `subtitleCharacter` to the typewriter's `onCharacter`. Don't change its signatures (ask the
   lead; additions are fine). Pair haptics with choice, lock-in and stamp.
8. **States:** loading, error (cinematic, never raw exception text) and the offline state for
   anything that would need the network (nothing in this brief does).
9. **Tests:** a widget test that plays Mission 1 end to end with fakes (a known path gives the
   engine's known score on the dossier); untimed Mission 1 shows no timer; the shuffle helper;
   reduced motion; 2x text on the scene and dossier; events fire once each.

## Out of scope

- Tower home, elevator, Recall Room, Chapter 1 report, skill radar (13). Notifications (11).
- Onboarding after Mission 1 and "Save your progress" (they need 08's services; brief 13).
- Sound files and `AudioService` (09, in parallel), the drift database (08), the AI coach (12).

## File ownership (touch only these)

- `apps/mobile/lib/features/{intro,mission,debrief}/**` (new), `apps/mobile/lib/core/progress/**`
  (new), `apps/mobile/lib/ui/figure/{silhouette_figure,interviewer_silhouette}.dart` (the rim-dot fix),
  `android/app/src/main/res/values*/styles.xml` and `apps/mobile/lib/app/app.dart` (edge to edge only),
  `apps/mobile/test/features/{intro,mission,debrief}/**`, `apps/mobile/test/core/progress/**`
- `apps/mobile/lib/app/router.dart`: your routes only (06b may add `/dev/catalog` in parallel;
  keep additions small, the lead resolves)
- The events enum + `docs/EVENTS.md` (only you this wave)
- A seeded-shuffle helper in `packages/engine` (one file + test), if you put it there
- `docs/status/10.md`, `.pr-screenshots/10/**`, your own `.claude-logs/` files

**Not yours:** `ui/**` and `packages/brand` (06b; ask for a component change in your status
file), `packages/content` (07 is merged; content bugs go to the lead), `core/{db,sync,backend}`,
pubspecs and `pubspec.lock`, CI, `scripts/`, `AGENTS.md`, `DESIGN.md`, `docs/HANDOFF.md`,
`docs/requirements.md`.

## Acceptance criteria

- [ ] Fresh clone, no env file, `flutter run -d chrome`: title → intro → character card →
      Mission 1 → dossier → Mission 2, all offline. A **recording of Mission 1 end to end**
      (Chrome, compressed) in the PR.
- [ ] The dossier's numbers equal `scoreAttempt` for the path played (test).
- [ ] Options appear in a shuffled, reproducible order; Mission 1 has no timer.
- [ ] The three owner fixes above, each with its test or a phone-sized Chrome still.
- [ ] Every `GameSounds` method is called at its moment (fake records the calls); no-op by default.
- [ ] Compressed stills (≤ 300 KB each) of the intro, character card, scene, a beat, the
      follow-up and the dossier.
- [ ] All local-review gates green; CI green; `docs/status/10.md` current.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/10.md`: done, half-done, next.
- **No phone:** test in Chrome and with widget tests; the lead checks Android in review.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
