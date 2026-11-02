---
name: feedback-claude-logs-every-pr
description: Every PR and every merge carries the session's Claude logs (scored, 15 pts); the pre-push hook enforces it
type: feedback
---

Every pushed branch and every PR must include a `chore(claude): add session logs` commit with the
latest `.claude-logs/` file of the session that did the work, made right before the push. Work
done by background agents is logged inside the *parent* session's log file, so the parent's
log must be copied into the agent's branch before it pushes, and a full log sweep
(regenerate every session from its transcript with `CLAUDE_TRANSCRIPT=… python3
.claude/hooks/extract-log.py`) runs after every merge batch.

**Why:** the owner is scored on the Claude logs (15 points) and on reviewers seeing their own
prompts; merged PRs without logs made it look like no one was working. The owner flagged it
three times (2026-11-02: "claude logs are essential… make sure this mistake never happen").
**How to apply:** never push or merge without the log commit; the repo's pre-push hook enforces
it. Repo copy: docs/memory/feedback-claude-logs-every-pr.md. Related: [[workflow-lead-and-workers]].
