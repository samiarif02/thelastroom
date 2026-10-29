# HANDOFF: live state

Last updated: 2026-10-29 16:35, claude-geo profile, foundation session (Prompt 1).
Read `docs/memory/MEMORY.md` first. Update this file after every meaningful step.

## Current goal

Foundation only (Prompt 1 in `~/Downloads/thelastroom-kit/prompts.md`): repo, logging, shared
brain, monorepo scaffold, 8x standards ported to Flutter, CI, docs, an app that boots on Android,
iOS and Chrome, shipped as one PR. No game features.

## Branch

`chore/foundation` (from an empty `main`). Remote: https://github.com/samiarif02/thelastroom.
PR: not opened yet.

## Done

- Flutter upgraded 3.41.4 → 3.47.8 (Dart 3.13.7); Supabase CLI 2.122.0; Docker running.
- Git repo, local identity samiarif02 / 104030675+samiarif02@users.noreply.github.com, public
  GitHub repo created.
- Session logging (`.claude/hooks/extract-log.py` + 3 hooks), pipe-tested; reads
  `$CLAUDE_CONFIG_DIR/projects`.
- Workspace scaffold: `apps/mobile` (com.thelastroom), `packages/{engine,content,brand}`, strict
  analysis, placeholder title screen; `flutter analyze --fatal-infos` clean; all Dart tests pass.
- Gate scripts (commit message, secrets, standards, events, env, test runner) + tests; hooks; CI.
- AGENTS.md, CLAUDE.md, 11 rule files, memory, requirements, DESIGN, README, EVENTS.

## In progress

- Shipping: commits on `chore/foundation`, push, PR, watch CI. Gates all green locally.

## Next steps

1. Finish the ship: PR open, CI green; the owner merges (never the agent).
2. Owner: confirm the Android build renders cleanly on a healthy emulator or a phone
   (`cd apps/mobile && flutter run --dart-define-from-file=env/dev.json`).
3. Next session (Prompt 2): the spec, in the owner's own words.
4. Design session must also: bundle the fonts (web currently fetches Roboto + CanvasKit from
   Google's CDN at runtime, against brief §9 "no runtime fetch"; use `--no-web-resources-cdn`
   too), brand the native launch screens (Android 12+ splash is the Flutter logo on white, iOS
   LaunchScreen is white), and make the app icons.

## Open decisions for the owner

- D1–D5 in `docs/requirements.md` (post-Chapter-1 outcome, portrait art, web host, fonts, sound).
- Accept the Android SDK licenses (`flutter doctor --android-licenses`, interactive).
- Bundle id is `com.thelastroom.theLastRoom` (iOS) / `com.thelastroom.the_last_room` (Android),
  from `flutter create`. Changing it is free now and impossible after a store release.
- Optional: install the iOS 27 simulator runtime (Xcode → Settings → Components); iOS 26.3 is
  installed and used meanwhile.

## Gotchas

- Android emulator `Medium_Phone_API_36.1` on this Mac (16 GB, macOS 27.2): restores from
  snapshot then crashes; cold boot (`-no-snapshot -gpu host`) works but is CPU-starved (System
  UI ANRs, ~1 min to first frame). Don't run Gradle, the iOS simulator and the emulator at once.
  First `flutter build apk` took ~10 min (downloads Build-Tools 36).
- Flutter web text needs a font: with none bundled it downloads Roboto at runtime, so headless
  screenshots with `--virtual-time-budget` show no text. Real-wait screenshots work.
- Screens are built without Scaffold, so `TheLastRoomApp` sets a root `DefaultTextStyle`;
  without it every Text gets Flutter's yellow double underline (regression-tested).

- In zsh, a non-matching glob (`rm -rf dir/*.iml`) aborts the **whole** command. Quote or check.
- Run `flutter pub get` at the repo root only; packages have no lockfile of their own.
- Answers given through Claude's multiple-choice questions arrive as tool results, so
  `extract-log.py` doesn't log them as prompts. Type important decisions as normal prompts.
- `.claude/settings.json` denies reading real env files; `apps/mobile/env/dev.json` is a copy of
  the example (all empty), created so `flutter run --dart-define-from-file` works.
