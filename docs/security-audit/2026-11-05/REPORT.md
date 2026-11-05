# Security audit: The Last Room

Cloudflare `security-audit` skill, full audit mode, **`quick` profile**. Reviewed `origin/main`
at `07a1b30` (a clean, read-only snapshot). Records: `findings.json` (4), `coverage-ledger.json`
(13 units), `NEEDS-VALIDATION.md`, `architecture.md`.

## 1. Run scope and limits
- Profile: `quick`. Budget: 12 agent invocations, all used (4 reconnaissance, 3 hunters, 1 final
  critic, 4 verifiers).
- **Nothing executed.** The sandbox couldn't be enforced on this Mac, so every check is a reading of
  the source. No deployed endpoint, hosted Supabase project, Gemini quota or real env file was
  touched.
- No prior run, so there's no carried evidence.
- Two units are deferred by the final critic (`quick_profile_final_critic`): GoTrue `/auth/v1` for
  callers with no session (password signup, email-existence oracles, the OTP brute-force bound,
  email-send abuse, loopback redirects), and unbounded jsonb size and row counts on the tables
  guests can insert into.
- **This is partial coverage.** It doesn't claim the rest is clean.

## 2. Posture summary
- **Strong on isolation:** owner-only RLS on every table, revokes from `anon`, column-narrowed
  grants, server-set identity and timestamps, and `SECURITY DEFINER` functions with
  `search_path=''` and no identity parameters. **No path was found to read or write another
  player's rows.**
- **Weak where it trusts the client, or a per-uid count while uids are free:** leaderboard XP,
  the AI quota, and the session that the email-link deep link accepts.

## 3. Confirmed findings
None, because no bounded local result could be observed (see §1). There's no severity table.

## 4. Needs validation (no severity)
| # | Lead | Trace | Blocker | Local next step |
|---|---|---|---|---|
| 1 | **Leaderboard XP is client-written.** A guest can write any XP and streak and take #1. | `config.toml:188` → `leaderboard.sql:38-41` grants → `:31-34` checks only `>=0` → `:116/:134/:148` rank as stored | pgTAP not runnable; whether it's applied on hosted is a deployment fact | A pgTAP case where one dummy uid upserts the max and another sees it at rank 1 |
| 2 | **The deep link accepts an injected `access_token` session** and merges the victim's progress into the attacker's account | `AndroidManifest.xml:50`, `Info.plist:84` → `supabase_backend.dart:271` (`detectSessionInUri` on) → gotrue 2.27.3 `getSessionFromUrl` (PKCE only enforced when `access_token` is absent) → `:294-307` → `account_merge.dart:61/89` → `sync_worker.dart:136` | No emulator or app execution allowed | `adb shell am start` with a dummy-token link on a local stack, with `?code=` as the control |
| 3 | **The Gemini quota is per uid, and uids are free**, so the shared free-tier key can be exhausted | `config.toml:188/213` → `score/handler.ts:72` → `ai_scores.sql:88,95` → `gemini.ts:153` (3 calls a claim, including on 429) → `gemini_voice.ts:79` (8 MB for one unit) | The hosted sign-in limit, captcha and Gemini tier are not in source | A local function test with many dummy uids |
| 4 | **The body is buffered before identity is checked**, with no byte cap | `score/handler.ts:58-63`; `score-voice/handler.ts:65,73,74` (counts chars, not bytes) | deno absent; the gateway and isolate limits are platform facts | A Deno test posting an oversized chunked body |

## 5. Fixes for the leads (smallest effective)
1. Revoke the client grants on `total_xp`, `week_xp`, `week_start` and `streak_weeks`; derive them server-side, bounded by the engine's maximum XP per attempt; tighten the streak check to `week_start between monday-7 and monday`.
2. `detectSessionInUri: false` plus an app-owned handler that accepts only `?code=` (PKCE) and `error*`; act on a link sign-in only while one is pending.
3. A global daily Gemini budget in the same atomic claim, voice weighted higher, no fallback after a 429, and captcha / a lower anonymous sign-in rate (owner, dashboard).
4. A streaming byte cap before parsing (413), with the JWT validated before the body is read.

## 6. Hardening notes (not findings)
- `log.dart:45` passes the raw error object; redact it before Sentry is wired.
- No `allowBackup`/`dataExtractionRules`, so the session and the local db go into the user's own cloud backup.
- `PlayerData.clear` deletes rows without VACUUM.
- **`ai_scores` is client-insertable** (`ai_scores.sql:52-55`). Self-only today, but any recount from it would inherit forgeable scores.
- Prompt context comes from the client instead of being looked up from `mission_id`.
- `score-voice` compares characters against a byte cap.
- `leaderboard_visible` defaults to true.
- `first_name` allows control, zero-width and bidi characters, which show to every player.
- The leaderboard sorts everyone on each call; fine at about 1,000 users, but use an indexed top-N later.
- The web has no CSP, `frame-ancestors` or Referrer-Policy (hardening only; there's no state-changing action).
- `release-apk.yml` (`contents: write`) uses movable action tags; pin them to SHAs.
- **Positive patterns:**
  - an atomic `claim_ai_score`;
  - the functions make database calls as the caller (no service role);
  - the Gemini key goes only in a header and is never logged;
  - model output is clamped and capped;
  - PKCE binds `?code=`;
  - sign-out wipes every player table and key;
  - analytics values are a sealed type;
  - CI runs on `pull_request` with read-only contents;
  - `/verified` writes no URL value into the page.

## 7. Coverage
8 units covered, 3 candidate units (the 4 leads), 0 blocked, and 2 deferred (above). Excluded
companions: memory safety (no native code) and protocols/brokers (none). The reviewer's questions:
cross-player read/write (no path found); secrets (none committed); web (headers only); about 1,000
users (partly covered, by leads 3 and 4).
