# 0003. Deterministic scoring; AI only for free text

- **Status:** accepted (2026-10-29)
- **Memory:** [`docs/memory/decision-engine-and-coach.md`](../memory/decision-engine-and-coach.md)

## Context

The promise is *measurable* improvement (brief §1): a Mission 1 baseline compared with a
Mission 7 review, a skill radar, skills that unlock only when demonstrated. That needs scores
that are fair, explainable, the same every time, and available offline. Players are often
non-native English speakers, so grading style or grammar would be unfair and off-mission.

## Decision

- Scoring is a **pure-Dart engine** (`packages/engine`): every option is hand-scored 0–3 on four
  dimensions by the content author, flags (`vague`, `we_not_i`, …) are a closed enum, and the
  mission score is a fixed weighted formula (relevance 25 %, specificity 30 %, structure 25 %,
  adaptability 20 %). The engine reads no clock, does no I/O and is fully unit-tested.
- The **AI coach** grades only free text ("Say it your way", the Mission 1 draft), only when
  online, through a Supabase Edge Function that holds the API key, validates its JSON output,
  logs usage and allows 3 calls a day. It grades **content only**, never accent, grammar polish
  or style, and the UI says so (FR-24).
- Coach feedback never changes an engine score. It's advice beside the dossier, not a grade.

## Consequences

- Every score is reproducible from stored picks, so the baseline comparison is honest and a bug
  report can be replayed in a test.
- The weights are a hypothesis (the README says so): validating them needs human-rated samples,
  which we don't have.
- Quality rests on content: ~100 hand-scored lines in Chapter 1. The content validator checks
  their shape (ranges, flags cap their dimension, references resolve) but not their judgement;
  that's a review job.
- Multiple choice measures recognition, not production. The draft, the coach and the recall
  checkpoints are the mitigation, and the README states the limit.

## Alternatives considered

- **AI grades every answer.** Not offline, not reproducible, costs money per play, and can't be
  unit-tested; a baseline compared with a non-deterministic grader isn't a measurement.
- **AI-generated options at runtime.** Same problems, plus distractors that are jokes or
  accidentally correct.
- **Pure option-picking with no free text at all.** Simpler, but loses "then vs. now", the most
  personal evidence of progress.
