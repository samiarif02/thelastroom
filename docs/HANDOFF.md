# HANDOFF: live state

Last updated: 2026-10-29 17:10, claude-geo profile, foundation session (Prompt 1).
Read `docs/memory/MEMORY.md` first. Update this file after every meaningful step.

## Current goal

Foundation only (Prompt 1 in `~/Downloads/thelastroom-kit/prompts.md`): repo, logging, shared
brain, monorepo scaffold, 8x standards ported to Flutter, CI, docs, an app that boots on Android,
iOS and Chrome, shipped as one PR. No game features.

## Branch

`chore/foundation`, pushed. PR #1: https://github.com/samiarif02/thelastroom/pull/1, **CI green**
(commits 4s, gates/tests/web build 2m44s). A lead session reviews and merges (agents in this session never merge).
`main` holds one empty "Initial commit" (needed as the PR base).

## Done

- Flutter upgraded 3.41.4 → 3.47.8 (Dart 3.13.7); Supabase CLI 2.122.0; Docker running.
- Git repo, local identity samiarif02 / 104030675+samiarif02@users.noreply.github.com, public
  GitHub repo created.
- Session logging (`.claude/hooks/extract-log.py` + 3 hooks), pipe-tested; reads
  `$CLAUDE_CONFIG_DIR/projects`.
- Owner confirmed (typed, 2026-10-29): Sami, GitHub samiarif02, deadline 2026-11-05.
- Bundle id is `com.thelastroom.app` on iOS and Android (MainActivity moved to
  `kotlin/com/thelastroom/app/`). Verified: release APK runs on a OnePlus 9 (LE2117), first
  frame in 1.09 s; iOS simulator build rebuilt.
- Workspace scaffold: `apps/mobile` (com.thelastroom), `packages/{engine,content,brand}`, strict
  analysis, placeholder title screen; `flutter analyze --fatal-infos` clean; all Dart tests pass.
- Gate scripts (commit message, secrets, standards, events, env, test runner) + tests; hooks; CI.
- AGENTS.md, CLAUDE.md, 11 rule files, memory, requirements, DESIGN, README, EVENTS.

## In progress

- Nothing.

## Next steps

1. Lead session reviews and merges PR #1; then `git switch main && git pull`.
2. Next session (Prompt 2): the spec, in the owner's own words.
3. Design session: start from DESIGN.md "Design session brief" (fonts, CanvasKit off the CDN,
   native launch screens, icons), then decision D4 and the tokens.

## Open decisions for the owner

- D1–D5 in `docs/requirements.md` (post-Chapter-1 outcome, portrait art, web host, fonts, sound).
- Accept the Android SDK licenses (`flutter doctor --android-licenses`, interactive).
- Optional: install the iOS 27 simulator runtime (Xcode → Settings → Components); iOS 26.3 is
  installed and used meanwhile.

## Gotchas

- Prefer the owner's OnePlus 9 over the emulator for Android: `adb -s 96239c4a ...`. The emulator
  `Medium_Phone_API_36.1` on this Mac (16 GB, macOS 27.2): restores from
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
