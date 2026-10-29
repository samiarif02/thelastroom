# Architecture decision records

One file per decision that is hard to reverse or that a reviewer would ask "why?" about:
`NNNN-short-title.md` with Context, Decision, Consequences, Alternatives considered.

The foundation decisions are recorded as project memory for now (`docs/memory/decision-*.md`).
Each is promoted to a full ADR here when its feature is built and the alternatives are
concrete:

- 0001 Flutter without a game engine → `docs/memory/decision-flutter.md`
- 0002 Offline-first with an idempotent outbox → `docs/memory/decision-offline-first-outbox.md`
- 0003 Deterministic engine + server-side AI coach → `docs/memory/decision-engine-and-coach.md`
- 0004 Owner-only RLS instead of 8x's no-client-table-access → AGENTS.md "Where this repo differs"
