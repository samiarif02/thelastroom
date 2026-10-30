# HANDOFF: live state

Last updated: 2026-10-30 02:30 (Fri), LEAD session (wave 2 briefs committed, workers not started).
Read `docs/memory/MEMORY.md` first. **Parallel mode: only the lead edits this file.** Workers keep
`docs/status/NN.md`.

## How work flows (parallel mode, kit README §4c)

- **LEAD** stays in `~/WebstormProjects/thelastroom` (claude-geo). Reviews in a detached
  worktree `../thelastroom-review`; merges only on the owner's "merge #N"; merges in dependency
  order, then the other open branches rebase on `main`; removes a worker's worktree after merge.
- **Workers** (max 3), one per worktree `../thelastroom-w1..w3`. The lead creates the worktree
  and commits the brief as the branch's first commit. Each brief lists its **file ownership**;
  parallel briefs never own the same files. Workers never edit this file.
- Lead docs (this file, ADRs, plan, requirements) go in **one small docs PR per wave**
  (`docs/lead-wave-N`).
- **No hosted web demo** (owner, 2026-10-29, ADR 0005). Reviewers clone and run; the owner records
  a demo video. **Zero setup:** clone → `flutter run` with no keys, fully offline; the backend is
  optional at runtime. `flutter build web` stays in CI as a compile check; Chrome is a local run
  target.

## Current goal

**Wave 2**, target merged by Sat 31 Oct evening (06 by Sat morning: it's the critical path for
10). Wave 1 merged Fri 30 Oct ~01:30 (PRs #5, #7, #6). Four workers (the owner raised the cap
from three).

| Worktree | Branch | Brief | Profile (tab) | Phone |
| --- | --- | --- | --- | --- |
| w1 | `feat/06-design-system` | `docs/briefs/06-design-system.md` | claude-geo | OnePlus 9 |
| w2 | `feat/07-missions-2-7` | `docs/briefs/07-missions-2-7.md` | claude | none (dart test) |
| w3 | `feat/08-auth-sync` | `docs/briefs/08-auth-sync.md` | claude | Chrome / realme by arrangement |
| w4 | `feat/09-sound` | `docs/briefs/09-sound.md` | claude-geo | Chrome / realme by arrangement |
| main folder | `docs/lead-wave-2` | lead docs: renumbering, D2/D4/D5, worker doc requests, memory | lead | realme 8 |

All four branches start at `cffba86` with their brief as the first commit.

**Merge order:** 07 → 06 → 08 → 09. **Shared hot spots this wave:** `apps/mobile/pubspec.yaml` +
`pubspec.lock` (08 adds drift; 09 adds `flutter_soloud`, `shared_preferences`, `assets/audio/`;
the second to merge rebases and reruns `flutter pub get`). `router.dart` and `web/index.html` are
06's; 09 adds one `/dev/sound` route and the soloud script tags. `main.dart` is 08's; 09 adds one
preload line. The lead checks these at merge.

**Waiting on the owner:** Mission 1 wording notes (forward to w2 / brief 07); approve the sound
set by ear on `/dev/sound` before 09 merges.

**Brief numbers shifted** (sound became 09): 10 mission player, 11 notifications, 12 AI coach,
13 tower + Recall Room + report, 14 dogfood/APK/release, 15 submission.

## Branch

Lead: `docs/lead-wave-2` in the main folder (off `main` = `cffba86`). Workers: the table above.

## Plan to 5 Nov (lead ticks these after each merge)

29 Oct 2026 is a Thursday. Full plan: `docs/v1-plan.md`.

- [x] Thu 29: 01 foundation (PR #1), lead docs (PR #2), 02 spec (PR #3)
- [x] Wave 1, Thu 29–Fri 30 (merged Fri 01:30, PRs #5 #7 #6): 03 cinematic direction (owner picks Fri noon) · 04 engine + Mission 1
      content · 05 Supabase schema, RLS tests, anonymous auth (optional at runtime)
- [ ] Wave 2, Fri 30–Sat 31: 06 design system (Boardroom) · 07 Missions 2–7 content · 08 drift +
      outbox sync + email linking · 09 sound design
- [ ] Wave 3, Sun 1–Mon 2: 10 **mission player: Chapter 1 playable offline** (needs 04, 06, 07, 09) ·
      11 notifications · 12 AI coach (optional, first to cut)
- [ ] Wave 4, Mon 2–Wed 4: 13 tower home + Recall Room + report · 14 dogfood fixes, APK on a
      GitHub Release · 15 submission write-up, demo video script, reviewer run guide
- [ ] Thu 5: record the demo video, submit early

**Cut order if we slip** (first to go first): 12 AI coach → trim 09's cue sheet to the core cues → Chapter 2–3 teaser
polish → skill tree visuals (keep the radar) → notifications on iOS (keep Android) → Missions
5–7 polish (keep them playable). Never cut: Mission 1 quality, zero setup, the design system,
the gates, the demo video.

## Rubric scoreboard

| Criterion (pts) | Evidence so far | Risk |
| --- | --- | --- |
| Claude logs (15) | Logs committed with every PR; owner decisions typed (D1, untimed M1, no Vercel, parallel mode); the spec worker corrected the lead (weekday) | **Med**: several owner prompts were pasted blocks; the logger flags them. Type prompts in your own words |
| Architecture (15) | 8x standards ported (25/25); pure engine gate; `EventValue` bans free text; ADRs 0001–0005; content validator | Low–Med: RLS tests (05) and the outbox (08) still to land |
| Comms (15) | Strong PR descriptions (#1, #3: D1 argument, 7 brief challenges) | Med: README run guide, SUBMISSION.md and the video don't exist yet (14) |
| Initiative (15) | Brief challenged (untimed baseline, M6 continuity, unhinted skills, waitlist as a flag) | Med: draft-first, Recall Room, kind notifications unbuilt |
| Demos (10) | Web build compiles; release APK on a OnePlus 9 | **High**: no public link by choice, so the **video carries Demos**, plus a 3-command run guide and an APK Release. Script it early (14) |
| Shipping speed (10) | 3 PRs merged day 1; 3 workers in parallel from tonight | Med: wave PRs must stay small |
| Design (10) | Boardroom direction chosen from 3 phone-tested prototypes (9 stills + 3 clips); bundled OFL fonts; AA tests per pair | **High** until 06 lands: the app itself still shows the placeholder |
| Completeness (10) | CI green | **High**: nothing playable until 09 (Sat 31–Sun 1) |

**Weakest right now:** Design and Completeness (nothing cinematic or playable yet), then Demos.

## Done

- PR #1 foundation (`ddfc597`), PR #2 lead docs (`489d9e6`), PR #3 spec v1 (`050ad6d`), PR #4
  wave-1 lead docs (`dff4bc2`), all
  2026-10-29. Spec: `docs/v1-plan.md`, ACs in `docs/requirements.md`, ADRs 0001–0004, engine API
  types, content schema + `validateContent`, `EventValue`.
- Owner decisions (2026-10-29): D1 = waitlist as a profile flag (`chapter_2_waitlist_at`), no
  email form; Mission 1 untimed; **no Vercel / no hosted demo**, zero-setup rule (ADR 0005);
  parallel mode with waves; 03 font pairs: Instrument Serif + Geist, Big Shoulders Display + Inter
  Tight, Cormorant Garamond + Manrope (banned: Playfair, Bebas, Montserrat, Poppins).

## In progress

- Lead: PR #4 merged (ADR 0005, zero setup, wave plan). Waiting on wave-1 PRs.
- Workers w1–w3: briefs committed, sessions not started yet.

## Next steps

1. Owner starts the three workers (tabs in the table above).
2. Lead reviews 04, 05, 03 as they land; owner picks the direction on 03 by Fri noon.
3. After wave 1: lead writes wave-2 briefs 06, 07, 08.

## Open decisions for the owner

- D2, D4, D5 decided (2026-10-30): code-drawn rim-lit silhouettes; Cormorant Garamond + Manrope;
  sound in v1, on but quiet.
- Accept the Android SDK licenses (`flutter doctor --android-licenses`, interactive).
- Optional: install the iOS 27 simulator runtime; iOS 26.3 is used meanwhile.

## Known gaps carried from PR #1

- Fonts and CanvasKit load from Google's CDN at runtime (breaks zero setup offline on web; 03 bundles fonts, 06 adds `--no-web-resources-cdn`); native launch screens are stock (design
  session, D4).

## Gotchas

- 29 Oct 2026 is a **Thursday**. Older notes (brief 02 itself) say Wednesday; trust dates.
- Flutter's web output isn't content-hashed: never cache `main.dart.js` as immutable if the web is ever hosted.
- `check:standards` engine-pure-dart greps engine sources for the clock-read call, **including
  comments**: write "reads no clock", not the call itself.

- **Lead review device:** realme 8 (RMX3085, Android 13, 1080×2400), `adb -s LFCQ8HKNAUDIFUPR`.
  adb isn't on PATH: use `~/Library/Android/sdk/platform-tools/adb`. Main at `dff4bc2`, release APK, no
  keys: boots to the title screen, cold start 3.6 s (`am start -W`). Workers use the OnePlus 9.
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
