# Brief 26: notifications (worktree w4)

From the lead (thelastroom-w1-ba), 2026-11-01. Worktree `../thelastroom-w4`, branch
`feat/26-notifications` from `origin/main`. Worker: thelastroom-9a. This is v1-plan phase 11
(FR-50–53), not built yet; the README lists it as a limit.

## Scope

Local notifications only (ADR 0004: local in v1, remote in v2). Android first, then iOS if it's
cheap.

- **Recall due:** "3 traps are waiting in the Recall Room", when cards are due.
- **Daily nudge,** in character, from the next mission's interviewer (e.g. Priya: "Still thinking
  about why you'd take this role?").
- **Kind and backing off:** at most 1 a day; after 3 ignored nudges, drop to every 3 days;
  never after 21:00 local.
- **Deep links:** a tap opens `/tower/recall` or `/tower/mission/N` (the router already
  supports both).
- **Permission,** asked at a designed moment (after the first mission's debrief, with a vivid
  explainer card), never on launch. Android 13+ needs the `POST_NOTIFICATIONS` runtime
  permission.
- **Off switch:** a toggle in Settings, using the existing `VividToggle`.
- **Events:** `notification_permission_prompted`, `notification_permission_granted` and
  `notification_opened` are already registered; fire them.
- **Tests:** the scheduling rules as pure functions, unit-tested.

## Owns

`apps/mobile/lib/core/notifications/**` (new), one Settings row (coordinate with 1e), the
AndroidManifest permissions (tell 1e), and `pubspec.yaml` (`flutter_local_notifications`; say so
in the PR).

## Done when

local-review, then ship; the lead gets the PR link and checks it on the realme.
