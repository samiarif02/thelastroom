# HANDOFF: live state

Last updated: 2026-11-03 (Tue) afternoon, by the wave-6 docs worker (worktree
`../thelastroom-w18`, branch `docs/53-wave-6-final`). Read `docs/memory/MEMORY.md` first.
Submission is **Thu 5 Nov 2026**.

## Current goal

Submit on Thu 5 Nov with the docs, screenshots and Claude logs current. Feature work is done.

## Branch

This worker: `docs/53-wave-6-final` in `../thelastroom-w18`, from `origin/main` `2233f80`.

## Done

- **`main` at `2233f80` has the whole v1:** Chapters 1–3 (21 rooms; Chapter 2 all voice, Chapter 3
  mixed), voice answers, live AI scoring with an offline fallback and a published eval, the
  Recall Room, reminders (days 1/3/5/8), the Daylight Tower redesign with doors, floor sheets,
  Your file with past results, first-time tips, route transitions, and the phone-QA fixes
  (release `INTERNET` permission). The landing page is live at https://thelastroom-ten.vercel.app
  (ADR 0007). The game itself stays unhosted and zero-setup (ADR 0005).
- **Merged in wave 6 (2–3 Nov):** #40–#59. What each did: `docs/SUBMISSION.md` ("Wave 6") and
  `docs/completion.md` (the wave-6 table).

## In progress

- The wave-6 docs PR from `docs/53-wave-6-final` (README with 15 new screenshots and the
  feature list, SUBMISSION, completion, this file, docs that contradicted ADR 0007, a stills
  test). Waiting for the owner's merge; agents never merge.

## How work flows

- A lead session writes briefs (`docs/briefs/`); workers take one worktree and one branch each,
  keep `docs/status/NN.md`, pass `local-review`, open a PR with green CI. Only the owner merges
  (a merge commit). Never two agents on one working tree.
- Session logs go in every PR, in their own `chore(claude): add session logs` commit right
  before the push; the pre-push hook refuses a branch without one.
- The owner's realme 8 (`LFCQ8HKNAUDIFUPR`) holds the owner's real progress: never uninstall or
  clear it, and don't drive it while the owner is testing.

## Next steps

1. Owner: review and merge the wave-6 docs PR.
2. **The final Claude-logs sweep** before submission: every session's log regenerated from its
   transcript and committed (the #45 method), one PR, green CI.
3. **The APK release only when the owner asks:** run the Release APK workflow (or tag `v*`),
   which makes a draft release; the owner publishes it.
4. Known small leftovers (not blocking): XP per sound reason and the shareable floor card are
   designed, not built; no device frame-timing pass (NFR-3); BUG-2 from status 51 (a resumed
   room once skipped a why step) was hardened but never reproduced.

## Open decisions

- None blocking. The owner chooses when to publish the APK release. The demo video was
  submitted by the owner directly (3 Nov), so the docs carry no link.

## Owner decisions that still hold

- Zero setup (ADR 0005): clone → `flutter run`, no keys, offline. No hosted Supabase.
- Landing page on Vercel (ADR 0007); the game's web build is a CI compile check only.
- No APK release until the owner asks; the owner sees UI before a merge.
- Free-tier Gemini key: heavy use rate-limits and falls back to the offline score.
- The debrief's Candidate assessment sheet stays exactly as it is (`ui/paper/**`).
- Chapters 2 and 3 are open for the demo; in a store build they'd be the Pro content
  (`docs/SUBMISSION.md`, the paywall mock).

## Gotchas

- 29 Oct 2026 is a **Thursday**. Older notes (brief 02 itself) say Wednesday; trust dates.
- Flutter's web output isn't content-hashed: never cache `main.dart.js` as immutable if the game's web build is ever hosted.
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
- **Release builds need `INTERNET` in `src/main`'s manifest** (Flutter's template only puts it in
  debug/profile). Without it a release APK is silently offline-only; `check:standards`
  (`android-release-permissions`) now guards it (#59).
- **Live AI on a USB phone:** `supabase start`, `supabase functions serve --env-file <your .env>`,
  `adb reverse tcp:54321 tcp:54321`, and a define file with `SUPABASE_URL=http://127.0.0.1:54321`
  plus the local anon key. Loopback HTTP works even in a release build; LAN-IP HTTP only in
  debug/profile.
- **README screenshots** come from `apps/mobile/test/app/stills/readme_stills_test.dart`:
  `WRITE_STILLS=1 STILLS_DIR=<dir> flutter test test/app/stills/readme_stills_test.dart`, then
  `sips -s format jpeg -s formatOptions 72` each PNG into `docs/screenshots/` (all < 400 KB).

