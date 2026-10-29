# Brief 04: Engine + content schema + Mission 1 content (wave 1, worktree w2)

Written by the lead session, 2026-10-29 (Thu). Worktree `../thelastroom-w2`, branch
`feat/04-engine-content`. **Timebox: PR up by Fri 30 Oct, evening.**

## Goal

Make the engine real and give it its first real content: every function brief 02 declared in
`packages/engine` implemented and unit-tested, and **Mission 1 ("The Opportunity", Priya)**
written, scored and validated in `packages/content`. Pure Dart only. When this merges, the
mission player (09) has everything it needs except screens.

Read first: `docs/requirements.md` (FR-12, FR-14, FR-15, FR-20–FR-22, FR-30, FR-32, FR-40, FR-41),
brief §3, §4 and §6, `docs/decisions/0003-*.md`, `docs/rules/code-quality.md`, and the types
already in `packages/engine/lib/src/` and `packages/content/lib/src/`.

## Hard rules

- **The engine stays pure and deterministic** (AGENTS.md non-negotiable 3): no Flutter, no
  `dart:io`, no clock, no randomness without an injected seed. Same input, same output.
- **Zero setup / offline** (owner, 2026-10-29): content ships in the app as Dart; nothing is
  fetched.
- **Mission 1 is untimed** (owner confirmed, FR-13). It's the baseline: no hints, no model answer.
- Every threshold, weight and step is a **named constant** with a doc comment, never a literal.

## In scope

1. **Implement every engine function** brief 02 declared: `scoreAttempt`, `trustAfter`, follow-up
   choice, skill unlocks, Leitner recall scheduling, baseline comparison, score buckets. Remove
   every `UnimplementedError`.
2. **Structure scoring** (lead note on PR #3). Structure is the *weakest* beat's structure score,
   so one bad beat sinks the whole dimension. Keep that rule unless you can argue a better one
   in the PR, and prove it with **three worked examples as named tests**, each with the numbers
   in a comment, so the debrief can explain it in one sentence:
   - a strong answer (all beats 3 → structure 100),
   - one weak beat in an otherwise strong answer (3, 3, 1 → structure 33): the case a player
     will find unfair, so its lesson line must make sense,
   - an evenly middling answer (2, 2, 2 → structure 67).
   Copy the same three examples into the `scoreAttempt` doc comment.
3. **Trust meter formula** (lead note on PR #3). Replace "how far above or below a middling one"
   with an **exact formula** written in `trustAfter`'s doc comment, every term a named constant
   (start, the "middling" reference, step per point, clamp to 0–100). Add a worked table (pick by
   pick, for a strong run and a weak run) as a test. The meter must move visibly within one beat
   and never leave 0–100.
4. **Property-style tests** on scoring: the total is always 0–100; raising any one option's score
   never lowers the total; the same attempt scored twice gives the same `MissionScore`;
   `optionIdsByCost` ties go to the earliest pick.
5. **Mission 1 content** in `packages/content` (Priya; setup lines, the question, three beats
   Open → Evidence → Land with 3–4 options each, follow-ups with exactly one default, a lesson for
   every flag the mission can raise, recall checks for those lessons). Writing rules: a general
   entry-level / product role; distractors are **realistic mistakes, never jokes**; no real
   companies or people; plain English a non-native speaker reads easily; Priya sounds like one
   person throughout. `validateContent` passes.
6. **A content review table** for the owner in the PR: every option, its four scores, its flags
   and one line of why. The owner reviews the writing; expect edits.

## Out of scope

- Missions 2–7 (brief 07). Any UI, route or widget. Any backend. New dependencies.
- Changing the **public shapes the app already uses**: `Identified`, `contentIdPattern`
  (`apps/mobile/lib/core/analytics/event_value.dart` depends on them). If you must, stop and ask
  the lead.

## File ownership (parallel wave: touch only these)

- `packages/engine/**`, `packages/content/**`
- `docs/status/04.md`, your own `.claude-logs/` files

**Not yours** (if you need a change, write it in `docs/status/04.md` and tell the lead):
`apps/`, `pubspec.lock`, root `pubspec.yaml`, the events registry and `docs/EVENTS.md`, CI,
`package.json`, `scripts/`, `packages/brand`, `supabase/`, `AGENTS.md`, `DESIGN.md`,
`docs/HANDOFF.md`, `docs/requirements.md` (propose requirement changes in the PR instead).

## Acceptance criteria

- [ ] No `UnimplementedError` left in `packages/engine`; `engine-pure-dart` passes.
- [ ] The three structure examples and the trust table are named tests and in the doc comments.
- [ ] Property-style scoring tests pass; engine line coverage ≥ 90 % (`dart test --coverage`),
      reported in the PR.
- [ ] Mission 1 passes `validateContent`; a test asserts it's unhinted, untimed, and that its
      best line scores ≥ 90 and its worst ≤ 30 (so the baseline can show growth).
- [ ] The content review table is in the PR description.
- [ ] All local-review gates green; CI green; `docs/status/04.md` current.
- [ ] No screenshots (no UI); say so.

## Events

None fired (the engine never touches analytics). Score buckets you define here feed
`mission_completed.score_bucket` later; name them so they read well as enum names.

## How to work

- Never edit `docs/HANDOFF.md` (parallel mode). Keep `docs/status/04.md`: done, half-done, next.
- This brief needs only `dart test`; don't start Gradle, simulators or Docker (others share the Mac).
- Own branch, local-review, PR, CI green, never merge. End with the PR link.
