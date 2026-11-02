---
name: decision-local-notifications
description: v1 uses local scheduled notifications (in-character, kind, back off after 3 ignored); remote push is v2; none on web
type: project
---

v1 uses **local scheduled notifications** (`flutter_local_notifications` + timezone): daily
nudge, recall due, cliffhanger, comeback ladder (2/4/7/14 days then stop), weekly win. In an
interviewer's voice, never guilt. At most 1 per day, quiet hours 21:30–08:30, back off to the
ladder after 3 ignored, permission asked after Mission 2 behind a custom pre-prompt.
"Cancel all, reschedule next 7 days" on every open/close (iOS caps pending at 64). Android 13+
`POST_NOTIFICATIONS`, boot receiver, inexact scheduling. Web skips them. Remote push (FCM) is v2.

**As built (briefs 26, 42):** daily nudge and recall due only; days 1, 3, 5 after the last open,
then day 8 (the owner wants returns on days 3 and 5); 09:00–20:30; permission after Mission 1.
Settings shows the next one and has "Send a test reminder" (shows tomorrow's now). The tower's
"welcome back" card covers the player who returns.

**Why:** works offline, no server, still shows retention thinking (brief §8).
**How to apply:** full design in `docs/product-brief.md` §8; events `notification_*` are
already registered.

Full record, with alternatives: [ADR 0004](../decisions/0004-local-notifications.md).
