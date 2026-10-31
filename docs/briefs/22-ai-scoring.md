# Brief 22: The AI scores the player (worktree w2)

Lead session (w1-ba), 2026-10-31, at the owner's request. Branch `feat/22-ai-scoring` from
`origin/main`. Session: thelastroom-w2-c1. Recorded here from the lead's message.

## Why

Reviewers asked "on what basis are you scoring?" The answer "fixed parameters" (hand-scored
lines and weights) didn't satisfy them. The owner wants the player's answers judged by AI acting
as a senior recruiter, with that score shown on the scoring screen. **Not a coach:** no advice,
no tips, only a score and its basis.

**Provider (owner's change, same day):** the key the owner has is a **Gemini** key, so the
`score` function calls Google's Gemini API (`generateContent` with a JSON response schema),
reading `GEMINI_API_KEY`. The model id is a named constant and is recorded in ADR 0006.

## Scope

1. **Edge Function `supabase/functions/score`** (Deno/TS), reading `GEMINI_API_KEY` with
   `Deno.env.get` (listed in `.env.example`, so `check:env` stays green).
   - Input: the mission's question and the interviewer's role; for each beat the line picked,
     the reason given and whether it was guessed (`decidedIn`); the follow-up question and the
     reply. **Never the player's name.**
   - A senior-recruiter system prompt ("You are a senior recruiter hiring for <role>…"),
     temperature 0. It grades relevance, specificity, structure and adaptability 0–100, plus an
     overall 0–100, with ONE short sentence of basis per number (why this score, not how to
     improve).
   - Structured JSON output, validated server-side; anything malformed is rejected or repaired.
   - Requires the player's Supabase JWT (anonymous auth exists). Rate limit per user (30/day)
     so the key can't be drained. Usage logged.
   - Deno unit tests with the API mocked.
2. **App** (`features/debrief` plus a small client):
   - The scoring screen shows "Scored by AI · Senior recruiter": the overall, the four
     dimensions and each one's basis.
   - While waiting, a designed loading state ("The panel is deliberating…") in the vivid style.
   - No backend (zero setup), no network or any error: the engine's score, labelled "Offline
     score". Never a raw error.
   - The engine still runs: offline play, the "You fell for" traps and the Recall Room.
3. **Persistence:** a migration adding the AI score to `mission_attempts`, RLS in the same
   migration, a pgTAP test (`docs/rules/migrations.md`); the local store if cheap.
4. **Docs:** ADR 0006 "AI scoring" (partly superseding 0003: why, privacy and what's sent,
   cost and the rate limit, offline fallback); FR-24 rewritten in `docs/requirements.md`;
   events `ai_score_requested`, `ai_score_shown`, `ai_score_fallback` (enum + `docs/EVENTS.md`),
   no answer text.

## Secrets

The key lives only server-side: never in the app, a commit or a log. Session logs are public, so
never print, echo or read it. The owner puts it in a gitignored `.env`. Tests use a mocked API;
the lead does the live check with the owner.

## Done when

local-review and CI green, PR open (never merged), link sent to the lead.
