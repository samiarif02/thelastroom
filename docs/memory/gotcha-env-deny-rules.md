---
name: gotcha-env-deny-rules
description: Claude's Read deny rules can't express "except *.example.json", so real env files are denied by exact name
type: reference
---

`.claude/settings.json` denies agents `Read` on real env files. Claude Code permission rules
have **no exceptions**: a deny always beats an allow, so `Read(**/env/*.json)` would also block
the committed `env/*.example.json` templates. So each real file is denied **by name**:
`env/dev.json`, `env/staging.json`, `env/prod.json`, `env/local.json` (plus `.env`, `.env.local`,
`.env.*.local`, `supabase/functions/.env`).

**Why:** agents must read the `*.example.json` files to keep `check:env` in step, and must never
read the real ones.
**How to apply:** when adding a flavor file (say `env/qa.json`), add its deny rule to
`.claude/settings.json` in the same PR. `.gitignore` already ignores `**/env/*.json` except
`*.example.json`, so git is safe either way; only agent reads need the new rule. See
`docs/rules/secrets.md`.
