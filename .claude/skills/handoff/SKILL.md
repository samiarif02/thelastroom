---
name: handoff
description: Save the shared brain so the other Claude profile (or any agent) can continue mid-task. Use when the person says "handoff", "save brain", "I'm switching profiles", "running out of quota", or before a long task. Brings docs/HANDOFF.md fully up to date, records durable facts in docs/memory/, lists uncommitted files, and prints the exact one-line prompt the other profile should start with.
---

# Handoff

Two Claude profiles (`claude` and `claude-geo`) work on this repo in turn; either can run out of
quota without warning. The repo is the brain. This skill makes sure it's current.

## 1. Gather the real state (don't write from memory)

```bash
git branch --show-current
git status --porcelain
git log --oneline -5
git diff --stat
```

## 2. Rewrite docs/HANDOFF.md

Keep exactly these sections (`check:standards` checks for them). Be concrete: file paths,
commands, the exact error text. The reader has none of this conversation's context.

- **Current goal**: the session's goal in one or two sentences, and which prompt/PR it belongs to.
- **Branch**: the branch name, whether it's pushed, the PR URL if any, CI state.
- **Done**: what's finished and verified (and how it was verified).
- **In progress**: each half-done file and what's missing in it. "Nothing" if nothing.
- **Next steps**: numbered, concrete, in order. The first one should be startable immediately.
- **Open decisions for the person**: questions only they can answer.
- **Gotchas**: traps found this session (a flaky command, a tool quirk, a dead end and why).

Update the "Last updated" line with the date, time and profile (`$CLAUDE_CONFIG_DIR`, or
`~/.claude` if unset).

## 3. Move durable facts to docs/memory/

Anything that will still be true next week (a decision, a constraint, a convention, a
deadline) goes in `docs/memory/<slug>.md`, one fact per file, indexed in
`docs/memory/MEMORY.md`. Not in Claude's personal memory: the other profile and other agents
can't see it.

## 4. Report

Print:

1. The list of uncommitted files (from `git status --porcelain`), or "working tree clean".
   Uncommitted work is fine: both profiles share this folder, so nothing needs committing to
   hand off.
2. This exact line, for the other profile to paste (or tell the person to use
   `claude --continue` / `claude-geo --continue` first, which resumes the full conversation):

```text
Read docs/memory/MEMORY.md and docs/HANDOFF.md, check git status, then continue from Next steps.
```

Remind the person: never run both profiles on this folder at the same time.
