# Completion audit

Every requirement in [`requirements.md`](requirements.md) and every phase of
[`v1-plan.md`](v1-plan.md), checked against `main` on 2026-11-01 (brief 29). The evidence is the
code and the merged PRs (`#N` links to github.com/samiarif02/thelastroom/pull/N).

**Status:** **Built**, **Partly** (some acceptance is missing; the gap says what), or **Not
built**. Every gap is either a **deliberate cut** (with the decision behind it) or **still
missing**.

## Summary

- **Built:** FR-1, 2, 4, 5, 10–14, 16, 17, 20–26, 31, 32, 40, 42, 51–53, 60–62, 70 and NFR-1, 2, 4–8
  (FR-4, 16, 32 and 42 completed by brief 32).
- **Deliberate cuts:**
  - FR-71, metrics: the owner, 1 Nov: events are defined and logged on the device; a PostHog sink
    is v2.
  - FR-3, email linking: the owner, #17.
  - The AI coach (FR-11 grading, FR-15 "Say it your way", FR-63, `coach_usage`): cut line #1,
    superseded by ADR 0006's AI scoring.
  - FR-50's extra reminder types: brief 26. iOS reminders: cut line #5.
- **Still missing:**
  - Mission 7's cliffhanger scene and "then vs. now" (brief 30);
  - the device performance pass (NFR-3, brief 31).

## Closing the gaps (the lead's plan, 2026-11-01)

| Gap | Goes to |
| --- | --- |
| XP, skill-unlock moments, the Evidence Builder badge, the weekly goal (FR-16, FR-30, FR-32, FR-42) | Brief 32, progression (thelastroom-9a) |
| The Mission 7 cliffhanger scene and "then vs. now" (FR-30, FR-41), plus the full Chapter 1 playthrough (phase 14) | Brief 30 (thelastroom-w2-c1) |
| The performance pass on a device (NFR-3) | Brief 31 (thelastroom-1e) |
| Metrics with an analytics backend (FR-71) | **Cut for v1** (owner, 1 Nov): PostHog is v2 |
| The interview date in onboarding (FR-4) | Brief 32 (thelastroom-9a), on the device, with the reminders' countdown |

## Functional requirements

| Req | What | Status | Evidence | Gap |
| --- | --- | --- | --- | --- |
| FR-1 | Splash → intro → Mission 1 as a guest | Built | #12, #24 (vivid splash, first launch to onboarding) | |
| FR-2 | Anonymous sign-in, offline-safe | Built | #7 (server), #17 (app) | |
| FR-3 | "Save your progress": link an email | Not built | | **Deliberate cut:** no sign-up, login or email linking in v1 (owner, #17); Google sign-in is v2. `account_linked` stays registered, unfired |
| FR-4 | Onboarding: role, nerves (calm mode), interview date | Built | #15 (role, nerves, name; calm mode), brief 32 (an optional interview-date step, kept on the device, counted down in reminders) | |
| FR-5 | Missions 2–7 → Chapter 1 report → Chapter 2 teaser → D1 (waitlist) | Built | #9, #15, #30 (report, teaser, `joinWaitlist`) | |
| FR-10 | Scene, typewriter subtitles, tap to complete | Built | #12, #19, #21 | |
| FR-11 | Draft first, stored; coach grading online | Partly | #12 (draft stored, never logged) | Coach grading: **deliberate cut** (cut line #1, ADR 0006) |
| FR-12 | Three beats, 3–4 plausible options | Built | #5, #12, #19 | "No shuffle" was replaced by a seeded per-attempt shuffle (owner note, brief 10); replays stay reproducible |
| FR-13 | Soft 60 s timer on timed missions; calm mode | Built | #12, #15 (calm mode in Your file) | |
| FR-14 | Follow-up at the weakest part, scored for adaptability | Built | #5, #12, #18 (a guess is the weakest) | |
| FR-15 | Dossier: four scores, one lesson, red pen; "Say it your way" | Partly | #12, #19, #25 | "Say it your way": **deliberate cut** (cut line #1, ADR 0006) |
| FR-16 | Progress: XP, skills unlocked, Recall Room cards | Built | #23 (cards from every trap), brief 32 (XP from missions and recall rounds, "+N XP" and the "Skill unlocked" card on the debrief, `skill_unlocked` fired) | |
| FR-17 | Sound: ticks, cues, ambience, settings | Built | #13, #14 | |
| FR-20 | Deterministic weighted scoring | Built | #5 | |
| FR-21 | Flags lower dimensions, drive the follow-up | Built | #5 | |
| FR-22 | Structure is the weakest beat | Built | #5 | |
| FR-23 | Weights documented as a hypothesis | Built | #29 (README "How the score works", "Honest limits") | |
| FR-24 | AI senior recruiter scores (Gemini) | Built | #25, #26 (Deno tests in CI) | Verified with a mocked Gemini; the live run on a phone is still to do (README) |
| FR-25 | A guessed beat scores 0 | Built | #18 | |
| FR-26 | The reason counts (principles, 60 %) | Built | #18 | |
| FR-30 | Chapter 1 as specified (baseline, M3 checkpoint, M6 continuity, M7 review, badge, cliffhanger, teaser) | Partly | #5, #9 (all seven missions, continuity, M3 unhinted), #30 (report, teaser) | The *Evidence Builder* badge: brief 32. **Still missing:** the cliffhanger (brief 30): Mission 7's epilogue lines are in content but no screen plays them |
| FR-31 | Chapters 2–3 visible, locked, teased | Built | #15, #20, #30 ("Coming soon") | |
| FR-32 | Skill tree; unlock only when demonstrated unhinted | Built | #5 (engine rule, tested), #20, #30 (radar), brief 32 (badges on the tower and in Your file; a locked badge says where it's earned) | |
| FR-40 | Recall Room, Leitner 1/3/7 | Built | #23 | Rounds are one minute (5 cards), not two (brief 21) |
| FR-41 | Skill radar baseline vs now; "then vs. now" drafts | Partly | #30 (two radars, baseline vs review) | **Still missing:** the Mission 1 draft beside the latest |
| FR-42 | No lives or streak shaming; soft weekly goal | Built | No lives, no shaming; brief 32 (a "2 of 3 sessions this week" ring, reset on Monday, never punishing) | |
| FR-50 | Local reminders in character | Partly | #33 (recall due, daily nudge, 3 wordings each) | Cliffhanger, comeback and weekly-win types: **deliberate cut** (brief 26 scope) |
| FR-51 | Max 1/day, never after 21:00, back-off, off switch, deep links | Built | #33 | One switch, not per type (brief 26) |
| FR-52 | Permission after Mission 1, behind an explainer | Built | #33 | Android checked on the realme; iOS **deliberate cut** (cut line #5): wired, untested |
| FR-53 | Web: no reminders, Settings says so | Built | #33 | |
| FR-60 | Local first, idempotent outbox | Built | #12, #17 | |
| FR-61 | Restore on a fresh install | Built | #17 | |
| FR-62 | Tables with owner-only RLS, tested | Built | #7, #25 | `coach_usage` replaced by `ai_scores` and `ai_score_usage` (ADR 0006) |
| FR-63 | Coach Edge Function | Not built | | **Deliberate cut** (cut line #1); the `score` function (#25) took its place |
| FR-70 | Events registered first, no PII | Built | #3, every feature PR; `check:events` in CI | Not yet fired: `account_linked` (FR-3 cut), `skill_unlocked` (FR-16 gap), `coach_feedback_requested` (cut) |
| FR-71 | Metrics: activation, D1/D3/D7, deltas, open rates | Not built | Every event is defined, registered and logged on the device (`LogAnalytics`) | **Deliberate cut** (owner, 1 Nov): events are defined and logged locally; a PostHog sink is v2 |

## Non-functional requirements

| Req | What | Status | Evidence | Gap |
| --- | --- | --- | --- | --- |
| NFR-1 | Cinematic design, no stock Material, tokens only | Built | #6, #10, #11, #16, #20, #21, #32, #35 | |
| NFR-2 | Accessibility: AA, 44 pt, 2x text, reduced motion, labels | Built | #11 (contrast tests), widget tests at 2x text and reduced motion across features | |
| NFR-3 | 60 fps mid-range Android; web first frame < 3 s | Partly | Branded web loader (#11, #24); profile APKs build | **Still missing:** no profile or jank pass on a device was ever recorded (status 06: "no device connected") |
| NFR-4 | Chapter 1 offline; designed offline states | Built | #12, #17, #30 (every store failure has a designed card) | |
| NFR-5 | No secret in the app | Built | #1, #17, #25; `check:secrets` in CI | |
| NFR-6 | Honesty | Built | #29 (README "Honest limits") | |
| NFR-7 | Quality gates, goldens, `/dev/catalog` | Built | #1, #11, every PR green | |
| NFR-8 | Zero setup | Built | #4, #7 (test boots with an empty `Env`) | |

## Plan phases

| Phase | What | Status | PRs | Gap |
| --- | --- | --- | --- | --- |
| 01 | Foundation | Built | #1 | |
| 02 | Spec v1 | Built | #3 | |
| 03 | Cinematic direction | Built | #6 | |
| 04 | Engine and Mission 1 | Built | #5 | |
| 05 | Supabase | Built | #7 | |
| 06 | Design system | Built | #10, #11 | |
| 07 | Missions 2–7 | Built | #9 | |
| 08 | Auth and sync | Partly | #17 | Email linking: deliberate cut (FR-3) |
| 09 | Sound | Built | #13, #14 | |
| 10 | Mission player | Built | #12, #19, #21 | |
| 11 | Notifications | Partly | #33 | iOS untested, extra types (FR-50): deliberate cuts |
| 12 | AI coach | Not built | (#25 instead) | Deliberate cut, cut line #1; replaced by AI scoring (ADR 0006) |
| 13 | Tower, elevator, Recall Room, report | Partly | #15, #20, #23, #30 | XP, skill unlocks, weekly goal, "then vs. now", the cliffhanger scene |
| 14 | Dogfood, APK, release | Partly | #29 (release workflow, draft `v0.1.0`) | No recorded full Chapter 1 playthrough on device, no profile pass (NFR-3); metrics (FR-71) cut for v1 |
| 15 | Submission | Partly | #29, this PR | Demo video (owner); the paywall mock and the demo script land here |
