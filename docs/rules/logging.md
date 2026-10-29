# Logging

Two tools, two jobs, as in 8x's template:

- **The log wrapper** (`apps/mobile/lib/core/logging/log.dart`, provided as `logProvider`) is the
  *record of what happened*: the outbox flushed 3 attempts, a mission loaded in 40 ms, a sync was
  skipped because the device is offline. Structured: a message plus a map of fields, one JSON
  object per record.
- **Sentry** (wired later; `docs/rules/error-handling.md`) is for *what broke and someone should
  look at*: an unexpected exception. It is not a log of routine activity.

An expected, handled failure (offline, the coach's daily limit reached) is neither an error nor
log spam: it's normal control flow, shown to the player as a designed state.

## Using it

```dart
final log = ref.read(logProvider);
log.info('outbox flushed', {'count': 3, 'ms': 120});
log.warn('sync deferred', {'reason': 'offline'});
log.error('migration failed', error: e, stackTrace: st);
```

- **Never `print` or `debugPrint`.** `avoid_print` is an analyzer error and `check:standards`
  (`structured-logger`) also catches `debugPrint`.
- Messages are fixed strings; variable data goes in fields (so logs can be searched and grouped).
- **Never log answer text, drafts, emails or tokens.** The wrapper redacts sensitive field names
  (`answer`, `draft`, `email`, `token`, `api_key`…) and credential-shaped values before any sink
  sees them, but don't rely on it: don't pass them in the first place.
- Level: `debug` in dev, `info` and up in prod (`main.dart`).
- A failing sink never throws into the caller.

The redaction patterns mirror `scripts/check-secrets.mjs` and the session-log hook's
`REDACTIONS`; when one changes, check the others.
