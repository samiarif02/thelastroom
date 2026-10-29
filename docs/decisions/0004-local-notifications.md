# 0004. Local scheduled notifications in v1; remote push in v2

- **Status:** accepted (2026-10-29)
- **Memory:** [`docs/memory/decision-local-notifications.md`](../memory/decision-local-notifications.md)

## Context

Retention is the theme ("learning that sticks"): the Recall Room is due on days 1, 3 and 7, and
a story thread is left open at the end of a session. Notifications in an interviewer's voice
bring the player back (brief §8). We have no app server, the game is offline-first, and the
build is 7 days.

## Decision

Use `flutter_local_notifications` with `timezone`. On every app open and close: cancel all, then
schedule the next 7 days from local state (recall due dates, last session, usual play hour),
respecting at most one a day, quiet hours 21:30–08:30, and the back-off to the comeback ladder
after 3 ignored. Inexact scheduling on Android, so no exact-alarm permission. Permission is asked
after Mission 2 behind a custom pre-prompt. The web build has none.

## Consequences

- Works offline and needs no server, no FCM/APNs setup and no device-token table.
- The schedule is only as fresh as the last app open. A player who never opens the app again
  gets the comeback ladder that was scheduled last time, then silence: kind by design.
- Copy can't change without an app release, and we can't win back a player who reinstalled.
  Those are the reasons remote push exists, and why it's v2.
- iOS caps pending notifications at 64; 7 days at one a day is far below it.
- Measured with `notification_opened` (type, variant) so the copy can be judged.

## Alternatives considered

- **Remote push (FCM / APNs) now.** Needs a server-side scheduler, a token table and store
  setup on both platforms. More moving parts than the deadline allows, for little gain in v1.
- **No notifications.** Saves a day but drops the Day 3 / Day 7 answer the brief is built on.
- **Web push on the demo.** Needs a service worker permission flow and a server; reviewers
  wouldn't see it in a short visit anyway.
