# v1 plan

Written by the brief 02 worker, 2026-10-29. Deadline: **Thursday 5 November 2026**
(`docs/memory/project-and-deadline.md`). Requirements are cited by id from `docs/requirements.md`;
each one there is tagged with the milestone below that delivers it.

> **Weekdays.** 29 October 2026 is a **Thursday**. Earlier docs (the brief, `docs/HANDOFF.md`)
> called it Wednesday, so every weekday there was one off. The dates were right; this plan uses
> dates with the correct weekday.

## The thin vertical slice comes first

The first thing that must exist end to end is **Mission 1, playable offline from a fresh
clone**: splash → intro → scene → draft → three beats → follow-up → dossier, with the attempt
stored on the device, and no keys or network needed. It touches every layer (brand, content,
engine, local database, analytics) once, so every later milestone is "more of the same" rather
than "first of its kind". Everything before it (03, 04, 06) exists to make that slice good;
everything after it widens it. The slice is brief 09.

## Waves

The plan runs in **parallel waves** (kit README §4c). Briefs in a wave run at the same time, each
in its own worktree (w1, w2, w3), and each is one PR merged by the owner. A wave starts when the
briefs it needs have merged. Sizes: **S** under half a day, **M** about half a day, **L** most
of a day.

| Brief | Wave | Worktree | Size | Merge by | Delivers | Needs |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | | | L | Thu 29 Oct ✔ | Foundation: monorepo, gates, CI, logging, brand skeleton. NFR-5, NFR-7 (gates) | |
| 02 | | | M | Thu 29 Oct ✔ | Spec v1: requirements with ACs, this plan, ADRs, engine and content types, `EventValue`. FR-70 (type), D1, D3 | 01 |
| 03 | 1 | w1 | M | Fri 30 Oct | **Cinematic direction**: 2–3 throwaway prototypes of the Mission 1 scene, compared on a phone; D2 (portraits) and D4 (fonts) decided. NFR-1 direction | 02 |
| 04 | 1 | w2 | M | Fri 30 Oct | **Engine + content schema + Mission 1 content** (scored, reviewed), every engine function unit-tested. FR-12, FR-14, FR-20–22, FR-30 (M1), FR-32, FR-40 (engine) | 02 |
| 05 | 1 | w3 | M | Fri 30 Oct | **Supabase**: migrations, owner-only RLS + tests, anonymous auth, all optional at runtime. FR-2 (server), FR-62, D1 column, NFR-8 | 02 |
| 06 | 2 | w1 | L | Sat 31 Oct | **Design system + cinematic layer**: tokens, bundled fonts, letterbox, spotlight, grain/vignette, subtitle text, icons, launch screens, `/dev/catalog`, first goldens. NFR-1, NFR-2, NFR-7 | 03 |
| 07 | 2 | w2 | M | Sat 31 Oct | **Missions 2–7 content**, scored and reviewed (text only). FR-30 | 04 |
| 08 | 2 | w3 | L | Sat 31 Oct | **App-side auth + drift outbox sync**: anonymous sign-in, link email/Google, onboarding, outbox flush, restore; silently off with no keys or network. FR-2–4, FR-60 (sync), FR-61 | 05 |
| 09 | 3 | w1 | L | **Sun 1 Nov** | **Mission player**: scene → draft → beats → follow-up → dossier, local attempt storage, events. FR-1, FR-10–16, FR-60 (local), NFR-4 (M1) | 04, 06 |
| 10 | 3 | w2 | M | Sun 1 Nov | **Notifications** (Android first, then iOS). FR-50–53 | 06 |
| 11 | 3 | w3 | M | Sun 1 Nov | **AI coach** Edge Function (optional, first to cut). FR-11 (grading), FR-15 ("Say it your way"), FR-24, FR-63 | 05 |
| 12 | 4 | w1 | L | Mon 2 Nov | **Tower home, elevator, Recall Room, Chapter 1 report**, skill radar, Chapter 2 teaser + waitlist. FR-5, FR-16, FR-31, FR-32, FR-40–42, D1 | 07, 08, 09 |
| 13 | 4 | w2 | M | Wed 4 Nov | **Dogfood fixes, APK, GitHub Release**: a full Chapter 1 playthrough on the OnePlus 9 and the web, fixes, profile pass. NFR-3, FR-71 | everything |
| 14 | 4 | w3 | S | **Thu 5 Nov, early** | **Submission**: write-up (scoring hypothesis, multiple-choice limits), `SUBMISSION.md` with the paywall mock, demo video script, reviewer run guide. FR-23, NFR-6 | 13 |

Target dates: wave 1 Thu 29–Fri 30 Oct, wave 2 Fri 30–Sat 31 Oct, wave 3 Sat 31 Oct–Sun 1 Nov,
wave 4 Mon 2–Wed 4 Nov, submit Thu 5 Nov early.

**The briefs that must not slip:** 04 and 06 (09 needs both), 09 (Mission 1 is the demo), 14
(submitting late is the only unrecoverable failure).

## Cut line

If we slip, drop in this order (first to go first). Each cut is announced in `docs/HANDOFF.md`
and explained in the README, never silently skipped.

1. **11 AI coach.** The draft is still stored for "then vs. now"; the README says grading is v2.
2. **Sound** (D5).
3. **Chapter 2–3 teaser polish**: plain locked floors with their mission titles.
4. **Skill tree visuals**: keep the radar, show unlocked skills as a list.
5. **Notifications on iOS**: keep Android.
6. **Missions 5–7 polish**: keep them playable and scored, with the base cinematic layer only.

**Never cut:** Mission 1 quality, zero setup and offline play, the design system, the gates.

## Run and review without hosting

There's no hosted web demo ([ADR 0005](decisions/0005-zero-setup-offline-backend-optional.md),
D3).

- **Zero setup.** `git clone` → `flutter pub get` → `cd apps/mobile && flutter run` works with no
  env file, no `--dart-define` and no keys, and the game plays fully offline. The backend is
  optional at runtime: with no keys, or keys but no network, every backend feature is silently
  off (NFR-8).
- **CI builds the web release as a compile check only.** Nothing is deployed, so there are no
  host secrets, no deploy job and no cross-origin headers to get right. `flutter run -d chrome`
  stays a local run target.
- **Reviewers clone and run** (on Chrome, an emulator or a phone), or install the APK from the
  GitHub Release (13). The README's run guide is those three commands (14).
- **The demo video is the public face.** The owner records it; brief 14 writes its script.

## Where the brief is wrong or risky

Each point names what we'd change. The owner decides; brief 02 adopts none of them silently
(the owner confirmed FR-13, Mission 1 untimed, and D1 on 2026-10-29).

1. **A 4–6 minute mission against a reviewer's first 10 seconds.** A reviewer who runs the game
   or opens the demo video decides in seconds whether it's cinematic, but the brief puts a splash, a three-screen
   intro, a scene and an optional draft before the first answer, about a minute of reading.
   **Change:** the first screen after the loader is already cinematic (the chapter title card
   over the lit tower, 03b), the intro is skippable from its first frame (FR-1 AC), and the
   README links a 60-second video (there's no hosted web build to link) and a shortcut that
   opens Mission 1 at the scene. Aim for
   Mission 1 at about 3 minutes, not 6.
2. **The 60-second timer, accessibility and the baseline.** Timing out text that non-native
   speakers must read (an option set per beat, 3–4 lines each) works against WCAG 2.2.1 (Timing
   Adjustable) and against the audience the brief names. Calm mode helps, but it's only offered
   in onboarding *after* Mission 1, so the baseline (Mission 1) is timed for everyone, nervous
   or not, and partly measures reading speed. **Change:** Mission 1 is untimed (a cleaner
   baseline); calm mode is reachable from the pause menu at any time; the timer never removes a
   choice or lowers a score, only dims the light and dents trust (FR-13 AC); at 2x text the
   timer is off by default.
3. **Seven polished missions in four build days.** Chapter 1 is about 7 × (3 beats × 3–4 options
   + 1–3 follow-ups × 3–4 replies), roughly 120–150 hand-scored lines with flags and lessons,
   plus 7 Recall Room checks. Writing and reviewing that is a day on its own, and it's
   invisible on the plan as the brief wrote it. **Change:** content is its own milestone (07a),
   validated by `validateContent` so structure can't be wrong, and written while 06 is built;
   Missions 2–7 reuse Mission 1's screens with no new UI; the cut list keeps 5–7 playable but
   plainer.
4. **Mission 6 "challenges the player's *actual* Mission 5 answer".** With three beats of 3–4
   options, Mission 5 has up to 64 answer combinations. Writing a challenge for each is
   impossible. **Change:** Lena challenges Mission 5's **costliest line**
   (`MissionScore.optionIdsByCost`), so Mission 6 needs at most one challenge per Mission 5
   option (about 12), and in practice one per flag. Mission 5's attempt must be stored with its
   option ids, which FR-60 already does.
5. **Art is a dependency nobody owns.** Four interviewers × three expressions with a Rive idle
   (brief §5, §9), and D2 (who makes the art) is still open. A beautiful scene with placeholder
   portraits fails the Design criterion. **Change:** decide D2 in 03a at the latest. Fallback
   that still looks filmic: one painterly still per expression with the idle done in code
   (a slow scale "breath", the spotlight flicker, a parallax shift), no Rive.
6. **"Skills unlock only when demonstrated in an unhinted mission".** In Chapter 1 only
   Missions 1, 3 and 7 are unhinted, and Mission 1 is the baseline where players should
   struggle, so Chapter 1 can realistically unlock one or two of the four skills. A skill tree
   that stays mostly dark for a week can read as failure. **Change:** say so on the tree
   ("Chapter 2 tests Conflict Navigator"), and let Mission 3 unlock Clear Introductions and
   Mission 7 Evidence Builder, so a good player sees two lit by Day 7.
7. **Web offline after the first load.** NFR-4 says Chapter 1 plays offline. On mobile that's
   the bundle; a hosted web build would have depended on a service worker, and Flutter's
   built-in one is being phased out. **Resolved:** there's no hosted web build now (ADR 0005),
   so no service worker is needed. A local `flutter run -d chrome` keeps playing when the
   network drops (drift gives us that), and the README says the full offline game is the mobile
   app.
