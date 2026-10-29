---
name: workflow-two-profiles
description: Two Claude profiles share this repo; the repo (HANDOFF + memory) is the brain, never run both at once
type: reference
---

The owner uses two Claude Code profiles: `claude` (`~/.claude`) and `claude-geo`
(`CLAUDE_CONFIG_DIR=~/.claude-geo`). Both profiles' project folders for this repo are symlinked
to `~/.claude-shared/projects/-Users-mac-WebstormProjects-thelastroom`, so `--continue` works
from either. The session-log hook reads `$CLAUDE_CONFIG_DIR/projects` for the same reason.

**How to apply:** read `docs/HANDOFF.md` at the start, update it after every meaningful step,
run the `handoff` skill on "handoff"/"save brain". Never run both profiles at once.
