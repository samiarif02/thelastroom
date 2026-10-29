# v1 plan

Written by the brief 02 worker, 2026-10-29. Deadline: **Thursday 5 November 2026**
(`docs/memory/project-and-deadline.md`). Requirements are cited by id from `docs/requirements.md`;
each one there is tagged with the milestone below that delivers it.

> **Weekdays.** 29 October 2026 is a **Thursday**. Earlier docs (the brief, `docs/HANDOFF.md`)
> called it Wednesday, so every weekday there was one off. The dates were right; this plan uses
> dates with the correct weekday.

## The thin vertical slice comes first

The first thing that must exist end to end is **Mission 1, playable offline, on the public web
link**: splash → intro → scene → draft → three beats → follow-up → dossier, with the attempt
stored on the device. It touches every layer (brand, content, engine, local database, analytics,
the deploy) once, so every later milestone is "more of the same" rather than "first of its
kind". Everything before it (02b, 03a, 03b, 04) exists to make that slice good; everything after
it widens it.

## Milestones

One milestone is one PR (two where noted), merged by the owner. Sizes: **S** under half a day,
**M** about half a day, **L** most of a day.

| Brief | Milestone | Size | Merge by | Delivers | Needs |
| --- | --- | --- | --- | --- | --- |
| 01 | Foundation: monorepo, gates, CI, logging, brand skeleton | L | Thu 29 Oct ✔ | NFR-5, NFR-7 (gates) | |
| 02 | **Spec v1** (this): requirements with ACs, this plan, ADRs, engine and content types, `EventValue` | M | Thu 29 Oct | FR-70 (type), D1, D3 | 01 |
| 02b | **Vercel deploy**: preview URL per PR, production from `main` (below) | S | Fri 30 Oct, morning | the demo link | 02, owner's three secrets |
| 03a | **Cinematic direction picked**: 2–3 throwaway prototypes of the Mission 1 scene, compared on a phone through preview links; D2 (portraits) and D4 (fonts) decided | M | Fri 30 Oct, noon | NFR-1 direction | 02b |
| 03b | **Design system + cinematic layer**: tokens filled in, fonts bundled, letterbox, spotlight, grain/vignette, subtitle text, `/dev/catalog`, first goldens | L | Fri 30 Oct, night | NFR-1, NFR-2, NFR-7 | 03a |
| 04 | **Content + engine**: Mission 1 content (scored, reviewed), every engine function implemented and unit-tested | M | Sat 31 Oct, morning | FR-12, FR-14, FR-20–22, FR-30 (M1), FR-32, FR-40 (engine) | 02 |
| 05 | **Mission 1 playable offline + web demo live**. Split in two PRs: **05a** scene → draft → beats → follow-up; **05b** dossier, local attempt storage, outbox table, events | L | **Sat 31 Oct** | FR-1, FR-10–16, FR-60 (local), NFR-4 (M1) | 03b, 04 |
| 05p | Mission 1 polish from the first outside play | S | Sun 1 Nov, morning | NFR-1, NFR-3 | 05 |
| 06 | **Auth + sync**: anonymous sign-in, link email/Google, onboarding, migrations with owner-only RLS + tests, outbox flush, restore | L | Sun 1 Nov | FR-2–4, FR-60–62, D1 column | 05 |
| 07a | **Missions 2–7 content**, scored and reviewed (text only; the screens already exist) | M | Mon 2 Nov | FR-30 | 04 |
| 07b | **Tower home, elevator, Recall Room, Chapter 1 report, skill radar, Chapter 2 teaser + waitlist** | L | Mon 2 Nov | FR-5, FR-16, FR-31, FR-32, FR-40–42, D1 | 05, 06 |
| 08 | **Notifications** (Android first, then iOS) | M | Tue 3 Nov | FR-50–53 | 07b |
| 09 | AI coach (**only if ahead**; otherwise cut, and the README says why) | M | Tue 3 Nov | FR-11 (grading), FR-15 ("Say it your way"), FR-24, FR-63 | 06 |
| 10 | **Dogfood and ship**: a full Chapter 1 playthrough on the OnePlus 9 and the web, fixes, profile pass, APK on a GitHub Release, final web deploy | M | Wed 4 Nov | NFR-3, FR-71 | everything |
| 11 | **Submission**: README (scoring hypothesis, multiple-choice limits), `SUBMISSION.md` with the paywall mock, the demo video | S | **Thu 5 Nov, early** | FR-23, NFR-6 | 10 |

04 depends only on 02, so it can start in parallel with 03a/03b if a second session is free;
it's on the critical path only for 05.

**The milestones that must not slip:** 02b (no demo link means no design comparison and no
outside review), 05 (Mission 1 on the web is the demo), 11 (submitting late is the only
unrecoverable failure).

## Cut line

If we slip, drop in this order (first to go first). Each cut is announced in `docs/HANDOFF.md`
and explained in the README, never silently skipped.

1. **09 AI coach.** The draft is still stored for "then vs. now"; the README says grading is v2.
2. **Sound** (D5).
3. **Chapter 2–3 teaser polish**: plain locked floors with their mission titles.
4. **Skill tree visuals**: keep the radar, show unlocked skills as a list.
5. **Notifications on iOS**: keep Android.
6. **Missions 5–7 polish**: keep them playable and scored, with the base cinematic layer only.

**Never cut:** Mission 1 quality, the web demo, the design system, the gates.

## 02b: the Vercel deploy (Friday morning, before 03a)

D3 is decided: Vercel, built in GitHub Actions and deployed prebuilt. The 02b worker builds
exactly this, and **stops to ask** for the owner's secrets rather than guessing.

### CI job shape

- `ci.yml` also runs on `push` to `main` (the `commits` job is already PR-only).
- The `check` job keeps building the web release (`npm run build:web`) and uploads
  `apps/mobile/build/web` as an artifact. **Build once**: nothing deploys code CI didn't test.
- A `deploy-web` job, `needs: check`, downloads the artifact, then:
  `vercel pull --yes --environment=<preview|production>` →
  `vercel build [--prod]` (with a no-op build command, it only copies the static output and
  compiles `vercel.json`'s headers and rewrites into `.vercel/output`) →
  `vercel deploy --prebuilt [--prod]`.
  The `vercel build` step matters: with `--prebuilt`, Vercel applies only what's in
  `.vercel/output/config.json`, so skipping it would silently drop every header below.
- `pull_request`: deploy a **preview**, then post its URL on the PR as one comment that's edited
  on each push (not a new comment per push) and as a deployment status.
- `push` to `main`: deploy **production**.
- **Fork PRs get no secrets**, so the job is skipped for them
  (`github.event.pull_request.head.repo.full_name == github.repository`), not failed.
- Job permissions: `contents: read`, `pull-requests: write` (the comment), `deployments: write`.
- Concurrency per ref, cancelling the superseded deploy, like CI.
- The Vercel CLI is pinned to a version, not `latest`.

### `vercel.json`

- **Git deploys off** (`"git": {"deploymentEnabled": false}`): only Actions deploys, so Vercel
  never tries to build Flutter itself.
- **SPA rewrite**: every path that isn't a file goes to `/index.html`, so go_router deep links
  (`/mission/1`) load on refresh.
- **Cache headers.** Flutter's web output is **not content-hashed** (`main.dart.js`,
  `flutter_bootstrap.js` and the assets keep the same names across builds), so nothing may be
  marked `immutable`, or players would run stale code after a deploy. Instead:
  `index.html`, `flutter_bootstrap.js`, `main.dart.js`, `version.json`,
  `flutter_service_worker.js` and `manifest.json` get `no-cache` (revalidate every load; Vercel's
  ETags make that a cheap 304). `canvaskit/` and `assets/fonts/` get `public, max-age=86400`:
  they change only with a Flutter or font upgrade, and a day of staleness is harmless there.
  If 03b measures the first frame as too slow, the fix is fingerprinting `main.dart.js` in a
  post-build step, not a longer cache on an unhashed name.
- **COOP/COEP** (`Cross-Origin-Opener-Policy: same-origin`,
  `Cross-Origin-Embedder-Policy: require-corp`) give drift's WASM build its fastest storage
  (OPFS with shared memory). **Not set in 02b**, written down as a commented-out plan, because
  they break things we use now or soon: any cross-origin resource without a CORP header (fonts
  and CanvasKit fetched from Google's CDN until 03b bundles them), and OAuth popups for Google
  sign-in in 06, whose `window.opener` COOP cuts. drift falls back to IndexedDB-backed storage
  without them, which is fast enough for a few hundred rows. Decide in 05 by measuring, and try
  `credentialless` before `require-corp`.

### Secrets

`VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` live **only** as GitHub Actions repository
secrets (`docs/rules/secrets.md`), referenced as `${{ secrets.NAME }}` in the workflow, which is
nothing `check:secrets` flags. `.vercel/` (where `vercel pull` and `vercel link` write
`project.json` and env files) goes in `.gitignore` in the same PR. The web build itself needs no
secret: until 06 it builds with `env/dev.example.json`; from 06 its public Supabase values come
from Actions **variables** (they're public by design), never secrets pretending to be private.

### Owner steps (exactly these, before 02b can finish)

1. **Create the project.** In the repo root run `npx vercel@latest link`, sign in, choose
   "create a new project", name it `thelastroom`, framework "Other". Don't connect the Git
   repository. It writes `.vercel/project.json`, which holds `orgId` and `projectId`. (Don't
   commit that folder.)
2. **Create the token.** vercel.com → Account Settings → Tokens → Create: name
   `thelastroom-ci`, scope your account (or team), expiry after 5 November (30 days is fine).
   Copy it once.
3. **Add the three repository secrets.** In the repo root run each and paste the value when
   prompted (it never lands in shell history):
   `gh secret set VERCEL_TOKEN`, `gh secret set VERCEL_ORG_ID`, `gh secret set VERCEL_PROJECT_ID`.
   (Or GitHub → Settings → Secrets and variables → Actions → New repository secret.)
4. **Let reviewers in.** Vercel → the project → Settings → Deployment Protection → turn
   **Vercel Authentication off** for previews. Otherwise every preview link asks outside
   reviewers to log in to Vercel, which defeats the point.

## Where the brief is wrong or risky

Each point names what we'd change. The owner decides; brief 02 adopts none of them silently
(FR-13's proposal is marked as such in the requirements).

1. **A 4–6 minute mission against a reviewer's first 10 seconds.** A reviewer opening the demo
   link decides in seconds whether it's cinematic, but the brief puts a splash, a three-screen
   intro, a scene and an optional draft before the first answer, about a minute of reading.
   **Change:** the first screen after the loader is already cinematic (the chapter title card
   over the lit tower, 03b), the intro is skippable from its first frame (FR-1 AC), and the
   README links a 60-second video plus a `?demo` link that opens Mission 1 at the scene. Aim for
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
   the bundle; on the web it depends on a service worker caching the app, and Flutter's built-in
   one is being phased out. **Change:** 02b checks what Flutter 3.47.8 emits. If there's no
   usable service worker, the web promise becomes "a loaded session keeps playing when the
   network drops" (which drift gives us), and the README says the full offline game is the
   mobile app.
