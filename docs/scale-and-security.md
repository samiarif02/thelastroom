# Scale and security: 1,000 players, and can anyone cheat?

Issue 74, written 5 Nov 2026. The reviewer asked: *"If 1,000 users use your app, would anything
break? Check every error from every possible scenario, including from the security perspective.
Can anyone fake their progress and pass, or earn extra XP?"*

An independent source audit ran the same day with Cloudflare's security-audit skill. Its records,
and which change fixes each lead, are in
[docs/security-audit/2026-11-05](security-audit/2026-11-05/README.md).

Short answers:

- **Faking XP onto the leaderboard: closed.** Until #74 the board ranked numbers the phone
  reported, and a modified app could also write its own AI verdicts. Now only the server writes
  verdicts, and the board ranks XP the server counts from those verdicts, once per mission. Section 1
  covers how, and what's still open.
- **"Passing" on the device.** Progress on the phone (XP in your league, unlocked floors) is
  offline-first by design (ADR 0005). Someone who edits their own phone's database can unlock
  their own floors. That only cheats themselves: it never reaches the board or anyone else.
- **1,000 players: nothing breaks.** At 300 daily players playing 3 rooms each, every free-tier
  limit has room to spare except two: Gemini's per-minute limits at peak (absorbed by the model
  chain, then the offline score) and email sending (built-in sender). Section 3 has the numbers and
  section 4 says what to change for real scale.

## 1. Anti-cheat: the board counts server-verified XP only

| Before #74 | After #74 |
| --- | --- |
| `profiles.total_xp`, `week_xp`, `week_start`, `streak_weeks` were granted to `authenticated`: the app upserted whatever the device computed | Those grants are revoked. A client writing them gets `42501 permission denied` |
| `ai_scores` had an owner insert policy and insert grants: the `score` functions inserted *as the player*, so any client could insert `overall_score = 100` itself | The insert policy and grants are gone. The functions insert with the service role, under the user id the auth server read from the caller's JWT, never an id from the body |
| Any `mission_id` matching the id pattern could be scored | Only the content's own mission ids (`supabase/functions/score/missions.ts`, kept equal to `packages/content` by a Dart test) |

**How the server counts** (`private.recount_verified_xp`, fired by a trigger on every
`ai_scores` insert, `security definer`, `search_path = ''`, migration
`20261105120000_verified_leaderboard.sql`):

- Per mission, the **best** verified overall score counts **once**, as the engine's room XP for a
  first clear (`packages/engine/lib/src/progression.dart`, `missionXp`):
  `20 + best ÷ 2 (rounded down) + 30`. A mission is worth at most 100 and a replay counts only when
  it beats the best. 21 missions cap a player's board XP at 2,100.
- `week_xp` is the verified XP *gained* this UTC week; `streak_weeks` counts UTC weeks in a row with
  at least one verified score.
- Reason XP and Recall Room XP stay on the phone. They're computed from client-reported picks, so
  the server can't verify them, and the board doesn't count them. The screen says so: "Verified XP ·
  The board counts rooms the recruiter scored online, your best in each room once. Offline rooms
  count in your league, not here."
- Rooms played offline never reach the board, because no server score exists for them. That's the
  honest cost of a board nobody can type their way onto.
- The migration's backfill replaces every previously reported number with the verified one.

**Proved by pgTAP** (`supabase/tests/verified_leaderboard.test.sql`, 19 tests, plus updated
`ai_scores_rls`, `leaderboard`, `voice_answers`): a client can't write an XP column on insert or
update; a client can't insert a verdict; a client can't call the recount; a client's own attempt
row claiming 100 earns 0 board XP; 60 then 40 then 91 on one mission gives 80, 80 then 95; 30
perfect replays give exactly 100; the week and streak follow when verdicts landed; hidden players
stay hidden but see their own verified rank.

**Measured under concurrency** (a throwaway Postgres 17 container, never the shared stack):
60 simultaneous `claim_ai_score()` calls for one player granted exactly 30 and the counter stopped
at 30 (`insert … on conflict do update … where used < 30` is atomic). 21 simultaneous verdicts on
21 missions for one player gave exactly 2,100: an advisory lock per player stops two recounts from
losing an update.

### What a determined cheater can still do (listed, not fixed tonight)

| Gap | Worst case | The fix |
| --- | --- | --- |
| The AI grades the text the app sends. A modified client can send better lines than the content offers for a real mission | Its own best score on each mission: at most 100 per mission, 2,100 in all, the same as a perfect honest player. It still costs one of 30 AI scores a day | Validate every beat line, reason and reply against a content manifest generated from `packages/content`, like `missions.ts` |
| Guest accounts are free, so one person can make many (anonymous sign-in is limited to 30 an hour per IP) | Many board entries, each capped at 2,100 and each needing real AI scores. Their AI use is bounded too: 30 units per id and a global budget of 3,000 units a day (see below) | Turnstile captcha on anonymous sign-in (an owner step: Authentication → Attack Protection), or show only saved (email-linked) accounts on the board |
| `ai_scores` rows written before #74 were client-insertable, and the backfill trusts them | Only the owner's test players existed then | Inspect with `select user_id, mission_id, model, overall_score, created_at from ai_scores where created_at < '2026-11-05' order by overall_score desc;` and delete any that look wrong (the next verdict recounts that player) |

## 2. Security audit

### Database (Supabase Postgres)

| Area | Finding | Status |
| --- | --- | --- |
| RLS | Every public table (`profiles`, `mission_attempts`, `ai_scores`, `ai_score_usage`) has RLS on and owner-only policies; `anon` holds no table privilege (`00_rls_enabled.test.sql`, `check:rls`) | OK |
| Grants | Column-level grants only: a client never writes `user_id`, `created_at`, the reached-at times, usage counters or (since #74) XP and verdicts. Supabase's default `TRUNCATE` grant is revoked | OK; tightened in #74 |
| `ai_scores` writable by clients | Critical: a client could insert its own verdict | **Fixed** (#74) |
| Leaderboard XP client-reported | Critical: anyone could top the board | **Fixed** (#74) |
| Security-definer functions | `claim_ai_score`, `leaderboard`, `recount_verified_xp`, `on_ai_score_inserted`: all `set search_path = ''`, fully qualified names, execute revoked from `public`/`anon` (the private ones from `authenticated` too). The `private` schema is not exposed through the Data API | OK |
| `leaderboard()` | Returns no user id or email; the tag is a 4-digit hash computed on the server; limit clamped to 1-100 | OK |
| Quota | 30 units per player per UTC day (a built answer 1, a voice answer 3), enforced in SQL, atomic under concurrency (measured) | Weighted in #74 |
| Global AI budget | Player ids are free to mint, so a per-player cap alone didn't bound the shared Gemini key. `private.ai_score_budget` caps all players at 3,000 units a day in the same atomic claim; a refused claim gives the player's units back | **Fixed** (#74, audit lead 3) |
| `first_name` | Shown to every player on the board, but allowed control, zero-width and bidi characters | **Fixed**: stripped by a server trigger and on the device; existing names cleaned |
| Storage buckets | None configured | Nothing to secure |
| Mission attempts | Client-reported scores (the engine's) for restore on a new phone. They count for nothing on the board now | OK by design |

### Edge Functions (`score`, `score-voice`)

| Area | Finding | Status |
| --- | --- | --- |
| Auth | The JWT is checked by the auth server (`GET /auth/v1/user`) before a byte of the body is read; a refused token is a 401. The quota is then claimed as the player | **Tightened** (#74, audit lead 4) |
| Attribution | Verdicts are stored for the verified caller's id, never a body field (tested: a `user_id` in the body is ignored) | **Fixed** (#74) |
| Mission ids | Allowlisted per function (choice missions for `score`, voice missions for `score-voice`) | **Fixed** (#74) |
| Payload size | `score` had no cap; `score-voice` checked `content-length` (missing on a chunked body) and then counted characters after buffering. Both now read the body through a streaming byte cap (20 KB `score`, 12 MB `score-voice`) and answer 413 the moment it's passed | **Fixed** (#74, audit lead 4) |
| The fallback chain on 429 | The audit suggested stopping on a 429. Not changed: Gemini's limits are per model, so a 429 from one model says nothing about the next, and a refused call isn't billed. The global budget bounds what the chain can spend | Kept (ADR 0006) |
| Prompt context | The question, lines and reasons come from the app, not looked up from `mission_id` | Listed (section 1) |
| Error messages | Responses are bare codes (`invalid_request`, `daily_limit_reached`, `upstream_error` …). An unexpected exception used to fall through to the runtime's default 500 without CORS headers; it's now a logged `500 internal_error` with CORS | **Fixed** (#74) |
| Logging | One JSON line per call: model, mission, tokens, latency. Never the JWT, the key, the answer text, the audio or the transcript (tested) | OK |
| Secrets | `GEMINI_API_KEY` lives only in the function secrets. `SUPABASE_SERVICE_ROLE_KEY` is injected by the Supabase runtime and never leaves the function | OK |
| CORS | `access-control-allow-origin: *`. Acceptable because the functions take a bearer token, not cookies, so another site can't ride a session | Listed: could be narrowed to the app's origins |

### The app

| Area | Finding | Status |
| --- | --- | --- |
| Keys | Only the Supabase URL and anon key (`Env`), optional; no service key anywhere in `apps/` or `web/` | OK |
| Logging | Every field and message goes through `redact.dart` (tokens, keys, bearer strings, emails, answers, drafts) | OK |
| Email links | "Save your progress" uses Supabase's email-change confirmation; "Sign in on another device" uses `signInWithOtp(shouldCreateUser: false)` with PKCE. Another app claiming the `thelastroom://auth-callback` scheme could catch the link but can't use it: the PKCE verifier never leaves this device | OK |
| Deep-link session injection | supabase_flutter read any `thelastroom://auth-callback` link, and gotrue installs a session handed over as `#access_token=…&refresh_token=…` without PKCE. A crafted link could have signed the player into an attacker's account and uploaded their progress there. Now `detectSessionInUriPredicate` reads a link only with `code` or `error*` and never with a token; a code only exchanges with the verifier this device stored when it sent the link | **Fixed** (#74, audit lead 2) |
| Logging to DevTools | `developerSink` handed the raw error object to `dart:developer` | **Fixed**: redacted like the JSON line |
| Android backup | No `allowBackup` setting, so the session tokens and the local database went into the user's cloud backup and device transfers | **Fixed**: `allowBackup="false"`, `fullBackupContent="false"`, data extraction rules excluding everything |
| Release workflow | `release-apk.yml` (`contents: write`) used movable action tags | **Fixed**: pinned to commit SHAs, with a test |
| `/verified` page | Strips any token or error from the URL before paint (`history.replaceState`); now also `Referrer-Policy: no-referrer` and `Cache-Control: no-store` | **Tightened** (#74) |
| Sign-out | Backs up everything first (blocked if anything can't upload), ends the session, then wipes the device's player data and signs in a fresh guest | OK |
| Old builds | An app from before #74 still sends XP in its leaderboard upsert, now refused (42501). That upsert is its own outbox row, retried with backoff up to every 30 minutes; the profile and attempts sync untouched | Listed: install the new build |

### The landing site (Vercel, static)

`web/vercel.json` adds, on every path:

- `Content-Security-Policy`: `default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; manifest-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests`
- `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (camera, microphone,
  geolocation, payment, usb, topics all off), `Strict-Transport-Security: max-age=63072000; includeSubDomains`,
  `Cross-Origin-Opener-Policy: same-origin`.

Checked by serving `web/out` locally with these headers and rendering the home page, `/verified`
and `/privacy` in headless Chrome: the fonts, styles and images all loaded. `'unsafe-inline'` is
needed because a static Next.js export inlines its bootstrap scripts, and nonces need a server.
The site has no forms, cookies, third-party scripts or user input, so the risk that leaves is
small.

`npm audit` in `web/`: 8 moderate, all in development-only lint tooling (`minimatch` via
`typescript-eslint` / `eslint-config-next`). None ships in the static output. Flutter packages:
`flutter pub outdated` shows only minor updates. An advisory scan (`osv-scanner --lockfile
pubspec.lock`) was not run tonight.

### Cloudflare URL Scanner (for the owner)

The scanner needs a person to submit the URL, so an agent can't run it.

1. After this PR is merged and Vercel has redeployed, open <https://radar.cloudflare.com/scan>.
2. Paste `https://thelastroom-ten.vercel.app`, leave the visibility as **Unlisted** if you don't
   want the report public, and press **Scan**. It takes about a minute.
3. Check the report's tabs:
   - **Security**: no malicious verdict, no phishing category.
   - **Headers** (HTTP response): `content-security-policy`, `strict-transport-security`,
     `x-frame-options: DENY`, `x-content-type-options: nosniff`, `referrer-policy`,
     `permissions-policy` and `cross-origin-opener-policy` should all be listed.
   - **Network**: every request goes to `thelastroom-ten.vercel.app` itself. No third-party
     domains, no cookies.
   - **Technology**: Next.js and Vercel, nothing else.
4. A good result is a clean security verdict with all seven headers present. Optionally confirm
   the header grade at <https://securityheaders.com/?q=thelastroom-ten.vercel.app>: expect an A
   (an A+ would need the CSP without `'unsafe-inline'`, which the static export can't do).

## 3. 1,000 players: every limit, with numbers

Assumptions: 1,000 players a month, 300 a day, 3 rooms each, so 900 AI scores a day (about 27,000
a month). The busiest hour carries 20% of a day, so 180 scores an hour, 3 a minute on average with
bursts above that. Free-tier figures are the ones published on the pages linked; check them again
before relying on them, because providers change them.

| Limit (free tier) | What 300 a day uses | Headroom | What happens at the limit | What the player sees |
| --- | --- | --- | --- | --- |
| Supabase database, 500 MB ([pricing](https://supabase.com/pricing)) | Measured: 42,000 verdicts = 12 MB with indexes (about 300 B each). Voice transcripts add up to about 6 KB per voice row. Attempts are about 400 B. About 1-3 MB a day | More than a year | The project goes read-only | Sync and AI scoring fail; the app keeps working offline and retries |
| Monthly active users, 50,000 | 1,000 | 50x | New sign-ins refused | The app runs offline as a guest-less device (ADR 0005) |
| Edge Function invocations, 500,000 a month ([limits](https://supabase.com/docs/guides/functions/limits)) | About 27,000 | 18x | Calls refused | The offline engine score, as with no network |
| Edge Function wall clock, 150 s; CPU 2 s per request | Wall clock is at most ~30 s (the model chain's timeouts add up to under 30 s); CPU is JSON parsing plus base64 for voice | Large | The call is killed | The offline score |
| Egress, 5 GB a month | A board read is ~51 rows, about 6 KB; a sync batch a few KB. About 50 KB per player per day, so about 0.5 GB a month | 10x | Overage on a paid plan; restrictions on free | Nothing until then |
| Database connections (Nano: 60 direct, 200 pooled) | PostgREST and the functions share a small pool; players never hold connections | Large | Queued requests, slower answers | Slower board loads; timeouts fall back to the cached board |
| Free project pause after 7 days without activity | A real audience keeps it awake | n/a | The project pauses until restored in the dashboard | The board says it can't be reached; every room still plays and scores offline |
| Anonymous sign-ins, 30 an hour per IP ([rate limits](https://supabase.com/docs/guides/auth/rate-limits)) | Fine at home. A classroom or event behind one NAT is the risk: the 31st new player in an hour is refused | Low behind a shared IP | 429 | The guest sign-in retries in the background (2 s doubling to 5 min); the player plays offline meanwhile. Raise the limit in the dashboard before an event |
| Auth email: built-in sender, about 2 an hour, and only to the project's team addresses ([SMTP](https://supabase.com/docs/guides/auth/auth-smtp)) | "Save your progress" and "Sign in on another device" | **None for the public** | 429 `over_email_send_rate_limit` | The card's rate-limited message; progress stays on the phone |
| Auth email with Gmail SMTP: about 500 recipients a day ([Gmail limits](https://support.google.com/mail/answer/22839)); Supabase's own custom-SMTP limit is 30 an hour by default (adjustable) | Maybe 5-10% of 300 a day save progress: 15-30 emails | 15x a day, but 30 an hour at a spike | Gmail blocks sending for up to 24 h; Supabase answers 429 | The rate-limited state; the player can try later |
| Our AI quota, 30 units per player per day (a voice answer is 3) | 3-9 a day | 3x or more | `429 daily_limit_reached` | The offline engine score, with the usual debrief |
| Our global AI budget, 3,000 units a day | About 1,850 (900 scores, 11 of 21 rooms are voice at 3 units) | 1.6x | `429 daily_limit_reached` for everyone until 00:00 UTC | The offline engine score. Raise `global_daily_units` in a migration when the key is on a paid tier |
| Gemini free tier, per model, per project ([rate limits](https://ai.google.dev/gemini-api/docs/rate-limits)): Flash-Lite tiers have been about 15 requests a minute and 1,000 a day; Flash about 10 a minute and 250 a day (numbers for the 3.x models: check the page) | 900 a day; bursts of more than 15 a minute at peak | Per day: the three-model chain spreads the load (about 2,250 a day across them at those figures). Per minute: tight at peak | 429 from one model | The next model in the chain answers (3.5 Flash-Lite, 3.6 Flash, 3.1 Flash-Lite). If all three are busy, the offline score at 8 s, and a late AI verdict up to 30 s is offered as a banner. The app never breaks |
| PostgREST `max_rows`, 1,000 | The board returns at most 101 rows (top 100 and the caller); a restore reads one player's own attempts | Large | Results cut at 1,000 | Only matters for a player with more than 1,000 attempts restoring a new phone |

### The app under errors (checked in code)

- **The outbox**: batches of 50, one flush at a time, exponential backoff from 5 s doubling to a
  30-minute cap per row, triggered on change, on resume and by the retry timer. A server outage
  makes each device try about 7 times in the first hour, then twice an hour. 1,000 devices at
  the cap send about 33 small requests a minute. No jitter, so devices that failed together retry
  together. That's harmless at this size; adding jitter is a one-line change for later.
- **Guest sign-in**: 15 s timeout, backoff from 2 s to 5 minutes, never awaited by the UI.
- **AI scoring**: one call per finished room, never per answer. 8 s until the offline score shows,
  30 s total.
- **The board**: one call per open or tab switch, cached for offline ("as of Tue 14:05").

### The leaderboard query at 1,000 players

Seeded in a throwaway Postgres 17 (`supabase/postgres:17.11.0.006`): 1,000 players and 42,000
verdicts (14 days of 3 a day each), all inserted through the real trigger.

- `public.leaderboard('all', 50)`: **~10 ms** (after autovacuum; ~58 ms with the update bloat of
  42,000 recounts not yet vacuumed). Plan: a sequential scan of `profiles` (1,000 rows), a sort and
  a window `row_number()`. A full scan is correct here: the caller's own rank needs every player
  ahead of them. The existing `(total_xp desc)` and `(week_start, week_xp desc)` indexes don't
  help with that.
- The recount trigger per verdict: **~8 ms** (an index scan on `(user_id, mission_id)` over that
  player's rows).
- Where this stops being fine: at roughly 50,000+ players the full sort costs tens of
  milliseconds per call. Then keep a rank table refreshed by the same trigger, or cache the top
  100 for a minute.

### Load test

`scripts/load-test.mjs` (Node 22, no dependencies) signs in a few guests and reads the board
concurrently, with an optional `--score` that spends one AI score each. It uses the public anon
key only, caps itself at 25 guests and 200 rounds, and is never run by CI or by an agent:

```bash
SUPABASE_URL=https://eeanpdlqxmatuidrhoht.supabase.co SUPABASE_ANON_KEY=<anon key> \
  node scripts/load-test.mjs --players 10 --rounds 20
```

It prints the status codes and p50 / p95 / max per call. Keep `--players` small: each guest is an
anonymous sign-in, and those are limited to 30 an hour per IP.

## 4. What to change for real scale

| When | Change | Why |
| --- | --- | --- |
| Before any public launch | Own SMTP on a sending domain (Resend, Postmark, SES) and raise Supabase's email rate limit | The built-in sender only reaches the team; Gmail caps at about 500 a day and can lock the account |
| Before an event or classroom | Raise the anonymous sign-ins per IP limit; add Turnstile captcha (Authentication → Attack Protection) | 30 an hour per IP; captcha also stops mass guest accounts using up the AI budget and filling the board |
| Beyond ~1,000 AI scores a day, or for steady latency | Paid Gemini tier (about $0.0007 a built-answer score: $2.20 a day at 1,000 daily players × 3, `docs/ai-reliability-and-cost.md`) | Free per-minute limits are the first wall; paid tiers lift them to hundreds or thousands of requests a minute |
| When the backend must never pause | Supabase Pro ($25 a month): 8 GB database, 100,000 MAU, 250 GB egress, 2M function calls, no pausing, daily backups | The free project pauses after a week idle and has no backups |
| Tens of thousands of players | A rank table (or cached top 100) for the board; jitter in the outbox backoff | The full-sort board query and synchronized retries |
| For a stricter board | Validate the lines in a scoring request against a content manifest; board for linked accounts only | Closes the two gaps in section 1 |
