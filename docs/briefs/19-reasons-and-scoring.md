# Brief 19: Reasons, reactions and fair scoring (worktree w4)

Lead session, 2026-10-31. Worktree `../thelastroom-w4`, branch `feat/19-reasons-scoring` from
`origin/lead/wave-5`. Session: thelastroom-9a. Read `docs/briefs/wave-5.md` first, especially
**the contract**.

## Why

Random clicking currently earns a score. Wave 5 adds a "why that line?" step, live interviewer
reactions and guess detection. Brief 18 plays them; **you write the content and the scoring
rules**, so the score rewards thinking.

## Owns

`packages/engine/**`, `packages/content/**` (all seven missions, lessons, validation) and
`apps/mobile/lib/core/audio/**` (only if brief 18 asks for a sound hook). Keep `packages/engine`
pure and deterministic (non-negotiable 3).

## In scope

1. **Scoring (engine), explainable, with unit tests for every rule:**
   - **A guessed beat** (`pick.guessed`) scores 0 on every dimension and carries a new flag,
     `guessed`, which the debrief explains.
   - **The reason counts.** A sound reason keeps the pick's points. An unsound reason costs a
     visible, fixed share of that beat's points. Name the constant (proposal: keep 60 %), and the
     debrief says why.
   - `judgePick` stays the single rule for the live reaction. Refine it if needed, keeping the
     signature (or agree a change with the lead and brief 18).
   - Saved attempts without `decidedIn`/`reason` still score exactly as before (old data).
2. **Content for Missions 1–7, every beat:**
   - a `why`: the interviewer's question in her own voice, plus 3–4 reasons. Exactly one reason
     is sound for each option; misconceptions are realistic, never jokes;
   - a `reaction`: strong, weak and guessed lines per interviewer, short and in character.
     Guessed lines are gently sharp, never cruel.
   Add lessons where a reason teaches something new.
3. **Validation** (`validation.dart` + tests):
   - every beat in every playable mission has `why` and `reaction`;
   - every option has exactly one sound reason;
   - reason ids are unique;
   - `soundFor` only names options of that beat.
4. **Docs**: the scoring section of `docs/requirements.md` or an ADR note says how guesses and
   reasons change the score. Ask the lead which file.

## Done when

`dart test` in engine and content covers the new rules. All seven missions are fully filled and
validated. Gates are green. Tell the lead and brief 18 (thelastroom-w2-c1) the moment Mission 1's
content is on your pushed branch, so 18 can play it early.
