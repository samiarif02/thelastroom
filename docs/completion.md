# Completion audit

Every requirement in [`requirements.md`](requirements.md) and every phase of
[`v1-plan.md`](v1-plan.md), checked against `main` on 2026-11-01 (brief 29), then wave 6's
asks checked against `main` at `2233f80` on 2026-11-03 (below). The evidence is the
code and the merged PRs (`#N` links to github.com/samiarif02/thelastroom/pull/N).

**Status:** **Built**, **Partly** (some acceptance is missing; the gap says what), or **Not
built**. Every gap is either a **deliberate cut** (with the decision behind it) or **still
missing**.

## Wave 6 (2–3 Nov): the reviewer's asks, one by one

| Ask | Status | Evidence | Gap |
| --- | --- | --- | --- |
| A professional, sleek look; one app, not two | Built | The Daylight Tower: direction #52, brand/type/cast #55, every screen #56, Your file, report, onboarding, title #57 | The legacy vivid tokens stay in `packages/brand` for the kept Candidate assessment sheet (owner's rule) |
| Keep the debrief's Candidate assessment sheet | Built | `ui/paper/**` and its goldens unchanged since #56 (status 46, 48) | |
| A marketing landing page in `web/`, on Vercel | Built | #43, #48, #53, ADR 0007; live at https://thelastroom-ten.vercel.app | Store badges say "coming soon": the app isn't in a store |
| Chapters 2 and 3 playable: Chapter 2 all voice, Chapter 3 mixed | Built | #41 (7 voice rooms), #42 (3 built + 4 voice), #47 (opened), #49 (report → Chapter 2), #54 (every mission played to its debrief in a test) | |
| Answer out loud: spoken interviewer, record, pause on 5 s of silence, Continue, delete and retake | Built | #44 (`features/voice/`, `score-voice`), restyled in #56 | Offline, a spoken answer is scored by the player's self-check, not by the AI |
| "On what basis do you score, and how do you know it scores well?" | Built | #46: the basis on every result, "How we scored this", [scoring-eval.md](scoring-eval.md) (92 % in band, r = 0.91 with the engine) | The weights are still a hypothesis: no human-rated set yet |
| Live AI scoring on a real phone | Built | Status 51: release build on the realme over USB, rooms 2, 5, 6, 7 scored 92, 90, 85, 82 by Gemini | **Needs the backend running on a laptop:** no hosted Supabase by design (ADR 0005); without it the offline score shows. The free-tier key rate-limits heavy use |
| What the player learns from each mission | Built | `Mission.practises` shown before every room and on the debrief (wave-6 contract, #44, #46, #56) | |
| Bring players back on days 3 and 5 | Built | #51 (test reminder, the next reminder shown, welcome back, plan days 1/3/5/8), #56 (weekly ring, XP, skills, floor-cleared reward) | iOS reminders wired, untested; web has none (FR-53) |
| A floor sheet and doors on the tower | Built | #56 (doors, `FloorSheet`, `floor_previewed`) | |
| Past results | Built | #57 (`/tower/progress/room/:n` re-shows the stored sheet, latest vs best) | |
| First-time tips instead of a tour | Built | #57 (seven tips, `tip_shown` / `tip_done`, Settings → "Show tips again") | |
| Transitions and animated back controls | Built | #58 (shared axis, fade-through, the room opening from its door, sheets that settle, 150 ms fades under reduced motion) | **Predictive back only on Android 14+**; the owner's realme (Android 13) gets the normal reverse transition |
| On-device QA of the release build | Built | Status 51, #59 (the P0 missing `INTERNET` permission in release builds, now guarded by `check:standards`; Your file's latest vs best; resume hardening; copy fixes) | Only the realme 8 was tested; iOS never ran on a device |
| XP for each sound reason on the feedback sheet | Built | [#61](https://github.com/samiarif02/thelastroom/pull/61): sound +10, close +5, guess 0; +5 per voice point; derived from stored picks, so a resume can't award twice | |
| A shareable floor card ("Share your floor card") | Built | [#62](https://github.com/samiarif02/thelastroom/pull/62): a 1080 × 1350 card through the system share sheet, on the floor-cleared screen and the Chapter 1 report; `floor_card_shared` | |
| The resume bug from the phone check (BUG-2) | Fixed | [#63](https://github.com/samiarif02/thelastroom/pull/63): a tip's spotlight passed the tap to the reason card underneath; card tips now only close | |
| The APK release | Partly | The Release APK workflow and a draft release (#29) | Published only when the owner asks |

## Summary (2026-11-01, updated for wave 6)

- **Built:** FR-1, 2, 3 (status 60), 4, 5, 10–14, 16, 17, 20–26, 30–32, 40–42, 51–53, 60–62, 70 and NFR-1, 2,
  4–8 (FR-4, 16, 32 and 42 completed by brief 32; FR-30 and 41 by #39).
- **Deliberate cuts:**
  - FR-71, metrics: the owner, 1 Nov: events are defined and logged on the device; a PostHog sink
    is v2.
  - The AI coach (FR-11 grading, FR-15 "Say it your way", FR-63, `coach_usage`): cut line #1,
    superseded by ADR 0006's AI scoring.
  - FR-50's extra reminder types: brief 26. iOS reminders: cut line #5.
- **Still missing:**
  - NFR-3's one soft spot: the door → room transition drops 15 of 245 frames on the realme
    (every other path ≤ 8 over budget; [status 56](status/56.md)).

## Closing the gaps (the lead's plan, 2026-11-01; briefs 30–32 landed as #37, #38, #39)

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
| FR-3 | "Save your progress": link an email | Built | Status 60: Settings' "Save your progress" card links the guest's email with a six-digit code (same user id), "Sign in on another device" merges the account in (attempts a union, the account's profile wins); `account_linked`, `account_signed_in`; a widget test per state | Google sign-in is v2. The local stack needs a restart for the code templates; a hosted project needs them in its dashboard. Not yet offered from the Chapter 2 waitlist |
| FR-4 | Onboarding: role, nerves (calm mode), interview date | Built | #15 (role, nerves, name; calm mode), brief 32 (an optional interview-date step, kept on the device, counted down in reminders) | |
| FR-5 | Missions 2–7 → Chapter 1 report → Chapter 2 teaser → D1 (waitlist) | Built | #9, #15, #30 (report, teaser, `joinWaitlist`) | |
| FR-10 | Scene, typewriter subtitles, tap to complete | Built | #12, #19, #21 | |
| FR-11 | Draft first, stored; coach grading online | Partly | #12 (draft stored, never logged) | Coach grading: **deliberate cut** (cut line #1, ADR 0006) |
| FR-12 | Three beats, 3–4 plausible options | Built | #5, #12, #19 | "No shuffle" was replaced by a seeded per-attempt shuffle (owner note, brief 10); replays stay reproducible |
| FR-13 | Soft 60 s timer on timed missions; calm mode | Built | #12, #15 (calm mode in Your file) | |
| FR-14 | Follow-up at the weakest part, scored for adaptability | Built | #5, #12, #18 (a guess is the weakest) | |
| FR-15 | Dossier: four scores, one lesson, red pen; "Say it your way" | Partly | #12, #19, #25 | "Say it your way": **deliberate cut** (cut line #1, ADR 0006) |
| FR-16 | Progress: XP, skills unlocked, Recall Room cards | Built | #23 (cards from every trap), brief 32 (XP from missions and recall rounds, "+N XP" and the "Skill unlocked" card on the debrief, `skill_unlocked` fired), brief 55 (XP per explained reason: sound +10, close +5, guess 0; +5 per voice point; the feedback sheet's "+10 XP" and the debrief's room/reasons breakdown) | |
| FR-17 | Sound: ticks, cues, ambience, settings | Built | #13, #14 | |
| FR-20 | Deterministic weighted scoring | Built | #5 | |
| FR-21 | Flags lower dimensions, drive the follow-up | Built | #5 | |
| FR-22 | Structure is the weakest beat | Built | #5 | |
| FR-23 | Weights documented as a hypothesis | Built | #29 (README "How the score works", "Honest limits") | |
| FR-24 | AI senior recruiter scores (Gemini) | Built | #25, #26 (Deno tests in CI), #46 (live eval), status 51 (live on the realme) | Needs the local backend: no hosted Supabase (ADR 0005) |
| FR-25 | A guessed beat scores 0 | Built | #18 | |
| FR-26 | The reason counts (principles, 60 %) | Built | #18 | |
| FR-30 | Chapter 1 as specified (baseline, M3 checkpoint, M6 continuity, M7 review, badge, cliffhanger, teaser) | Built | #5, #9 (all seven missions, continuity, M3 unhinted), #30 (report, teaser), #38 (the badge), #39 (the cliffhanger epilogue), #56 (floor-cleared reward) | |
| FR-31 | Chapters 2–3 visible, locked, teased | Built | #15, #20, #30; since wave 6 both are playable (#41, #42, #47) and open floor by floor | |
| FR-32 | Skill tree; unlock only when demonstrated unhinted | Built | #5 (engine rule, tested), #20, #30 (radar), brief 32 (badges on the tower and in Your file; a locked badge says where it's earned) | |
| FR-40 | Recall Room, Leitner 1/3/7 | Built | #23 | Rounds are one minute (5 cards), not two (brief 21) |
| FR-41 | Skill radar baseline vs now; "then vs. now" drafts | Built | #30 (two radars), #39 (then and now), #57 (in the report and room 7's debrief) | |
| FR-42 | No lives or streak shaming; soft weekly goal | Built | No lives, no shaming; brief 32 (a "2 of 3 sessions this week" ring, reset on Monday, never punishing) | |
| FR-50 | Local reminders in character | Partly | #33 (recall due, daily nudge, 3 wordings each), #51 (days 1/3/5/8, test reminder, welcome back) | Cliffhanger and weekly-win types: **deliberate cut** (brief 26 scope) |
| FR-51 | Max 1/day, never after 21:00, back-off, off switch, deep links | Built | #33 | One switch, not per type (brief 26) |
| FR-52 | Permission after Mission 1, behind an explainer | Built | #33 | Android checked on the realme; iOS **deliberate cut** (cut line #5): wired, untested |
| FR-53 | Web: no reminders, Settings says so | Built | #33 | |
| FR-60 | Local first, idempotent outbox | Built | #12, #17 | |
| FR-61 | Restore on a fresh install | Built | #17 | |
| FR-62 | Tables with owner-only RLS, tested | Built | #7, #25 | `coach_usage` replaced by `ai_scores` and `ai_score_usage` (ADR 0006) |
| FR-63 | Coach Edge Function | Not built | | **Deliberate cut** (cut line #1); the `score` function (#25) took its place |
| FR-70 | Events registered first, no PII | Built | #3, every feature PR; `check:events` in CI | Not yet fired: `skill_unlocked` (FR-16 gap), `coach_feedback_requested` (cut) |
| FR-71 | Metrics: activation, D1/D3/D7, deltas, open rates | Not built | Every event is defined, registered and logged on the device (`LogAnalytics`) | **Deliberate cut** (owner, 1 Nov): events are defined and logged locally; a PostHog sink is v2 |

## Non-functional requirements

| Req | What | Status | Evidence | Gap |
| --- | --- | --- | --- | --- |
| NFR-1 | Cinematic design, no stock Material, tokens only | Built | #6, #10, #11, #16, #20, #21, #32, #35 | |
| NFR-2 | Accessibility: AA, 44 pt, 2x text, reduced motion, labels | Built | #11 (contrast tests), widget tests at 2x text and reduced motion across features | |
| NFR-3 | 60 fps mid-range Android; web first frame < 3 s | Partly | Branded web loader (#11, #24); #37 (a profile web bundle measured in Chrome, idle faces stilled); #63 (the device harness, idle repaint cuts); the realme run, 3 Nov ([status 56](status/56.md)): every path's p90 under 16.6 ms on build and raster, 38 of 3,108 frames over budget (1.2%) | The door → room transition drops 15 of 245 frames (raster p99 33 ms); web first frame not re-measured since #37 |
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
| 08 | Auth and sync | Built | #17, status 60 (FR-3) | |
| 09 | Sound | Built | #13, #14 | |
| 10 | Mission player | Built | #12, #19, #21 | |
| 11 | Notifications | Partly | #33 | iOS untested, extra types (FR-50): deliberate cuts |
| 12 | AI coach | Not built | (#25 instead) | Deliberate cut, cut line #1; replaced by AI scoring (ADR 0006) |
| 13 | Tower, elevator, Recall Room, report | Built | #15, #20, #23, #30, #38, #39, then the Daylight tower #56, #57 | |
| 14 | Dogfood, APK, release | Partly | #29 (release workflow, draft `v0.1.0`), #39 (Chapter 1 playthrough), status 51 + #59 (Chapter 1 to the end on the realme, release build) | The NFR-3 run done on the realme (status 56); the APK release waits for the owner; metrics (FR-71) cut for v1 |
| 15 | Submission | Built | #29, #36, #49, the wave-6 docs PR; the demo video submitted by the owner | |
