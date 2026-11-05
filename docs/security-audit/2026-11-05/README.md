# Security audit, 5 Nov 2026

Produced with Cloudflare's MIT-licensed
[security-audit skill](https://github.com/cloudflare/security-audit-skill), **quick profile**,
source only (nothing executed), on `main` at `07a1b30`. The files here are the run's own records,
copied unchanged: [REPORT.md](REPORT.md), [FINDINGS-DETAIL.md](FINDINGS-DETAIL.md),
[NEEDS-VALIDATION.md](NEEDS-VALIDATION.md), `findings.json`, `coverage-ledger.json` and
[architecture.md](architecture.md). The per-agent working folder isn't included.

The run reported no *confirmed* findings, because it couldn't execute anything. It left four
source-grounded leads and some hardening notes. Issue 74 (PR `fix/74-security-scale`) checked each
one locally, in a throwaway Postgres 17 container and with unit tests, and fixed it. The full write-up is
[docs/scale-and-security.md](../../scale-and-security.md).

## Leads

| # | Lead (fingerprint) | Fix | Proof |
| --- | --- | --- | --- |
| 1 | Leaderboard XP is client-written (`supabase/migrations/20261104120000_leaderboard.sql:profiles-client-reported-xp-unbounded`) | `fix(supabase): rank the leaderboard on server-verified XP only`: XP grants revoked; `ai_scores` server-only; XP recounted from verified verdicts, at most 100 per mission (migration `20261105120000_verified_leaderboard.sql`) | `supabase/tests/verified_leaderboard.test.sql` (19), `ai_scores_rls.test.sql`, `leaderboard.test.sql`; `schema_drift_test.dart` ("no client may write the board's XP") |
| 2 | Deep link accepts an injected `access_token` session (`apps/mobile:supabase_flutter-detectSessionInUri-implicit-token-deeplink-session-injection`) | `fix(auth): accept only PKCE codes and errors from sign-in links`: `detectSessionInUriPredicate` reads a link only with `code` or `error*` and never with `access_token`/`refresh_token`. A code only exchanges with the PKCE verifier this device stored when it sent the link, which is the "a sign-in is pending" check | `apps/mobile/test/core/backend/auth_callback_test.dart` |
| 3 | Gemini quota per uid, uids free (`supabase/functions/claim_ai_score:per-uid-quota-escapable-via-anonymous-uids`) | `fix(supabase): add a global AI budget and clean first names`: a global daily budget of 3,000 units in the same atomic claim, a voice answer is 3 units for the player and the budget; captcha and the anonymous sign-in limit are owner steps (docs/scale-and-security.md §4) | `supabase/tests/ai_budget_and_names.test.sql` (13) |
| 4 | Body buffered before identity, no byte cap (`supabase/functions/handler:unbounded-body-buffering-before-jwt-validation`) | `fix(supabase): cap score bodies on the stream, check the caller first`: the auth server's check runs before a byte is read; a streaming byte cap (20 KB `score`, 12 MB `score-voice`) answers 413 | `score_test.ts`, `score_voice_test.ts` (chunked body cut at the cap, refused JWT leaves the body unread) |

## Hardening notes

| Note | Status |
| --- | --- |
| `log.dart:45` passes the raw error object | Fixed: `developerError()` redacts it (`test/core/log_test.dart`) |
| No `allowBackup` / `dataExtractionRules` | Fixed: `allowBackup="false"`, `fullBackupContent="false"`, data extraction rules excluding everything (`test/platform/android_manifest_test.dart`) |
| `ai_scores` client-insertable | Fixed with lead 1 |
| `first_name` allows control, zero-width and bidi characters | Fixed: cleaned on the device (`cleanFirstName`) and by a server trigger, existing names cleaned (`clean_first_name_test.dart`, `ai_budget_and_names.test.sql`) |
| Web has no CSP, `frame-ancestors`, Referrer-Policy | Fixed: `web/vercel.json` |
| `release-apk.yml` uses movable action tags | Fixed: pinned to commit SHAs (`scripts/workflows.test.mjs`) |
| `score-voice` compares characters against a byte cap | Fixed with lead 4 (bytes on the stream) |
| Prompt context comes from the client, not looked up from `mission_id` | Listed: the mission id is now allowlisted, but the lines are still the client's. Next step: a content manifest for the functions (docs/scale-and-security.md §1) |
| No fallback after a 429 | Not changed, on purpose: Gemini's limits are per model, so a 429 from one model says nothing about the next, and the chain exists for exactly that (ADR 0006). The global budget bounds what the chain can spend |
| Leaderboard sorts everyone on each call | Measured: about 10 ms at 1,000 players. Listed for tens of thousands |
| `PlayerData.clear` deletes rows without VACUUM | Listed: deleted rows stay in SQLite free pages until reused. Low risk on a phone the player owns |
| `leaderboard_visible` defaults to true | Kept: a product decision (issue 72). Shown with a first name only, and switchable in Settings |
| Streak check should be `week_start between monday-7 and monday` | Mitigated: `week_start` is server-written now, from verdict times, so it can't be in the future |
