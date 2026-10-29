# Brief 02: Spec v1 (before any feature code)

Written by the lead session, 2026-10-29, after PR #1 merged. One worker session, one PR.
**Timebox: done tonight (Wed 29 Oct).** Tomorrow noon is the design-direction pick (03a), so this
can't slip into Thursday.

## Goal

Turn the brief into a plan a worker can build from without guessing: the thin vertical slice
first (Mission 1 playable offline, end to end), the content schema and engine API as **types
only**, the ADRs, and the owner's open decisions answered or argued.

## In scope

1. **`docs/requirements.md` stays the requirements file** (don't create a second one). Tighten
   it: add acceptance criteria (Given/When/Then, or a checkable bullet) to every FR the slice
   needs (FR-1, FR-10–FR-16, FR-20–FR-22, FR-60, FR-70), and to NFR-1/NFR-4. Mark each FR with
   the plan milestone it lands in.
2. **`docs/v1-plan.md`**: milestones in build order, each one a PR-sized slice with its brief
   number, rough size (S/M/L) and the day it should merge (deadline 5 Nov; see the plan table in
   `docs/HANDOFF.md`). Order: design direction → design system → content + engine → **Mission 1
   playable offline + web demo live (Fri 31 Oct)** → auth + sync → home/recall/report →
   notifications → (coach only if ahead) → dogfood/ship → submission. Name the cut line: what
   gets dropped first if we slip, in order.
3. **Content schema as types** in `packages/content` (mission, scene line, question, beat,
   option with per-dimension 0–3 scores and flags, follow-up, lesson, interviewer). Plus a
   validation test skeleton (ids unique, every option has 4 dimension scores in 0–3, every flag
   is from the closed set). No mission text beyond one tiny fixture.
4. **Engine API as types/signatures** in `packages/engine` (score a mission attempt, pick a
   follow-up, unlocks, Leitner schedule, baseline compare). Bodies may `throw
   UnimplementedError()`; the inputs and outputs are what matter. Time is passed in, never read
   (`AGENTS.md` non-negotiable 3). Doc comments say what each returns and why.
5. **Narrow `EventProperties`** (`apps/mobile/lib/core/analytics/analytics.dart`): today it's
   `Map<String, Object>`, which lets typed answer text through. Design a type that only admits
   ids, enum names, numbers and booleans (e.g. a sealed `EventValue`), with a test. Lead review
   flagged this on PR #1.
6. **ADRs** in `docs/decisions/` (`NNNN-slug.md`, context / decision / consequences / alternatives):
   offline-first + outbox, deterministic scoring vs AI, local vs remote notifications, Flutter
   widgets vs Flame. Link each from the matching `docs/memory/decision-*.md` (don't duplicate).
7. **Events:** check the 18 registered events against the slice. Anything the slice fires that
   isn't registered goes into the enum and `docs/EVENTS.md` **in this PR**.
8. **Decision D1** (after Chapter 1): the owner leans to the waitlist. Argue it in the PR (agree
   or disagree with a reason) and record the outcome in `docs/requirements.md`.
9. **Challenge the brief:** a short "Where the brief is wrong or risky" section in
   `docs/v1-plan.md` (at least 3 concrete points, e.g. a 4–6 minute mission vs a 10-second demo,
   the 60-second timer and accessibility, scope of 7 polished missions in 4 build days).

## Out of scope

- Any screen, widget or route. Any implementation inside the engine beyond signatures.
- Mission 2–7 content. Supabase migrations. Fonts, colours, the design direction (that's 03a).
- Renaming or restructuring existing docs beyond what's listed.

## Acceptance criteria

- [ ] `docs/v1-plan.md` exists with milestones, dates, sizes, brief numbers and an ordered cut list.
- [ ] Every slice FR in `docs/requirements.md` has acceptance criteria and a milestone.
- [ ] Content and engine types compile under `--fatal-infos`; the content validation test runs
      (against the one fixture) and passes; the engine has **no** Flutter or `dart:io` import
      and no `DateTime.now()`.
- [ ] `EventProperties` rejects free text at compile time; a test proves the allowed kinds work.
- [ ] 4 ADRs, linked from memory.
- [ ] D1 decided or argued, and recorded.
- [ ] "Where the brief is wrong or risky" has ≥ 3 points, each with a proposed change.
- [ ] All local-review gates green; CI green; `docs/HANDOFF.md` updated.
- [ ] PR description: summary, the D1 argument, the challenges, gate table. **No screenshots
      needed** (no UI change); say so.

## Events

None fired. Register any the slice needs that are missing (item 7).

## Likely files

`docs/requirements.md`, `docs/v1-plan.md` (new), `docs/decisions/000{1..4}-*.md` (new),
`docs/memory/decision-*.md`, `docs/EVENTS.md`, `packages/content/lib/src/*.dart`,
`packages/content/test/*`, `packages/engine/lib/src/*.dart`, `packages/engine/test/*`,
`apps/mobile/lib/core/analytics/*.dart`, `apps/mobile/test/core/*`, `docs/HANDOFF.md`.

## Worker prompt (type it yourself, in your own words)

> Worker: do docs/briefs/02-spec.md. Read AGENTS.md and docs/HANDOFF.md first. Own branch,
> local-review, PR, CI green, don't merge. Done tonight.
