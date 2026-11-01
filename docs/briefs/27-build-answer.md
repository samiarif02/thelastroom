# Brief 27: Build your answer (worktree w2)

Lead session (w1-ba), 2026-11-01. Branch `feat/27-build-answer` from `origin/main`. Session:
thelastroom-w2-c1. Recorded here from the lead's message.

## Why

A second way to play, so a mission isn't only tap-a-card. The owner wants missions more
interactive and more fun.

## The idea

In some beats, instead of picking one of 3–4 full lines, the player **assembles** the answer from
4–5 short fragments:

- they tap fragments in order (Situation → Task → Action → Result for "tell me about a time"
  beats);
- one fragment is a decoy (vague, "we" not "I", or blame);
- the line builds live in the subtitle as they tap;
- Priya reacts to the result.

Scoring maps to the existing engine: the order, plus leaving the decoy out, gives the dimension
scores, explainable like the rest. The debrief shows the built line next to the strong one.

## Owns

`features/mission`, `features/debrief`, and for this brief `packages/content` and
`packages/engine` (9a, on notifications, has released them). Keep the existing contract working.

## In scope

1. **Content + engine:** a new optional `BuildBeat` in `packages/content` (fragments, the right
   order, decoys) and a pure engine scorer with unit tests. The validator enforces its shape.
   At least 3 beats across Missions 4–7 (the STAR-type questions) use it.
2. **UI in `features/mission`:** big tappable fragment chips (vivid kit), one tap places or
   removes a fragment, a "Lock it in" button, guess timing as usual, reduced motion respected.
3. **Events registered first** (`AnalyticsEvent` enum + `docs/EVENTS.md`).

## Done when

local-review green, PR open (never merged), link sent to the lead.
