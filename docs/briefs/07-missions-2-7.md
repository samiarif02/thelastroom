# Brief 07: Missions 2–7 content (wave 2, worktree w2)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w2`, branch
`feat/07-missions-2-7`. **Timebox: PR up by Sat 31 Oct, evening.**

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
4. **The owner's Mission 1 wording notes**, when they arrive (the owner sends them to the lead,
   who forwards them): applied in their own `feat(content)` commit.
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
- [ ] Content review tables for M2–M7 in the PR; the owner's M1 notes applied (or listed as
      pending if they haven't arrived).
- [ ] All local-review gates green; CI green; `docs/status/07.md` current. No screenshots (no UI).

## Events

None.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/07.md`: done, half-done, next.
- Only `dart test` needed; no Gradle, simulators or Docker.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
