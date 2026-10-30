---
name: workflow-lead-and-workers
description: How the lead session and parallel worker worktrees hand work over (briefs, file ownership, status files, docs PRs)
type: project
---

Parallel mode (kit README §4c, owner, 2026-10-29). One long-lived LEAD session in the main folder
reviews and merges (only on the owner's explicit "merge #N"); up to four workers (the owner raised it from three, 2026-10-30) each build one
`docs/briefs/NN-slug.md` in their own worktree `../thelastroom-w1..w4` and never merge.

- The lead creates each worktree (`git worktree add ../thelastroom-wN -b <branch> main`) and
  commits the brief as the branch's first commit; worktrees only see committed files.
- Every brief lists its **file ownership**; parallel briefs never own the same files. Shared hot
  spots (pubspecs and `pubspec.lock`, the events registry, CI, `AGENTS.md`) belong to one brief
  per wave, or the lead resolves them at merge.
- Workers never edit `docs/HANDOFF.md`; each keeps `docs/status/NN.md` (done, half-done, next).
  The lead owns HANDOFF and lands its docs in one small `docs/lead-wave-N` PR per wave.
- Merge in dependency order; after each merge the other open branches rebase on `main`; the lead
  removes the merged worktree. The lead reviews in a detached `../thelastroom-review`.
- There is no hosted preview: the lead reviews by running the branch locally (ADR 0005).

**Why:** parallel workers finish the 7-day build sooner; ownership and status files stop two
sessions from editing the same file.
**How to apply:** a worker that needs a file it doesn't own writes the change it needs in its
status file and asks the lead. Related: [[workflow-two-profiles]], [[project-and-deadline]].
