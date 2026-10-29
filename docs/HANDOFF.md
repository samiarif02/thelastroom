# HANDOFF: live state

Last updated: 2026-10-29 (evening), claude-geo profile, brief 02 WORKER (PR open).
Read `docs/memory/MEMORY.md` first. Update this file after every meaningful step.

## How work flows

- One long-lived **LEAD session** reviews PRs (in the worktree `../thelastroom-review`), merges
  only when the owner says "merge #N", then writes the next brief in `docs/briefs/NN-slug.md`.
- **Worker sessions** build one brief each: own branch, local-review, PR, green CI, never merge.
- Lead docs (this file, briefs) are left **uncommitted on `main`**; the next worker commits them
  first on its own branch ([[workflow-lead-and-workers]]). No separate docs PRs.
- **Previews:** every PR gets a Vercel preview URL (from 02b on); lead reviews and outside
  reviewers play that link.

## Current goal

Brief 02 (spec v1) is in review: lead reviews the PR from `docs/spec-v1` tonight; the owner
merges. Next brief: 02b (Vercel), Fri 30 morning.

## Branch

`docs/spec-v1`, pushed, PR open against `main` (CI green at push time; check `gh pr checks`).
`main` is still `489d9e6`. The lead's uncommitted docs from `main` are committed on this branch
(`6b4d0a7`).

## Plan to 5 Nov (lead ticks these after each merge)

Weekdays corrected by the 02 worker: 29 Oct 2026 is a Thursday. Full plan: `docs/v1-plan.md`.

- [x] Thu 29: 01 foundation (PR #1, merged)
- [x] Thu 29: lead docs (PR #2, merged)
- [ ] Thu 29: 02 spec + plan + ADRs + types (plans Vercel)
- [ ] Fri 30 (morning): 02b Vercel deploy: preview per PR, production from `main`
- [ ] Fri 30 (noon): 03a cinematic direction picked
- [ ] Fri 30: 03b design system + cinematic layer
- [ ] Sat 31: 04 content + engine
- [ ] Sat 31: 05 **Mission 1 playable offline + web demo live**
- [ ] Sun 1: 05 polish, 06 auth + sync
- [ ] Mon 2: 07 tower home, Recall Room, report; Missions 2–7 content reviewed
- [ ] Tue 3: 08 notifications (09 AI coach only if ahead, else cut and say why)
- [ ] Wed 4: 10 dogfood, fixes, APK on a Release, final web deploy
- [ ] Thu 5: demo video, 11 SUBMISSION.md, submit early

**Cut order if we slip** (first to go first): 09 AI coach → sound (D5) → Chapter 2–3 teaser
polish → skill tree visuals (keep the radar) → notifications on iOS (keep Android) → Missions
5–7 polish (keep them playable). Never cut: Mission 1 quality, the web demo, the design system.

## Rubric scoreboard

| Criterion (pts) | Evidence so far | Risk |
| --- | --- | --- |
| Claude logs (15) | Logging hooks for both profiles, logs committed with PR #1; foundation prompt was a template | **Med**: the lead prompt and Prompt 1 were pasted. Type later prompts in your own words, push back, ask "why" |
| Architecture (15) | 8x standards ported (25/25), pure engine gate, strict analysis, logger with redaction, event registry, env check | Low now; outbox + RLS tests are still promises (06) |
| Comms (15) | PR #1 description is strong (gates, screenshots ×3, gaps, deviations) | Med: README, SUBMISSION.md and video don't exist yet |
| Initiative (15) | Decisions D1–D5 surfaced, ADR topics chosen, brief challenge requested in 02 | Med: draft-first, Recall Room and kind notifications are all unbuilt |
| Demos (10) | Web build boots; release APK runs on a OnePlus 9; D3 decided: Vercel | Med: no public URL until 02b (Fri 30, morning); needs the owner's Vercel secrets |
| Shipping speed (10) | 1 PR on day 1 | **High**: PR #1 was 176 files. From here: small PRs, more than one a day |
| Design (10) | Brand tokens, AA contrast tests, no-ripple theme, branded web loader | **High**: no direction yet; fonts and CanvasKit still on the CDN; stock launch screens |
| Completeness (10) | CI green | High: nothing playable yet |

**Weakest right now:** Design and Demos (nothing cinematic or public yet), then Shipping speed.

## Done

- PR #1 foundation merged (merge commit `ddfc597`, 2026-10-29). Lead review: all 8 gates green
  locally, web build boots to the title screen.
- PR #2 lead docs merged (`489d9e6`): plan, cut order, scoreboard, brief 02.
- Brief 02 (PR open, branch `docs/spec-v1`): `docs/v1-plan.md` (milestones, cut line, 02b
  plan, 7 risks), ACs + milestone tags in `docs/requirements.md`, D1 argued, D3 recorded, ADRs
  0001–0004, engine API types (bodies `UnimplementedError`, implemented in 04), content schema
  with a working `validateContent`, `EventValue` (no String constructor), events
  `draft_completed` and `answer_timer_expired`.
- Owner decisions (2026-10-29): no separate lead docs PRs; **D3 = Vercel**, built in GitHub
  Actions, preview per PR, production from `main`. Added to brief 02 (item 10).

## In progress

- Nothing being built. PR for brief 02 waiting on lead review and the owner's merge.

## Next steps

1. Lead reviews the brief 02 PR; owner merges ("merge #N").
2. Owner decides the two proposals in it: **D1 = (b) waitlist as a profile flag** (argued in
   `docs/requirements.md`) and **Mission 1 untimed** (FR-13). Both are marked "owner to confirm".
3. Owner, ready for 02b: the four owner steps in `docs/v1-plan.md` ("02b: the Vercel deploy"),
   including turning off Vercel Authentication on previews.
4. Lead writes `docs/briefs/02b-vercel.md` from that section of `docs/v1-plan.md`.

## Open decisions for the owner

- D1 argued and recorded as (b), owner to confirm. D2, D4, D5 open (03a). D3 decided (Vercel).
- Proposals from brief 02's "Where the brief is wrong or risky" (`docs/v1-plan.md`), 7 points.
- Vercel project, token and the three GitHub secrets (needed for 02b, Fri 30 morning).
- Accept the Android SDK licenses (`flutter doctor --android-licenses`, interactive).
- Optional: install the iOS 27 simulator runtime; iOS 26.3 is used meanwhile.

## Known gaps carried from PR #1

- Fonts and CanvasKit load from Google's CDN at runtime; native launch screens are stock (design
  session, D4).

## Gotchas

- 29 Oct 2026 is a **Thursday**. Older notes (brief 02 itself) say Wednesday; trust dates.
- Flutter's web output isn't content-hashed: never cache `main.dart.js` as immutable (02b).
- `check:standards` engine-pure-dart greps engine sources for the clock-read call, **including
  comments**: write "reads no clock", not the call itself.

- Prefer the owner's OnePlus 9 over the emulator for Android: `adb -s 96239c4a ...`. The emulator
  `Medium_Phone_API_36.1` on this Mac (16 GB, macOS 27.2): restores from
  snapshot then crashes; cold boot (`-no-snapshot -gpu host`) works but is CPU-starved (System
  UI ANRs, ~1 min to first frame). Don't run Gradle, the iOS simulator and the emulator at once.
  First `flutter build apk` took ~10 min (downloads Build-Tools 36).
- Flutter web text needs a font: with none bundled it downloads Roboto at runtime, so headless
  screenshots with `--virtual-time-budget` alone show only the HTML loader. Load the page once
  first (or wait for real), then screenshot.
- Screens are built without Scaffold, so `TheLastRoomApp` sets a root `DefaultTextStyle`;
  without it every Text gets Flutter's yellow double underline (regression-tested).
- The review worktree can't check out a branch the main folder has checked out: use
  `git worktree add --detach ../thelastroom-review origin/<branch>`.
- Switching the main folder to `main` with a modified session log: move `main` first
  (`git branch -f main origin/main`), then `git switch main`.
- In zsh, a non-matching glob (`rm -rf dir/*.iml`) aborts the **whole** command. Quote or check.
- Run `flutter pub get` at the repo root only; packages have no lockfile of their own.
- Answers given through Claude's multiple-choice questions arrive as tool results, so
  `extract-log.py` doesn't log them as prompts. Type important decisions as normal prompts.
- `.claude/settings.json` denies reading real env files; `apps/mobile/env/dev.json` is a copy of
  the example (all empty), created so `flutter run --dart-define-from-file` works.
