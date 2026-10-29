---
name: decision-engine-and-coach
description: Deterministic, unit-tested scoring engine offline; optional server-side AI coach (Edge Function) for free text only
type: project
---

Scoring is a **deterministic pure-Dart engine** (`packages/engine`): four dimensions (relevance
25%, specificity 30%, structure 25%, adaptability 20%), options scored 0–3 per dimension, mission
score normalised to 0–100, flags like `vague`/`we_not_i`/`blame`. The weights are a stated
hypothesis, not a validated rubric. The optional **AI coach** grades free text ("Say it your
way", Mission 1's draft) through a Supabase Edge Function `coach` that calls Claude with the key
server-side only, validates output, logs usage and enforces 3 per day. It grades **content
only, never accent, grammar polish or style**.

**Why:** fair, explainable and offline; the AI does only what needs AI.
**How to apply:** no network or clock in the engine; pick the coach model with the claude-api
skill when building it. Related: [[decision-offline-first-outbox]].

Full record, with alternatives: [ADR 0003](../decisions/0003-deterministic-scoring-and-ai-coach.md).
