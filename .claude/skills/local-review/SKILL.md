---
name: local-review
description: 'Run the full local pre-push gate: exactly the commands CI runs, in CI''s order (secrets, standards, format, analyze, events, env, RLS, tests, web build, then migrations + RLS tests), then the commit-message range check and a manual review pass against AGENTS.md and docs/rules. Use when the person says "/local-review", "review this before I push", "is this ready", or has finished a change and wants it validated before CI sees it.'
---

# Local review

A pre-push gate: the same checks CI runs, plus a manual pass against the rules CI can't
automate. Run it once a change is functionally done, not after every edit.

**This is what makes `docs/rules/commits.md`'s don't-over-commit rule work.** CI should
*confirm* what's already verified here, never be the first place a lint error, failing test or
broken web build is found.

## 1. Automated gates, in CI's order

These are exactly the `npm run` commands in the `check` job of `.github/workflows/ci.yml`, then
the `db` job, in the same order. A gate added to one is added to the other in the same PR;
`check:standards` (`local-review-mirrors-ci`) reads both files and fails if they drift.

Stop at the first failure and fix it (or report it) before continuing. Report each command's
real result line, not "it passed". Don't pipe a gate through `tail`: that reports `tail`'s exit
code, not the gate's.

```bash
flutter pub get
npm run check:secrets    # every tracked file, session logs included
npm run check:standards  # the standards checklist (AGENTS.md, hooks, CI, strict analysis, brand tokens…)
npm run format:check     # on failure run the "format" script: always safe, never ask first
npm run analyze          # flutter analyze --fatal-infos: zero errors, warnings AND infos
npm run check:events     # enum ↔ docs/EVENTS.md, no string event names; unfired ones only warn
npm run check:env        # env.dart ↔ env/dev.example.json ↔ .env.example ↔ Edge Functions
npm run check:rls        # every create table enables RLS and has a policy, in the same migration
npm run test             # gate-script tests, then every workspace package's Dart tests
npm run test:functions   # Edge Functions (Deno 2.9.8): lint, format, unit tests with the AI API mocked
npm run build:web        # flutter build web --release: a compile check only, nothing is deployed
```

No Deno on the machine? Run the same gate in Docker:
`docker run --rm -v "$PWD:/repo" -w /repo denoland/deno:2.9.8 sh -c 'deno lint supabase/functions && deno fmt --check --line-width 120 --single-quote supabase/functions && deno test --no-prompt supabase/functions'`.

Then the commit messages, the same check CI's `commits` job runs over the branch:

```bash
git fetch origin main
node scripts/check-commit-message.mjs --range origin/main..HEAD
```

Then CI's `db` job: replay every migration on a fresh local database and run the pgTAP RLS
tests in `supabase/tests/` (`docs/rules/migrations.md`). Docker must be running. Start only the
database (not the whole stack) and stop it afterwards: other worktrees share this machine.

```bash
supabase db start
npm run test:db          # supabase db reset && supabase test db
supabase stop
```

## 2. Manual review pass

Diff the branch against its merge base (`git diff origin/main...HEAD`) and check the changed
files against `AGENTS.md` and the `docs/rules/` file for each area touched:

- **Design** (`docs/rules/components.md`, DESIGN.md): no stock Material look (AppBar, ListTile,
  Card, default ripple, default blue); every colour, size, duration and curve from
  `packages/brand`; empty, loading, offline and error states designed; 44 pt targets; survives
  2x text; reduced motion swaps camera moves for a cross-fade. UI changes have before/after
  screenshots for the PR.
- **Engine** (`docs/rules/code-quality.md`): `packages/engine` stays pure and deterministic;
  new scoring logic has unit tests, including edge cases.
- **Events** (`docs/rules/analytics.md`): a new screen, button or state change has its event
  registered in the enum and `docs/EVENTS.md`; properties carry no PII and no answer text.
- **State** (`docs/rules/state-management.md`): progress is written locally first and synced
  through the outbox; no screen talks to Supabase directly.
- **Secrets** (`docs/rules/secrets.md`): nothing but public keys in `env/*.json`; no credential
  in a comment, fixture or session log.
- **Logging and errors** (`docs/rules/logging.md`, `docs/rules/error-handling.md`): no
  `print`/`debugPrint`; no raw exception text shown to a player.
- **Migrations** (`docs/rules/migrations.md`): a new table has RLS and owner-only policies in the
  same migration, with a test.
- **Magic numbers**: a threshold, weight, duration or limit whose meaning isn't obvious is a
  named constant (or a brand token).
- **Rule of Three**: logic that already exists in two places is extracted before a third copy.
- **God files**: a changed file now mixing layout, state, data access and business logic.
- **Comments**: flag ones that restate the code; a missing one on a non-obvious invariant is also
  a finding.

## 3. Report

A short pass/fail summary: each gate and its real result line, then what the manual pass found
(file:line for each item), separating what blocks from what's worth flagging. Say what you
fixed if you fixed anything trivial (formatting, say). If something needs a judgement call (a
new dependency, a new global provider, a schema change), ask rather than decide.

If everything is clean and the branch is done, this is the moment to write the PR's real title
and description (`docs/rules/pull-requests.md`).
