# Brief 05: Supabase: migrations, RLS + tests, anonymous auth, optional at runtime (wave 1, w3)

Written by the lead session, 2026-10-29 (Thu). Worktree `../thelastroom-w3`, branch
`feat/05-supabase`. **Timebox: PR up by Fri 30 Oct, evening.**

## Goal

The backend exists, is locked down and is tested, and the app can use it **without ever
depending on it**: the schema for profiles and mission attempts with owner-only RLS proven by
tests in CI, and an anonymous sign-in that runs in the background only when keys are present.
Account linking and the drift outbox are brief 08; this brief makes them possible.

Read first: `docs/rules/migrations.md`, `docs/rules/secrets.md`, `docs/rules/state-management.md`,
`docs/rules/error-handling.md`, `docs/decisions/0002-*.md` (and 0005 if merged), FR-2, FR-60–FR-62
in `docs/requirements.md`.

## Hard rules

- **Zero setup** (owner, 2026-10-29, ADR 0005): `cd apps/mobile && flutter run` works from a
  fresh clone with **no keys and no network**, and the game is fully playable. The backend is
  **optional at runtime**:
  - no keys → Supabase is never initialised, nothing is attempted, nothing is shown;
  - keys but offline, or Supabase down → sign-in fails quietly in the background (a `warn` log),
    retries with backoff, and **never blocks a frame or shows an error**.
- Only the anon key may be in the app. No service-role key anywhere in the app or the repo.
- Every table gets RLS and owner-only policies **in the migration that creates it**.

## In scope

1. **Migrations** (`supabase migration new ...`):
   - `profiles`: `user_id` (pk, references `auth.users`, on delete cascade), `created_at`
     (server default), `target_role`, `nerves_level` (1–5 check), `calm_mode`, `interview_date`,
     **`chapter_2_waitlist_at`** (D1, owner confirmed 2026-10-29: the waitlist is this flag, no
     email form).
   - `mission_attempts`: **`attempt_id` uuid primary key generated on the device** (idempotent
     upsert), `user_id`, `mission_id`, `content_schema_version`, the four dimension scores, total,
     `hinted`, flags, `completed_at` (from the device), `created_at` (server default, **not**
     client-settable). Append-only: no update or delete policy.
   - No `coach_usage` yet: the coach (11) is optional and first to cut; it adds its own table.
2. **RLS tests** with pgTAP (`supabase/tests/*.sql`, run by `supabase test db`): user B can't
   select, insert, update or delete user A's rows; the `anon` role (no session) sees nothing;
   inserting the same `attempt_id` twice leaves one row; a client can't set `created_at` or
   another user's `user_id`.
3. **Anonymous sign-in** enabled in `supabase/config.toml`.
4. **CI:** a job that starts the local stack and runs `supabase test db` on every PR, and the
   same command in the `local-review` skill (`check:standards`' `local-review-mirrors-ci` checks
   they match). Port **`check:rls`** as a gate: every `create table` in `supabase/migrations/`
   has `enable row level security` and at least one policy in the same file.
5. **App side, minimal:** `supabase_flutter`, initialised **only if `Env.hasSupabase`**, behind a
   small interface in `apps/mobile/lib/core/backend/` so tests use a fake and the rest of the app
   never imports Supabase directly. After the first frame, sign in anonymously in the background;
   on success fire **`guest_started`** (already registered) once. Expose the session state
   (none / guest) through a provider for 08. A local `apps/mobile/env/dev.json` pointing at
   `supabase start` is fine for your own runs; it stays gitignored.

## Out of scope

- Linking email or Google, onboarding, the drift database, the outbox and sync (all 08).
- The coach Edge Function and `coach_usage` (11). Any UI: there is no sign-in screen in v1.
- Deploying anything to a hosted Supabase project (nothing is deployed without the owner).

## File ownership (parallel wave: touch only these)

- `supabase/**`
- `apps/mobile/lib/core/backend/**` (new), `apps/mobile/lib/main.dart`,
  `apps/mobile/lib/app/providers.dart`, `apps/mobile/test/core/backend/**` (new)
- `apps/mobile/pubspec.yaml` and the root `pubspec.lock` (**only you** change dependencies this wave)
- `.github/workflows/ci.yml`, `package.json`, `scripts/**`, `.claude/skills/local-review/SKILL.md`
- `apps/mobile/env/dev.example.json`, `.env.example` (only if a key changes; `check:env` must pass)
- `docs/status/05.md`, your own `.claude-logs/` files

**Not yours** (write the change you need in `docs/status/05.md` and the PR; the lead applies it):
`AGENTS.md` (e.g. the "check:rls not ported yet" row), `docs/HANDOFF.md`, `docs/requirements.md`,
`docs/rules/*`, `docs/EVENTS.md` and the events enum (no new events expected),
`apps/mobile/lib/app/router.dart`, `app.dart`, `features/**`, `packages/**`, `DESIGN.md`.

## Acceptance criteria

- [ ] `supabase db reset` replays cleanly; `supabase test db` passes locally and in CI; output
      pasted in the PR.
- [ ] `check:rls` is in CI and `local-review`, fails on a table without RLS (tested), passes now.
- [ ] **Zero-setup proof:** with no `env/dev.json`, `flutter run -d chrome` starts and shows the
      title screen with **no Supabase network request** (screenshot of DevTools network tab).
- [ ] **Offline proof:** with keys but the local stack stopped, the app starts, nothing blocks,
      no error is shown, a `warn` is logged (screenshot or log excerpt).
- [ ] Widget/unit tests: empty `Env` never touches the backend; a backend fake that throws or
      never completes doesn't delay the first frame; `guest_started` fires exactly once on success.
- [ ] `check:secrets` clean; no service-role key anywhere.
- [ ] All local-review gates green; CI green; `docs/status/05.md` current.

## Events

`guest_started` (registered) is the only one fired. No new events; if you think one is needed,
ask the lead first.

## How to work

- Never edit `docs/HANDOFF.md` (parallel mode). Keep `docs/status/05.md`: done, half-done, next.
- You're the only worker using Docker this wave. Stop the stack (`supabase stop`) when not
  testing; other workers share this Mac's 16 GB.
- Own branch, local-review, PR, CI green, never merge. End with the PR link.
