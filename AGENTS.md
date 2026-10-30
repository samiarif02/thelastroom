# AGENTS.md — The Last Room

The one file every coding agent reads (Claude Code, Codex, Cursor, Gemini). Per-tool files
(`CLAUDE.md`) only import it. Rules live here and in `docs/rules/`, nowhere else.

**What this repo is:** a cinematic interview-practice game in Flutter (Android, iOS, plus a web
build run locally; nothing is hosted). The full design is `docs/product-brief.md`; the testable version is
`docs/requirements.md`; the visual direction is `DESIGN.md`.

## Start of every session (both Claude profiles, any agent)

1. Read `docs/memory/MEMORY.md` (the index of durable facts) and `docs/HANDOFF.md` (the live state).
2. Confirm the branch in `docs/HANDOFF.md` matches `git branch --show-current`, and look at
   `git status`. Uncommitted files are probably the previous session's half-done work, not junk.
3. Continue from "Next steps" in `docs/HANDOFF.md`, unless the person asks for something else.

## While working: keep the brain current

- **Update `docs/HANDOFF.md` after every meaningful step**, not only at the end. A step is
  meaningful if losing it would cost the next session more than a minute to rediscover (a file
  created, a decision made, a gate passing or failing, a dead end found). Quota can run out
  between any two messages, so the last update is all the next profile gets.
- **Durable facts go in `docs/memory/`**: one fact per file, linked from `docs/memory/MEMORY.md`.
  Never only in an agent's personal memory (`~/.claude*/…/memory`), which the other profile, other
  agents and reviewers can't see.
- "handoff" or "save brain" from the person runs the `handoff` skill (`.claude/skills/handoff`).
- Never run two agents on this working tree at the same time.

## Layout

```
apps/mobile/        Flutter app (android/ ios/ web/). lib/app (bootstrap, router, theme wiring),
                    lib/core (env, logging, analytics, backend, db, sync, audio, notifications), lib/features/*
packages/engine/    pure Dart: scoring, follow-ups, unlocks, Leitner recall, baseline compare
packages/content/   missions, interviewers, lessons as typed Dart + validation tests
packages/brand/     design tokens + ThemeData; the only place a raw colour may be written
supabase/           config.toml, migrations/, functions/ (the AI coach), seed.sql
docs/               product-brief, requirements, EVENTS, rules/, memory/, decisions/, HANDOFF
scripts/            the gate scripts (Node, zero dependencies)
.githooks/          commit-msg, pre-commit, pre-push (installed by `npm install` → prepare)
.claude/            settings.json (hooks + deny rules), hooks/extract-log.py, skills/
.claude-logs/       committed session transcripts
```

## Commands

| What | Command |
| --- | --- |
| Install deps + git hooks | `flutter pub get && npm install` |
| Run the app | `cd apps/mobile && flutter run` (`-d chrome` for web). No keys, works offline. |
| Run with the optional backend | `cd apps/mobile && flutter run --dart-define-from-file=env/dev.json` |
| All gates, in CI's order | the `local-review` skill |
| Format | `npm run format` (always safe, never ask first) |

## Engineering rules

Read the rule file for every area a change touches, before writing the change.

- [Code quality](docs/rules/code-quality.md): strict analysis, no `dynamic`, no god files, named constants.
- [Commits](docs/rules/commits.md): Conventional Commits, curated scopes, don't over-commit, `Changelog:` line.
- [Pull requests](docs/rules/pull-requests.md): branch → finished → real description → green CI. Never merge on your own.
- [Deployment](docs/rules/deployment.md): zero setup, APK, store builds, Edge Functions, what ships how (the web isn't hosted).
- [Logging](docs/rules/logging.md): the structured `log` wrapper, never `print`.
- [Error handling](docs/rules/error-handling.md): typed failures, Sentry for the unexpected, cinematic error states.
- [Migrations](docs/rules/migrations.md): Supabase SQL migrations, RLS in the same migration, never edit a merged one.
- [Secrets](docs/rules/secrets.md): only public keys in the app, server secrets in Edge Function secrets, scanned twice.
- [Analytics](docs/rules/analytics.md): events registered in the enum before the feature; no PII, no answer text.
- [State management](docs/rules/state-management.md): Riverpod 3, where state lives, offline-first.
- [Components](docs/rules/components.md): brand tokens only, no Material defaults visible, every state designed.

### Non-negotiables

1. **No raw colours, no stock Material look** outside `packages/brand` (`check:standards` enforces
   the colour half). The UI is the headline of this project (brief §9).
2. **Events are registered before the feature** (`AnalyticsEvent` enum + `docs/EVENTS.md`).
3. **The engine stays pure Dart** and deterministic: no Flutter, no I/O, no clock reads, fully
   unit-tested. Scores must be explainable and reproducible offline.
4. **No secret ever ships in the app.** The Supabase anon key is the only key the app holds.
5. **An agent never merges a PR and never pushes to `main`.**
6. **Zero setup.** Clone → `flutter run` works with no keys and fully offline; the backend is
   optional at runtime (ADR 0005).

## Where this repo differs from 8x's templates

8x's `docs/STANDARDS.md` says to record divergences here rather than leave template rules
standing as silent lies about the stack. The engineering discipline is ported in full; the stack
conventions are replaced.

| Template (Next.js / Expo / Prisma) | Here (Flutter / Supabase) | Why |
| --- | --- | --- |
| TypeScript strict, ESLint `--max-warnings=0`, `no-explicit-any`, `no-console` | `analysis_options.yaml`: `strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `avoid_print`; `flutter analyze --fatal-infos` | The Dart equivalents of the same rules. `--fatal-infos` makes every lint fail the build. |
| `typecheck` + `lint` scripts | one `analyze` script | The Dart analyzer is both the type checker and the linter. |
| Prettier + `.prettierignore` | `dart format --set-exit-if-changed` | Dart has one canonical formatter. There's no JS to format besides the zero-dependency gate scripts. |
| Zod env schema in `src/lib/env.ts` | `Env` class reading `String.fromEnvironment` (`--dart-define-from-file`), `apps/mobile/env/dev.example.json`; `.env.example` for Edge Function secrets. Every app value is optional: with none, the backend is off (ADR 0005) | Dart compile-time defines are how Flutter gets config. `check:env` keeps the three in step. |
| Pino logger | `lib/core/logging` wrapper over `dart:developer` with redaction, plus Sentry later | Same contract (structured, levelled, redacted, one wrapper), Dart runtime. |
| Client never touches tables; Prisma is the only data path; RLS with **no** policies | The app reads/writes its **own rows** through `supabase_flutter`, guarded by **owner-only RLS policies** (tested) | Offline-first with an outbox needs the device to sync directly. There's no server of ours in the middle, so RLS policies *are* the authorization layer. |
| Prisma-generated migrations, CI drift check | Hand-written SQL in `supabase/migrations/` via `supabase migration new` | Supabase CLI is the migration tool. A local `supabase db reset` replays them. |
| Expo OTA-first releases, EAS | Store builds (Flutter has no first-party OTA); the web is not hosted (CI compile check only); APK on a GitHub Release | Stack difference. |
| npm workspaces | Dart pub workspace (root `pubspec.yaml` with `workspace:`); root `package.json` only for gates and `prepare` | Dart's own monorepo tool. |
| `check:events` against `/api/track` | `check:events`: the Dart enum is the registry (unregistered names don't compile), the check bans string event names and keeps the enum and `docs/EVENTS.md` in step | The compiler already does half the job. |
| `check:store`, `check:rls`, `check:template` | `check:rls` is ported (`scripts/check-rls.mjs`, run in CI's `check` job; CI's `db` job runs the pgTAP RLS tests with `supabase test db`). `check:store` and `check:template` are not ported yet | Store readiness lands with the store build. |
