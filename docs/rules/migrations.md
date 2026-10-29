# Migrations (Supabase)

Schema lives in `supabase/migrations/` as plain SQL, created with the Supabase CLI. This differs
from 8x's Prisma flow (AGENTS.md, "Where this repo differs"): the app reads and writes its own
rows directly, so **RLS policies are the authorization layer** and get tested like code.

## Making one

```bash
supabase migration new <snake_case_description>   # creates supabase/migrations/<ts>_<name>.sql
supabase db reset                                  # replays every migration + seed.sql locally (Docker)
```

## Rules

1. **Every table has RLS enabled and owner-only policies in the same migration that creates
   it.** `using (auth.uid() = user_id)` for select/update/delete, `with check (auth.uid() =
   user_id)` for insert/update. No table is ever briefly open.
2. **Every policy has a test** that proves a second user can't read or write the first user's
   rows (pgTAP via `supabase test db`). CI's `db` job runs `supabase test db` on every PR, and
   `check:rls` (in the `check` job) fails a migration that creates a table without RLS and a
   policy in the same file.
3. **Never edit a migration that's merged.** Write a new one.
4. **Additive first.** Adding a column or table is safe. Renaming or dropping one breaks app
   builds already installed on phones (they can't be force-updated): add the new shape, ship an
   app that uses it, and only then remove the old one in a later migration.
5. **Idempotent sync.** `mission_attempts.attempt_id` is a client-generated UUID with a unique
   constraint; the outbox inserts with `on conflict (attempt_id) do nothing` (supabase-dart:
   `upsert(..., ignoreDuplicates: true)`), so a retried sync never duplicates an attempt.
   Attempts are append-only and have no update policy, so a plain upsert (which updates on
   conflict) would be refused.
6. **Server-controlled columns** (`created_at`, usage counters in `coach_usage`) are set by
   defaults or the Edge Function, never trusted from the client; policies or triggers enforce it.
7. **Seed data** (`supabase/seed.sql`) is for local development only and contains no real
   person's data.
8. Deploy order: migration first (`supabase db push` after merge), then the app or function that
   depends on it (`docs/rules/deployment.md`).
