# Brief 07: Missions 2–7 content (wave 2, worktree w2)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w2`, branch
`feat/07-missions-2-7`. **Timebox: PR up by Fri 30 Oct, evening**, so w2 can start brief 10 on Saturday.

## Goal

The rest of Chapter 1 as validated, scored content, in the voice Mission 1 set, so the mission
player (10) can play all seven missions without a single content change. Plus the locked
Chapter 2 and 3 teasers.

Read first: brief §3, §5, §6 (`docs/product-brief.md`), `docs/requirements.md` FR-12, FR-14,
FR-21, FR-30–FR-32, FR-40, the engine and content code (especially
`packages/content/lib/src/data/` and `m01_the_opportunity.dart`), and PR #5's content table.

## Hard rules

- Pure Dart content, validated by `validateContent`; the engine stays untouched.
- Distractors are **realistic mistakes, never jokes**. Plain English a non-native speaker reads
  easily. No real companies or people. Each interviewer sounds like one person throughout.
- Mission 1 is the untimed, unhinted baseline (owner-confirmed). Missions 3 and 7 are unhinted
  (brief §6); the others may have hint cards.

## The owner's writing notes (2026-10-30): apply to Mission 1 **and** Missions 2–7

The owner reviewed Mission 1. Rework M1 with these in its own `feat(content)` commit first, then
write M2–M7 to the same rules. More notes may follow through the lead.

1. **The right answer is too obvious.** It's always the longest, and the wrong ones are
   clichés. Every beat gets **one tempting wrong answer**: it sounds smart, but it has a hidden
   flaw (it dodges the question, takes credit for the team, is generic underneath the polish,
   over-promises). The review table marks it and names the flaw.
2. **Length gives nothing away.** Within a beat, options are within about ±20 % of each other's
   length, and across a mission the best option isn't the longest in more than a third of the
   beats (a test checks it). Wrong options aren't clichés: each is a mistake a real, decent
   candidate makes.
3. **The player plays a character.** Add a **player character sheet** in content: a fresh
   graduate (degree, one internship, one university project, one part-time job, a few concrete
   facts and numbers). Every option draws on those same facts, consistently across all seven
   missions. Mission 1's setup makes clear that you play this candidate; the draft-first prompt
   says it's for **your own words** about yourself (that's what "then vs. now" compares).
4. **Phone-length options:** about 20–25 words each. The validator fails anything over 30;
   interviewer lines stay within two subtitle lines.
5. *(lead)* **Same register across a beat:** no option is spottable by tone or formality alone.
6. *(lead)* **Every lesson names the hidden flaw** in one plain sentence the debrief can show.
7. *(lead)* **Screen order is not your job:** brief 10 shuffles options on screen with a seeded,
   reproducible order. Keep ids free of order hints (no `_a`, `_best`).

## In scope

1. **Interviewers** Marcus and Lena (and Sam for the Chapter 3 teaser only): name, role, one-line
   voice note. Ids stay `priya`, `marcus`, `lena`, `sam`: brief 09 keys typing sounds by them.
2. **Missions 2–7** exactly as brief §6 lists them, each with setup lines, the question, three
   beats (3–4 options each, four 0–3 scores and flags), follow-ups (one default, others
   triggered by flags), lessons and recall checks:
   - M2 Tell Me About Yourself (Priya): present → past → future; relevance over life story.
   - M3 The Experience Gap (Priya): first recall checkpoint, **no hint cards**; unlocks
     *Clear Introductions* when passed unhinted.
   - M4 Show Me the Evidence (Marcus): "I" vs "we"; vague picks trigger "What did *you* do?".
   - M5 Something Went Wrong (Marcus): STAR without sounding memorised; `blame` flags.
   - M6 The Follow-Up Trap (Lena): challenges the player's **costliest Mission 5 line**
     (spec decision: one variant per M5 option that can be costliest, ~12 at most, not 64).
     Model it in the schema in the smallest way the engine already supports; if it needs an
     engine change, stop and ask the lead.
   - M7 First Round Review (Priya + Marcus): a new question, **no hints**; report vs baseline;
     badge *Evidence Builder*; the cliffhanger line, then the Chapter 2 teaser.
3. **Chapters 2 and 3, locked:** titles and mission titles only (FR-31), for the tower teaser.
4. **The owner's writing notes** above: Mission 1 reworked first, in its own commit; later notes
   forwarded by the lead go in their own commits too.
5. **Tests:** every mission passes `validateContent`; M3 and M7 unhinted; each mission's best line
   ≥ 85 and worst ≤ 35; every flag a mission can raise has a lesson; M6 has a variant for every
   M5 option that can be costliest; ids prefixed by mission (`m02_…`).
6. **A content review table per mission** in the PR (option, scores, flags, one line of why).

## Out of scope

- Any UI, engine change, backend, sound. Chapter 2–3 missions beyond their titles.

## File ownership (parallel wave: touch only these)

- `packages/content/**`, `docs/status/07.md`, your own `.claude-logs/` files.

**Not yours:** `packages/engine` (ask the lead), `apps/`, pubspecs and `pubspec.lock`, CI,
`scripts/`, the events registry, `AGENTS.md`, `DESIGN.md`, `docs/HANDOFF.md`, `docs/requirements.md`.

## Acceptance criteria

- [ ] Missions 1–7 and both locked chapters in `gameContent`; all validation tests pass.
- [ ] The tests in item 5 exist and pass.
- [ ] Content review tables for M1 (reworked) and M2–M7 in the PR, each marking the tempting
      wrong answer and its flaw.
- [ ] Tests for notes 2 and 4 (length spread, best-not-longest ratio, ≤ 30 words) and the
      character sheet referenced by every mission.
- [ ] All local-review gates green; CI green; `docs/status/07.md` current. No screenshots (no UI).

## Events

None.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/07.md`: done, half-done, next.
- Only `dart test` needed; no Gradle, simulators or Docker.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
