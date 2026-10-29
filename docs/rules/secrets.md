# Secrets

## Where each kind of value lives

| Value | Where | In git? |
| --- | --- | --- |
| Public app config (Supabase URL + anon key, PostHog key, Sentry DSN) | `apps/mobile/env/<flavor>.json`, passed with `--dart-define-from-file` | **No.** Only `env/*.example.json` (empty values) is committed. |
| Server secrets (Anthropic API key, any service-role key) | Supabase Edge Function secrets (`supabase secrets set`); locally `.env` | **No.** Only `.env.example` is committed. |
| Signing (Android keystore, `key.properties`, Apple `.p8`/`.p12`) | Your machine / a password manager; CI secrets if CI ever signs | **Never.** |

**Anything compiled into the app is public.** A `--dart-define` value can be read out of an
APK or the web bundle in minutes. So the app holds only keys designed to be public (the
Supabase anon key is safe *because* RLS guards every row). The AI coach's Anthropic key lives
only in the Edge Function. **No secret ever ships in the app.**

## Enforcement (two points, like commit messages)

- **`.githooks/pre-commit`** runs `scripts/check-secrets.mjs --staged` on every commit.
- **CI** runs `npm run check:secrets` over every tracked file, so `--no-verify` can't skip it.

The scanner's main target is the one `.gitignore` can't stop: **session transcripts**
(`.claude-logs/`) are committed verbatim, and a key that scrolled past in a session rides along.
The log hook redacts known shapes before writing; the scanner is the second net.

Agents can't read real env files at all: `.claude/settings.json` denies `Read` on `.env`,
`.env.local`, `.env.*.local`, `env/dev|staging|prod|local.json` and `supabase/functions/.env`.
Ask the person for a value instead of working around the rule.

## If a secret is committed

Rotate it first. Removing it from history is not enough once it has been pushed (the repo is
public).

False positive: put `allowlist secret` in a comment on that line, or add a glob to
`.secretsallow`, and say why in the PR.
