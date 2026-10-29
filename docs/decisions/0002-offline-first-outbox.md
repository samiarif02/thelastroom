# 0002. Offline-first, with an idempotent outbox

- **Status:** accepted (2026-10-29)
- Amended by [0005](0005-zero-setup-offline-backend-optional.md): the backend is optional at runtime.
- **Memory:** [`docs/memory/decision-offline-first-outbox.md`](../memory/decision-offline-first-outbox.md)

## Context

Players practise on a commute, in a lift, before an interview: the network is not a given.
Chapter 1 must be fully playable offline (NFR-4), and progress must survive a reinstall once
the player has an account (FR-61). We have no server of our own; Supabase is the backend.

## Decision

- Content and the engine ship inside the app. A mission never needs the network.
- Every attempt is written to a local SQLite database (drift; WASM on the web) **first**, and
  the UI reads only from it.
- A completed attempt also goes into an **outbox** table. A sync worker flushes it whenever the
  app is online, upserting to `mission_attempts` on a client-generated `attempt_id` (UUID), so a
  retry after a timeout never makes a duplicate.
- The device writes its own rows directly, guarded by **owner-only RLS policies**, tested like
  code (`docs/rules/migrations.md`). This is the divergence from 8x's template recorded in
  `AGENTS.md`.
- Each attempt stores the `contentSchemaVersion` it was scored against, so a server-side score
  can always be traced to its content.

## Consequences

- The game starts and plays with no account and no network. Anonymous sign-in (FR-2) happens in
  the background; until it succeeds, the outbox just waits.
- Conflicts are simple because attempts are append-only: the server never edits an attempt, and
  "progress" is derived from the attempts. Profile fields (nerves level, calm mode) use last
  write wins, which is acceptable for a single player on few devices.
- Two sources of truth to keep honest: tests cover "flush twice, one row" and "offline then
  online".
- drift on the web wants cross-origin isolation (COOP/COEP headers) for its fastest storage
  mode. That's moot now: there's no hosted web build to set headers on (ADR 0005), and
  `flutter run -d chrome` falls back to IndexedDB-backed storage, which is fast enough.

## Alternatives considered

- **Online-only (read and write Supabase directly).** Simplest, but breaks NFR-4 and makes every
  tap wait on the network.
- **Supabase realtime or a sync library (PowerSync, ElectricSQL).** Real bidirectional sync is
  more than append-only attempts need, and adds a service and a learning curve in a 7-day build.
- **An Edge Function as the only write path (8x's "client never touches tables").** Keeps
  authorization in code, but adds a server hop and a deploy for every write; owner-only RLS on
  three small tables is easier to test and to reason about.
