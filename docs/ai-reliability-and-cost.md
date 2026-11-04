# AI scoring: when it's wrong, and what it costs

The reviewer's question (2 Nov): *what happens if the AI is wrong, if it isn't evaluating
properly, and what does the AI cost?* This page answers both with what the code does and what
was measured. The full accuracy study is [scoring-eval.md](scoring-eval.md).

## What the AI does, and doesn't do

- The AI **scores**; it never writes questions. Every question, answer line, reason and follow-up
  is authored content in `packages/content`, validated by tests. So "the AI generates a bad
  question" can't happen.
- It scores one finished room: the question, the lines picked, the reasons, guesses and the
  follow-up (or, in a voice room, what was said). The player's name is never sent.

## When the AI is wrong or unavailable

| Failure | What the player sees | Where |
| --- | --- | --- |
| No network, no backend, or the key is missing | The game's own deterministic score, labelled **"Offline score"**; nothing breaks | `features/debrief/ai_score.dart`, ADR 0005 |
| Slow model (over 8 s) | The offline score at once; a late AI verdict (up to 30 s) replaces it, and the label changes | `AiScorer.timeout`, `lateLimit` |
| A model errors or rate-limits (429/503) | The next model in the chain answers: 3.5 Flash-Lite → 3.6 Flash → 3.1 Flash-Lite | `supabase/functions/score/gemini.ts` |
| Malformed output | `parseVerdict` repairs what is safe (a score outside 0–100 is clamped, a decimal rounded, a long basis cut to one sentence); text that isn't JSON or a missing field is an error, and the next model or the offline score answers | `score/scoring.ts` + tests |
| The AI is generous to guessing | Prompt rules cap an all-guessed room (overall ≤ 40, specificity ≤ 20); a good-sounding reason never rescues a weak line | `score/scoring.ts` |
| The AI disagrees with the rules | Every result shows **"How we scored this"**: the AI's basis per skill next to the game's own number, so a player can see both | `scoring_basis_sheet.dart` |
| A player spams it | 30 AI scores per player per UTC day, enforced in Postgres (`claim_ai_score()`); past that, the offline score | `20261031130000_ai_scores.sql` |

**How we know it's accurate:** 63 of 63 evaluation cases returned a verdict, 92% landed in their
expected band, all 7 missions ranked right (a strong run above both a weak and a guessed one), and
the AI's overall score correlates r = 0.91 with the game's deterministic score
([scoring-eval.md](scoring-eval.md)). The deterministic engine is the reference that ships
offline, so the AI can never take the game below its own floor.

## What it costs

Measured on the owner's realme on 3 Nov (local backend, `functions.log`): one choice-room score
on `gemini-3.5-flash-lite` used **639 input and 215 output tokens** and took **1.9–2.1 s**.

At Google's standard paid price for Gemini 3.5 Flash-Lite ($0.30 per 1M input tokens, $2.50 per
1M output tokens, thinking included; [pricing](https://ai.google.dev/gemini-api/docs/pricing)):

| | Cost |
| --- | --- |
| One AI score | 639 × $0.30/1M + 215 × $2.50/1M ≈ **$0.0007** |
| A player at the daily cap (30 scores) | ≈ **$0.022 a day** |
| 1,000 daily players × 3 rooms each | ≈ **$2.20 a day** (≈ $66 a month) |
| Batch pricing (half price), if scoring could wait | ≈ $0.00036 a score |

Today the key is on Gemini's **free tier**, so the running cost is $0; its per-model rate limits
are what the fallback chain and the offline score absorb. Voice rooms send audio, which costs more
per score; their token use wasn't measured yet. That's the first number to log before paid use.

**Cost controls already in place:** minimal thinking on every model (thinking tokens are billed as
output), a short structured prompt, one call per finished room (not per answer), the 30-a-day
cap, and the offline score for everything else.
