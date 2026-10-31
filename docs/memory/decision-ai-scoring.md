---
name: decision-ai-scoring
description: The mission's answer is scored by an AI senior recruiter (Gemini via the score Edge Function); the engine's score is the "Offline score" fallback
type: project
---

Since brief 22 (2026-10-31, owner's request after reviewers asked "on what basis are you
scoring?"), the debrief asks the `score` Edge Function for a verdict: Gemini (`gemini-3.8-flash`),
temperature 0, four dimensions and an overall 0–100, one sentence of basis each, never advice.
The engine (`packages/engine`) still scores every attempt and is what the dossier shows when
there's no verdict within 8 s ("Offline score"); progress, the baseline and skills stay on the
engine. The key (`GEMINI_API_KEY`) is server-side only; 30 AI scores per player per day.

**Why:** the hand-scored rubric didn't answer reviewers' "on what basis"; a recruiter's stated
basis does, while the engine keeps the game offline and reproducible.
**How to apply:** don't send the player's name or typed text to the function; never let the UI
wait more than 8 s or show an error; ADR 0006 has the details. Related:
[[decision-engine-and-coach]], [[decision-offline-first-outbox]].
