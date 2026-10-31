# 0006. An AI recruiter scores the answer; the engine stays for offline play

- **Status:** accepted (2026-10-31). Partly supersedes [0003](0003-deterministic-scoring-and-ai-coach.md):
  the engine is no longer the only scorer of the mission's answer.
- **Memory:** [`docs/memory/decision-ai-scoring.md`](../memory/decision-ai-scoring.md)
- **Brief:** [`docs/briefs/22-ai-scoring.md`](../briefs/22-ai-scoring.md)

## Context

Reviewers asked "on what basis are you scoring?" The honest answer was "fixed parameters": each
line hand-scored 0–3 by the content author, combined with fixed weights (0003). That's
reproducible and offline, but it's the author's judgement frozen into numbers, and the answer
didn't satisfy them. The owner wants the answer judged the way an interviewer would: by a senior
recruiter reading what the player built, with each number explained.

## Decision

- **The debrief asks an AI recruiter for the score.** A Supabase Edge Function, `score`, sends
  the answer to **Google Gemini** (`gemini-3.8-flash`, the constant `GEMINI_MODEL` in
  `supabase/functions/score/gemini.ts`) with a senior-recruiter system prompt, temperature 0 and
  a JSON response schema. It grades relevance, specificity, structure and adaptability 0–100,
  plus an overall 0–100, each with **one sentence of basis**: why this score. It gives no
  advice; it isn't a coach. The dossier says "Scored by AI · Senior recruiter".
  - Gemini because it's the key the owner has. Flash rather than `gemini-4-argon` because the
    player waits at most 8 seconds; Argon reasons longer than that.
  - The verdict is validated on the server: scores clamped to 0–100 and rounded, a basis cut to
    its first sentence, anything else malformed rejected (502), and the app falls back.
- **The engine still runs on every attempt** (`packages/engine`): it scores offline play, picks
  the follow-up, drives the trust meter, the "You fell for" traps, the red pen, the Recall Room
  and the baseline comparison. When there's no AI verdict, the dossier shows the engine's score,
  labelled **"Offline score"**.
- **What's sent (privacy):** the question, the interviewer's role, the job title, each beat's
  line, the reason the player gave, whether the beat was guessed, the follow-up and the reply.
  All of it is game content the player picked: **never the player's name**, nothing they typed
  (the draft stays on the device), no device or analytics ids. The function's log lines carry
  the mission id, token counts and timings: never the key, the JWT or any answer text.
- **The key is server-side only:** `GEMINI_API_KEY` in Edge Function secrets (`.env` locally,
  gitignored), sent to Google in the `x-goog-api-key` header, never in a URL. The app holds only
  the public anon key (docs/rules/secrets.md).
- **Who may call it:** only a signed-in player (the anonymous Supabase session; the function
  needs their JWT and every database call runs as them, under RLS).
- **Cost and rate limit:** each player may take **30 AI scores per UTC day**
  (`public.claim_ai_score()`, a security-definer function holding the limit, over
  `public.ai_score_usage`). One score is a few hundred input tokens and at most 1,024 output
  tokens on Flash, so a full day's quota costs a fraction of a cent.
- **Stored:** each verdict is a row in `public.ai_scores` (owner-only RLS, append-only), with
  the model that graded it. Not columns on `mission_attempts`: attempts are append-only and are
  often synced before the verdict arrives.
- **Offline fallback:** no backend (the zero-setup run), no session, no network, a timeout after
  8 seconds, a spent quota or any error: the engine's "Offline score". The player never sees an
  error, and nothing waits longer than 8 seconds.
- **Where it runs:** there's no hosted Supabase project, so AI scoring runs on the developer's
  Mac (`supabase start` + `supabase functions serve score`), reached over the LAN
  (README, "AI scoring locally").

## Consequences

- The scoring a reviewer sees has a stated basis, in a recruiter's words, for every number.
- The AI's score isn't reproducible the way the engine's is (temperature 0 narrows the spread
  but doesn't remove it), so progress over time (the baseline, the Chapter 1 report, unlocked
  skills) stays on the engine's scores, which are recomputable from stored picks.
- Two scores can disagree for one attempt. The dossier shows one (the AI's when it answered),
  labelled with its source.
- A new failure surface (Gemini, the network), contained by the 8-second fallback.

## Alternatives considered

- **Claude through the same function:** the first plan; changed because the owner's key is a
  Gemini key. The function's provider is one file (`gemini.ts`).
- **Re-weighting the engine or showing the 0–3 rubric:** more transparent, but still the
  author's fixed judgement, which is what reviewers questioned.
- **Scoring on the device:** would ship the key in the app (forbidden) or need an on-device
  model too large for the game.
