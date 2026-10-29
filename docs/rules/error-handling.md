# Error handling

## Expected vs. unexpected

- **Expected failures** are part of the domain: offline, sync conflict, the coach's daily limit,
  an invalid content file caught by validation. Model them as types (a sealed `Result`/failure
  class, or a typed exception caught at the feature boundary) and show a **designed state**.
- **Unexpected failures** are bugs: a null where there can't be one, a plugin throwing. They go
  to `FlutterError.onError` / `PlatformDispatcher.instance.onError` (wired in `main.dart`), to
  the log at `error`, and to Sentry once it's wired. Don't catch-and-ignore them.

## Rules

- **Never show raw exception text to a player.** Every error state is written copy, in the
  game's voice, and *cinematic* like every other state (brief §9: "The lights are out. Your
  progress is safe on this device.").
- **Never lose progress to an error.** Attempts are written locally first; sync failures retry
  from the outbox. An error screen always says what is safe.
- **Catch narrowly.** `on SomeException catch` at the boundary that can do something about it;
  `on Object catch` only at top-level guards, and then log it.
- **`only_throw_errors`**: throw `Exception`/`Error` subclasses, never strings or maps.
- **No silent fallbacks that hide bugs.** A failed query surfaces as an error state, never as an
  empty list the player mistakes for "no data".
- Async: `unawaited_futures` and `discarded_futures` are errors. If a future is deliberately
  fire-and-forget, wrap it in `unawaited(...)` and say why.
