# Brief 24: Completeness (worktree w2)

Lead session (w1-ba), 2026-11-01. Branch `feat/24-completeness` from `origin/main`. Session:
thelastroom-w2-c1. Recorded here from the lead's message.

## Why

Completeness scored 6/10 in the owner's first review. Everything a player can reach must work
and lead somewhere, and the AI scoring (brief 22) and the progress story must show up outside
the debrief.

## Owns

`features/mission`, `features/debrief`, `features/progress`. 1e has moved to other screens; tell
them about any change to `lib/ui`.

## In scope

1. **Your file shows the AI scores:** per mission, the AI's overall and its dimensions when
   there is one (from `ai_scores` and the local store), else the offline score, labelled as on
   the debrief ("Scored by AI · Senior recruiter" / "Offline score").
2. **The Chapter 1 report:** after Mission 7, or from Your file once Mission 7 is done, the
   player against their first try (the Mission 1 baseline vs the latest) per skill, with the
   radar. Honest wording; the engine's baseline comparison already exists.
3. **The Leave-mission sheet** in the vivid style (it's still cream).
4. **No dead ends.** Audit every button and route: locked chapters and missions explain how they
   open; Mission 7's end leads somewhere sensible; replaying a finished mission works; every
   empty, offline and error state is designed. Fix what's found, and list the audit in the PR.

## Done when

local-review green, PR open with the audit (never merged), link sent to the lead.
