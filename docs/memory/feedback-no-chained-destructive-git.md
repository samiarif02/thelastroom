---
name: feedback-no-chained-destructive-git
description: Never chain a destructive git step (branch delete, worktree remove, reset) after another command; run it alone and check the result first
type: feedback
---

Run every destructive git or GitHub step (deleting a branch locally or on GitHub, removing a
worktree, `reset`, closing a PR) as **its own command**, and only after checking that the step
before it really did what it should. Never put it at the end of an `&&` / `;` chain.

**Why:** on 2026-10-30 the lead ran `gh pr merge 6 … ; gh pr view … && git push origin --delete …`.
PR #6 was still a draft, so the merge was refused, but `gh pr view` succeeded and the chain went
on to delete the branch on GitHub and locally, which closed the PR. It was recovered from the
commit (`90ad86f`), but the owner said: "no more chained commands that delete branches. check
each step before the next."
**How to apply:** merge → confirm `state == MERGED` and the head is an ancestor of `origin/main`
→ only then delete the remote branch → check → delete the local branch → check → remove the
worktree. `gh pr merge` also fails on drafts: check `isDraft` first. Related:
[[workflow-lead-and-workers]].
