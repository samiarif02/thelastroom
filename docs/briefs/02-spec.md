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

10. **Web host: decided by the owner (2026-10-29): Vercel.** The site is built in GitHub
    Actions (`flutter build web --release`), not by Vercel's builder, and deployed prebuilt
    (Vercel CLI, `vercel deploy --prebuilt`). Every PR gets a **preview URL**, which lead reviews
    and outside reviewers use; `main` deploys to **production**. Record D3 as decided in
    `docs/requirements.md` and `docs/rules/deployment.md`, then plan it in `docs/v1-plan.md` as
    its own small milestone, **02b, merged Thursday morning before 03a**, so the direction
    prototypes can be compared on a phone through a preview link. The plan covers:
    - CI job shape: build once, deploy a preview on `pull_request` and production on `push` to
      `main`; the preview URL is posted on the PR (comment or deployment status), and fork PRs
      get no secrets.
    - `vercel.json`: SPA rewrite to `index.html`, cache headers (hashed assets immutable,
      `index.html` and `flutter_service_worker.js` no-cache), and the headers drift's WASM
      needs later (COOP/COEP), with a note on what they break.
    - Secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` as **GitHub Actions
      secrets only** (`docs/rules/secrets.md`); `check:secrets` must not flag the workflow.
    - **Owner steps**, listed exactly: create the Vercel project, create the token, add the
      three repo secrets. The 02b worker stops and asks for them; it never guesses.

## Out of scope

- The Vercel workflow and `vercel.json` themselves (that's 02b).
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
- [ ] D3 recorded as Vercel; 02b planned (workflow shape, `vercel.json`, secrets, owner steps).
- [ ] "Where the brief is wrong or risky" has ≥ 3 points, each with a proposed change.
- [ ] All local-review gates green; CI green; `docs/HANDOFF.md` updated.
- [ ] PR description: summary, the D1 argument, the challenges, gate table. **No screenshots
      needed** (no UI change); say so.

## Events

None fired. Register any the slice needs that are missing (item 7).

## Likely files

`docs/requirements.md`, `docs/v1-plan.md` (new), `docs/decisions/000{1..4}-*.md` (new),
`docs/memory/decision-*.md`, `docs/rules/deployment.md`, `docs/EVENTS.md`, `packages/content/lib/src/*.dart`,
`packages/content/test/*`, `packages/engine/lib/src/*.dart`, `packages/engine/test/*`,
`apps/mobile/lib/core/analytics/*.dart`, `apps/mobile/test/core/*`, `docs/HANDOFF.md`.

## Worker prompt (type it yourself, in your own words)

> Worker: do docs/briefs/02-spec.md. Read AGENTS.md and docs/HANDOFF.md first. Own branch,
> local-review, PR, CI green, don't merge. Done tonight.

**First commit on the worker's branch:** the lead leaves this brief and its `docs/HANDOFF.md`
changes uncommitted on `main`. Commit them first, as they are, in their own `docs:` commit, then
start the work.
