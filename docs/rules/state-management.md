# State management

**Riverpod 3** for state and dependency injection, **go_router** for navigation and deep links,
**drift** (SQLite, WASM on web) for local persistence. Offline-first: the device is the source of
truth for the player's progress; the server is a backup and a sync target.

## Where state lives

| Kind | Where |
| --- | --- |
| App services (env, log, analytics, db, sync, notifications) | `Provider`s in `lib/app/providers.dart` / `lib/core/*`, overridden in `main.dart` and in tests |
| A screen's ephemeral UI state (an animation, a focused field) | the widget (`StatefulWidget`), not a provider |
| A feature's state (the current mission's picks, timer, follow-up) | a `Notifier`/`AsyncNotifier` next to the feature (`features/<f>/<f>_controller.dart`) |
| Game rules and scores | `packages/engine`: pure functions the controller calls, never inside a widget or provider |
| Content (missions, interviewers, lessons) | `packages/content`: const data, versioned |
| Progress, attempts, recall cards, settings | drift tables in `core/db`, exposed through repositories |
| Remote sync | `core/sync`: the outbox, flushed when online through the `Backend` interface (`core/backend`) |

## Rules

- **Write locally first.** Completing a mission writes the attempt to drift *and* an outbox row
  in one transaction. The UI never waits on the network.
- **The outbox is idempotent.** Each attempt has a client-generated `attempt_id`; the server
  upserts on it. Retries are safe, ordering doesn't matter.
- **No screen talks to Supabase.** Only `apps/mobile/lib/core/backend/supabase_backend.dart`
  imports `supabase_flutter`. Sync and sign-in go through the `Backend` interface
  (`core/backend/backend.dart`), so tests swap in a fake and the app runs with no backend at all.
- **No global mutable singletons.** Everything injectable goes through a provider so tests can
  override it.
- **Providers are read in `build` with `ref.watch`, and in callbacks with `ref.read`.**
- **Restore on fresh install**: after sign-in on a new device, progress is pulled from the server
  into drift, then the outbox resumes.
- **Routes are constants** (`Routes` in `lib/app/router.dart`); notification deep links resolve
  to them.
