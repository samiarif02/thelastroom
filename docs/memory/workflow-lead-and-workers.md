---
name: workflow-lead-and-workers
description: How the lead session and worker sessions hand work over (briefs, uncommitted lead docs, preview links)
type: project
---

One long-lived LEAD session reviews and merges (only on the owner's explicit "merge #N"); worker
sessions build one `docs/briefs/NN-slug.md` each on their own branch and never merge.

- The lead leaves the next brief and its `docs/HANDOFF.md` changes **uncommitted on `main`**.
  The worker's first commit on its branch is those files, unchanged, in their own `docs:` commit.
  No separate lead docs PRs (owner, 2026-10-29).
- The lead reviews in a detached worktree, `../thelastroom-review`, never in the main folder.
- Every PR gets a Vercel preview URL (from brief 02b); reviews and outside reviewers use it.

**Why:** a docs-only PR cost a review and a CI cycle per brief; the preview links make reviews
and the demo the same thing.
**How to apply:** a worker that finds uncommitted `docs/briefs/` or `docs/HANDOFF.md` changes on
`main` commits them first; it doesn't treat them as junk or stash them. Related:
[[workflow-two-profiles]], [[project-and-deadline]].
