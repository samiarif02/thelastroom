# HANDOFF: live state

Last updated: 2026-10-29 17:45, claude-geo profile, LEAD session (after merging PR #1).
Read `docs/memory/MEMORY.md` first. Update this file after every meaningful step.

## How work flows

- One long-lived **LEAD session** reviews PRs (in the worktree `../thelastroom-review`), merges
  only when the owner says "merge #N", then writes the next brief in `docs/briefs/NN-slug.md`.
- **Worker sessions** build one brief each: own branch, local-review, PR, green CI, never merge.
- Lead docs (this file, briefs) land through a small `docs/lead-NN` PR, never a push to `main`.

## Current goal

Brief 02: spec v1 (`docs/briefs/02-spec.md`), done tonight.

## Branch

`main` = merge of PR #1 (`ddfc597`). Lead docs branch: `docs/lead-02` (this file + brief 02).
No worker branch open.

## Plan to 5 Nov (lead ticks these after each merge)

- [x] Wed 29: 01 foundation (PR #1, merged)
- [ ] Wed 29: 02 spec + plan + ADRs + types
- [ ] Thu 30 (noon): 03a cinematic direction picked
- [ ] Thu 30: 03b design system + cinematic layer
- [ ] Fri 31: 04 content + engine
- [ ] Fri 31: 05 **Mission 1 playable offline + web demo live**
- [ ] Sat 1: 05 polish, 06 auth + sync
- [ ] Sun 2: 07 tower home, Recall Room, report; Missions 2–7 content reviewed
- [ ] Mon 3: 08 notifications (09 AI coach only if ahead, else cut and say why)
- [ ] Tue 4: 10 dogfood, fixes, APK on a Release, final web deploy
- [ ] Wed 5: demo video, 11 SUBMISSION.md, submit early

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
| Demos (10) | Web build boots; release APK runs on a OnePlus 9 | **High**: no public URL yet (D3 undecided); must be live Fri 31 |
| Shipping speed (10) | 1 PR on day 1 | **High**: PR #1 was 176 files. From here: small PRs, more than one a day |
| Design (10) | Brand tokens, AA contrast tests, no-ripple theme, branded web loader | **High**: no direction yet; fonts and CanvasKit still on the CDN; stock launch screens |
| Completeness (10) | CI green | High: nothing playable yet |

**Weakest right now:** Design and Demos (nothing cinematic or public yet), then Shipping speed.

## Done

- PR #1 foundation merged (merge commit `ddfc597`, 2026-10-29). Lead review: all 8 gates green
  locally, web build boots to the title screen.

## In progress

- Nothing. Waiting on the owner to merge `docs/lead-02` and start the brief 02 worker.

## Next steps

1. Owner merges `docs/lead-02` (or says "merge" to the lead).
2. Start a worker on `docs/briefs/02-spec.md`.
3. Lead reviews the spec PR tonight; then writes `docs/briefs/03a-direction.md`.

## Open decisions for the owner

- D1–D5 in `docs/requirements.md`. D1 gets argued in brief 02; D3 (web host) is needed by Fri 31.
- Accept the Android SDK licenses (`flutter doctor --android-licenses`, interactive).
- Optional: install the iOS 27 simulator runtime; iOS 26.3 is used meanwhile.

## Known gaps carried from PR #1

- `EventProperties` admits free text (fixed in brief 02, item 5).
- Fonts and CanvasKit load from Google's CDN at runtime; native launch screens are stock (design
  session, D4).

## Gotchas

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
