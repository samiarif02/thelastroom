# Project memory

Durable facts, one per file. Every session (either Claude profile, any agent) reads this index
and `docs/HANDOFF.md` first. Add a file and a line here when something will still be true next
week. `check:standards` (`shared-brain`) fails on a dangling or unindexed file.

- [Project and deadline](project-and-deadline.md): 8x assessment, due **2026-11-05**, public repo
- [Scoring rubric](scoring-rubric.md): the 8 criteria and 100 points we're judged on
- [Decision: Flutter](decision-flutter.md): Flutter 3.47.8, no Flame, web build as the demo
- [Decision: offline-first + outbox](decision-offline-first-outbox.md): drift, idempotent sync, owner-only RLS
- [Decision: engine + AI coach](decision-engine-and-coach.md): deterministic engine, server-side coach for free text
- [Decision: Chapter 1 scope](decision-scope-chapter-1.md): Chapter 1 complete, 2–3 locked
- [Decision: local notifications](decision-local-notifications.md): local in v1, remote push v2
- [Two profiles, one brain](workflow-two-profiles.md): how the claude / claude-geo handoff works
- [Lead and workers](workflow-lead-and-workers.md): parallel worktrees, file ownership, status files, one lead docs PR per wave
- [Gotcha: env deny rules](gotcha-env-deny-rules.md): deny rules have no exceptions; each real env file is denied by name
