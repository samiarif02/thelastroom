---
name: ship
description: Land finished work the standard way - run the local-review gates, commit in Conventional Commits (session logs in their own commit, right before the push), push the branch, open the pull request and watch CI to green. Use for "ship it", "push this up", "verify and push", "ready to ship?", "push to main" or "merge to main". Every one of them ends in a branch and a PR with green CI, never a push to main; an agent merges a PR only when the person explicitly tells it to merge that PR.
argument-hint: "[optional: 'check' to run the gates and report without committing]"
---

# Ship

Verified locally, committed in the standard format, pushed to a branch, opened as a pull request
with a description a reviewer can trust, green in CI. Then stop. **An agent never merges on its
own.**

"Push to main" and "merge to main" mean "land this": a branch and a PR. Say so in one line and
carry on.

## Golden rules

1. **Never push to `main`, never merge a PR on your own, never force-push** anything but your
   own branch, and never to get around a failing check.
2. **Gates before push.** A gate fails: stop, show the real output, fix it or report it.
3. Never `--no-verify`, never a blind `git add -A` / `git commit -a` over a dirty tree. If the
   tree has changes unrelated to this task, say so and ask before sweeping them in.
4. Never stage real env files (`.env`, `env/*.json` other than `*.example.json`), keystores,
   `*.jks`, `*.p8`, `key.properties`, `google-services.json` (`docs/rules/secrets.md`).
5. `/ship check` runs steps 1–3 and reports. It commits and pushes nothing.

## 1. Orient

```bash
git rev-parse --abbrev-ref HEAD && git status --porcelain && git fetch origin main
```

On `main`? Create a branch first: `git switch -c <type>/<short-kebab-name>`
(`feat/mission-scene`, `fix/offline-banner`). Behind `origin/main` and not pushed yet: rebase.
Already pushed: never rewrite it; merge `origin/main` in if you must.

## 2. Classify the change

List what changed (`git diff --name-only origin/main...HEAD` plus the working tree) and say, in
the report and the PR:

- **Ships how?** Web demo (redeploys from `main`), a new APK/store build (anything under
  `android/`, `ios/`, a new plugin, permissions, icons, version), an Edge Function deploy, or a
  migration. See `docs/rules/deployment.md`.
- **Events**: a user-visible change has its events registered first.
- **Schema**: `supabase/migrations/` changed → replay locally and run the RLS tests.

## 3. Gates: the `local-review` skill

Run `.claude/skills/local-review/SKILL.md`. Its command block is exactly what CI runs, in CI's
order. Don't keep a second copy of the list here. Stop at the first failure.

## 4. Commit: Conventional Commits

`docs/rules/commits.md`: `type(scope): subject`, imperative, lowercase, no trailing period,
header ≤ 72 characters, body after a blank line with a `Changelog:` line. Scopes are curated in
`scripts/check-commit-message.mjs`.

- **Stage by path**, deliberately. A few commits per PR, each one unit of work; formatting and
  logic never share a commit.
- A rejected message is rewritten, never bypassed.
- **Session logs go last, in their own commit, right before the push**, so the transcript
  includes as much of the session as possible:

```bash
git add .claude-logs/ && git commit -m "chore(claude): add session logs"
```

## 5. Push the branch

```bash
git push -u origin <branch>
```

Never `main`. Rejected because the branch moved: fetch and integrate; never force.

## 6. Open the pull request

Finished work gets the real title and description now; unfinished work is a draft with a
one-line placeholder (`docs/rules/pull-requests.md`).

```bash
gh pr create --base main --title "<type(scope): subject>" --body-file <file>
```

The body:

1. **What changed and why**, in plain words.
2. **Standards**: `npm run check:standards` result on the branch (and on `main` if it changed).
3. **Gates**: each command `local-review` ran and its real result line.
4. **Ships how**: web, APK/store build, Edge Function, migration, or "nothing ships".
5. **Screenshots** for any UI change: before/after (`docs/rules/pull-requests.md`).
6. **Watch list**: what to check after merge.
7. **Where this differs** from the plan, and why.

## 7. Watch CI

```bash
gh pr checks <number> --watch
```

Green: report and stop. Red: read the failing step's log (`gh run view <id> --log-failed`), fix
it properly, run the gates again, push once. Don't push guesses.

## 8. Report, then stop

The PR URL, the commits, each gate's result, CI's result, and what's left for the person:
**the merge**, and any release step. Update `docs/HANDOFF.md`.

## 9. Merge, only when told to

Only when the person explicitly says to merge that PR, with CI green and the branch up to date:
`gh pr merge <number> --merge` (a merge commit, never a squash, so the per-commit history and
the logs commit survive). An instruction to merge one PR covers that PR, not the next.
