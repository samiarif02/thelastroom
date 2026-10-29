@AGENTS.md

## Claude Code notes

- **Two profiles share this project.** `claude` (`~/.claude`) and `claude-geo`
  (`CLAUDE_CONFIG_DIR=~/.claude-geo`) both see the same session history through a symlinked
  project folder (`~/Downloads/thelastroom-kit/setup-shared-brain.sh`). When one runs out of
  quota, the other resumes with `--continue`. The repo (`docs/HANDOFF.md`, `docs/memory/`) is the
  brain that matters; Claude's personal auto-memory is not shared with other agents or reviewers,
  so never keep a fact only there.
- Shared settings, skills and MCP config live in the repo: `.claude/settings.json`,
  `.claude/skills/`, `.mcp.json`. Personal approvals go in `.claude/settings.local.json`
  (gitignored), never in a profile's home folder.
- Skills: `local-review` (exactly what CI runs), `ship` (gates → commit → PR → green CI, never
  merge), `handoff` ("handoff" / "save brain").
- `.claude/settings.json` denies reading real env files. Don't work around it; ask the person
  for the value you need, or read the `*.example` file.

## Session Logs

`.claude/settings.json` runs `.claude/hooks/extract-log.py` on `UserPromptSubmit`, `Stop` and `SubagentStop`, writing prompt + final-response transcripts to `.claude-logs/`. Each session file ends with a "Subagents" section. Always commit `.claude-logs/` with your changes.

The script reads transcripts from `$CLAUDE_CONFIG_DIR/projects` (default `~/.claude/projects`),
the one deviation from 8x's logging guide, so both profiles are logged. Logs are staged in their
own commit, right before the push (the `ship` skill).
