# Brief 08: Local progress (drift), outbox sync, account linking (wave 2, worktree w3)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w3`, branch
`feat/08-auth-sync`. **Timebox: PR up by Sat 31 Oct, evening.**

## Goal

Progress lives on the device first and reaches Supabase when it can: a drift database for
attempts and the profile, an outbox that syncs idempotently through the `Backend` interface,
restore on a fresh install, and linking a guest to an email account. All of it invisible and
optional: with no keys or no network the game behaves exactly the same.

Read first: ADR 0002 and 0005, `docs/rules/state-management.md`, `docs/rules/migrations.md`,
`docs/rules/error-handling.md`, FR-3, FR-4, FR-60, FR-61, `apps/mobile/lib/core/backend/`
(brief 05's interface) and `supabase/migrations/`.

## Owner's changes (2026-10-30, after the feedback session): read first

- **No sign-up, no login, no email linking in v1.** The silent guest account (brief 05) is the
  only account. Drop item 5 (linking a guest to email) and the `account_linked` event from this
  brief.
- **The profile now holds what onboarding asks** (brief 13): first name, experience, target role,
  nerves level, calm mode, weekly goal, auto-advance setting. Brief 13 creates
  `core/profile/profile_repository.dart` with a local implementation; **you sync it** to
  `profiles` (new migration: add the columns, owner-only RLS unchanged, pgTAP tests for them),
  and read it from the device first: the server is only a backup, never asked on every launch.
- **Security pass** (owner: "no one can access our database"), in the PR as a checklist:
  - RLS on every table, owner-only, tested for a second user and the `anon` role (exists; extend
    to the new columns).
  - Grants: least privilege per table; no `delete`; server-set columns can't be written by the
    client.
  - `supabase db lint` and the Security Advisor clean; paste the output.
  - Only the **anon (publishable) key** is in the app; it is public by design and safe only
    because of RLS. The service-role key and any AI key are **never** in the app or the repo:
    server secrets live in Supabase Edge Function secrets. `check:secrets` stays clean.
  - The first name is personal data: never in analytics events or logs (test).
  - Rate-limit friendliness: the sync worker backs off and batches; no tight retry loops.

## Order change: brief 10 lands before you (owner, 2026-10-30)

The mission player (10) is built first and saves attempts through
**`apps/mobile/lib/core/progress/progress_repository.dart`**: an interface (`recordAttempt`,
`attempts`, `baseline`), an in-memory implementation and a provider. **Implement that interface
on drift** (attempt + outbox row in one transaction) and override its provider, so the player
persists and syncs without a screen edit. Add methods if you need them; don't rename them.

## Hard rules

- Zero setup and offline (AGENTS.md 6): no keys → the database and outbox still work locally;
  sync never runs. A sync failure is a `warn` log and a retry, never a visible error.
- The UI reads only from the local database. Nothing outside `core/backend` imports
  `supabase_flutter` (only `supabase_backend.dart` does).
- Attempts are append-only and synced with **insert on conflict do nothing** (`ignoreDuplicates`)
  on the device-generated `attempt_id`. Never an update.

## In scope

1. **drift** in `apps/mobile/lib/core/db/`: `attempts` (mirrors `mission_attempts`, plus the
   draft text, which **never leaves the device**), `profile` (target role, nerves level, calm
   mode, interview date, `chapter_2_waitlist_at`), `outbox`. Works on Android, iOS and the web
   (drift's WASM files committed under `apps/mobile/web/`, so a fresh clone runs in Chrome).
2. **Repositories + providers:** record an attempt (one transaction: attempt + outbox row),
   read progress, update the profile, join the waitlist (FR-5 / D1: a flag, no email form).
3. **Sync worker** in `core/sync/`: flushes the outbox through new `Backend` methods
   (`insertAttempts`, `upsertProfile`, `fetchAttempts`) on start, on reconnect and after each
   attempt; exponential backoff; idempotent.
4. **Restore** (FR-61): signed in on a fresh install with an empty local db → fetch attempts and
   profile from the server once.
5. **Link a guest to email** (FR-3) through the `Backend`: the anonymous user adds an email
   (Supabase `updateUser` + the confirmation/OTP flow), keeping the same `user_id` and every
   attempt. **Service and tests only**: the "Save your progress" sheet is UI for brief 10, built
   on 06's components. Google sign-in needs owner-side OAuth setup, so it's **out** for v1
   (record it in the PR as a v2 note).
6. **Events:** fire `account_linked` (`provider: email`) and `waitlist_joined` (both registered)
   at the service layer.
7. **The flag drift test** (lead note on PR #7): a test that the engine's `Flag` wire names equal
   the `flags` check list in the `mission_attempts` migration, so they can't drift apart.

## Out of scope

- Any screen or sheet (10, 13). Google sign-in (v2). The coach (12). New migrations, unless a
  column is genuinely missing (then a new migration with its pgTAP test, and say why).

## File ownership (parallel wave: touch only these)

- `apps/mobile/lib/core/{db,sync}/**` (new), `apps/mobile/lib/core/progress/**` (after 10
  merges: your drift implementation and the provider override), `apps/mobile/lib/core/backend/**`,
  `apps/mobile/lib/main.dart`, `apps/mobile/lib/app/providers.dart`
- `apps/mobile/test/core/{db,sync,backend}/**`, `apps/mobile/web/sqlite3.wasm`,
  `apps/mobile/web/drift_worker.js` (new files only; `web/index.html` is 06's)
- `supabase/**` (only if item "Out of scope" allows), `packages/engine/test/` **only** for the
  flag drift test file
- `docs/status/08.md`, your own `.claude-logs/` files

**Shared this wave (the later PR rebases and reruns `flutter pub get`; the lead checks):**
`apps/mobile/pubspec.yaml` and `pubspec.lock`. You add drift and its tooling; brief 09 adds
`flutter_soloud` and `shared_preferences`. Add only your lines. Brief 09 may add **one** audio
preload line to `main.dart`; leave `main`'s startup as a short, readable list so it merges.

**Not yours:** `apps/mobile/lib/ui/**`, `features/**`, `router.dart`, `app.dart`, `web/index.html`,
`packages/brand|content`, engine `lib/`, CI, `scripts/`, the events registry (no new events),
`AGENTS.md`, `DESIGN.md`, `docs/HANDOFF.md`, `docs/requirements.md`, `docs/rules/*` (propose
wording in your status file).

## Acceptance criteria

- [ ] Tests: record attempt → attempt + outbox row in one transaction; flush twice → one server
      row (fake backend); offline then online → flushes; restore on an empty db; linking keeps
      the `user_id`; no keys → sync never starts; the flag drift test.
- [ ] Against the local stack (`supabase start` + `env/dev.json`): an attempt recorded on the
      phone appears once in `mission_attempts`; killing the network mid-sync then restoring it
      leaves exactly one row (paste the SQL output in the PR).
- [ ] Fresh clone, no env file, Chrome: app starts, drift works, no Supabase request.
- [ ] All local-review gates green (incl. the `db` job); CI green; `docs/status/08.md` current.
- [ ] No UI change, so no screenshots; say so.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/08.md`: done, half-done, next.
- You're the only worker using Docker this wave; `supabase stop` when not testing.
- **No phone:** the OnePlus is 06's only and the realme is the lead's. Test with unit tests and
  Chrome; the lead checks Android in review. The owner runs two workers at a time.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
