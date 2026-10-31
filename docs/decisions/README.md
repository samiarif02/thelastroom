# Architecture decision records

One file per decision that is hard to reverse or that a reviewer would ask "why?" about:
`NNNN-short-title.md` with Context, Decision, Consequences, Alternatives considered. The short
version of each lives in project memory (`docs/memory/decision-*.md`), which links here.

- [0001 Flutter widgets for the cinematic layer, not Flame](0001-flutter-widgets-not-flame.md)
- [0002 Offline-first, with an idempotent outbox](0002-offline-first-outbox.md)
- [0003 Deterministic scoring; AI only for free text](0003-deterministic-scoring-and-ai-coach.md)
- [0004 Local scheduled notifications in v1; remote push in v2](0004-local-notifications.md)
- [0005 Zero setup, fully offline, backend optional](0005-zero-setup-offline-backend-optional.md)
- [0006 An AI recruiter scores the answer; the engine stays for offline play](0006-ai-scoring.md)

Still to write when its feature is built: owner-only RLS instead of 8x's no-client-table-access
(milestone 05; the divergence is recorded in `AGENTS.md` meanwhile). There's no web host to
record: 0005 dropped the hosted web demo.
