---
name: decision-offline-first-outbox
description: Offline-first: bundled content and engine, local drift DB, idempotent outbox sync to Supabase with owner-only RLS
type: project
---

The game plays fully offline: content and engine are bundled, progress lives in local SQLite
(drift, WASM on web). Completed attempts go into a local **outbox** and are flushed to Supabase
when online, **upserted on a client-generated `attempt_id`** so retries never duplicate. Supabase
anonymous auth gives a guest a real user id instantly; the account is linked to email/Google
later. Tables have **owner-only RLS policies** (the client touches its own rows), which differs
from 8x's template (client never touches tables) and is recorded in AGENTS.md.

**Why:** plays anywhere; the server only stores progress; guest play from second one.
**How to apply:** write locally first, never await the network in the UI, test RLS like code
(`docs/rules/migrations.md`, `docs/rules/state-management.md`).
