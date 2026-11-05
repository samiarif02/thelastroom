# Architecture summary: The Last Room (07a1b30, quick profile)

## 1. Product, principals, protected resources
A Flutter interview-practice game (Android/iOS/web build) that is offline-first; the backend is optional (README.md, ADR 0005). The operator runs one hosted Supabase project and holds the Gemini key as an Edge Function secret.

Principals:
- `anon` role (no session): only GoTrue endpoints. All table and RPC grants are revoked from anon.
- **Anonymous guest**: `authenticated` role, minted by anyone via `signInAnonymously` (supabase/config.toml:188, 30 per hour per IP at :213, no captcha). Every grant to `authenticated` is therefore open to the public.
- **Linked email account**: the same `authenticated` role. No policy distinguishes guests from linked accounts.
- **Edge Functions** `score` and `score-voice`: act as the caller, forwarding the caller's JWT plus the anon key to PostgREST. No service role is used in source. They hold `GEMINI_API_KEY`.
- **Gemini**: receives player-controlled answer text and audio. Its output becomes the stored score.
- **CI**: `ci.yml` (pull_request, contents: read) and `release-apk.yml` (tag or dispatch, contents: write).

Protected resources:
- each player's rows: `profiles` (first_name, interview_date, etc.), `mission_attempts`, `ai_scores`, `voice_answers` data, `ai_score_usage`;
- leaderboard integrity, which is shared by all players;
- the operator's Gemini spend and quota;
- account identity (the email link and the account merge);
- device-local data after sign-out.

Comparable baseline: standard Supabase starter patterns, namely owner-only RLS and SECURITY DEFINER RPCs with `search_path=''`. Client-reported leaderboard scores are a known weak pattern in casual games. Here the migration says so itself (20261104120000_leaderboard.sql:23-24).

## 2. Stack and execution limits
Stack:
- Dart/Flutter (Riverpod, go_router, supabase_flutter, drift);
- pure-Dart packages under packages/;
- Postgres migrations with pgTAP tests (supabase/tests);
- Deno TypeScript Edge Functions with injected-deps unit tests;
- a Next.js 16 static export (`output: 'export'`) on Vercel, in web/.

Execution limits:
- There is no OS-enforced sandbox on this macOS host. sandbox-exec cannot cap memory, processes or disk.
- `deno`, `psql` and `pg_prove` are absent. The Supabase images would need pulling.
- No trusted promotion tool exists.
- So **no target code is executed**. Decisive behavioural checks become needs_validation.

## 3. Entry surfaces and key paths
- **PostgREST writes to `profiles`.** Column grants (20261030170650:30-38 and 20261104120000_leaderboard.sql:38-41) let the owner write `total_xp`, `week_xp`, `week_start` and `streak_weeks`. The only bounds are CHECKs (`>= 0`, Monday). These values feed the SECURITY DEFINER `public.leaderboard` (leaderboard.sql:82-154), which ranks every visible player and returns `first_name` (shown_name), a 4-digit tag, the XP figures and the streak to every authenticated caller.
- **PostgREST inserts into `ai_scores` and `mission_attempts`.** Column insert grants are given to `authenticated` (20261031130000_ai_scores.sql:52-55, 20261102120000_voice_answers.sql, 20261030170650:40-46). RLS WITH CHECK requires `auth.uid() = user_id`.
- **RPC `claim_ai_score()`** (ai_scores.sql:81-106): a SECURITY DEFINER upsert counter with 30 per UTC day per uid.
- **Edge Function `score`** (supabase/functions/score/index.ts, handler.ts):
  1. requires a Bearer token to be present;
  2. parses the input (scoring.ts);
  3. claims the quota as the caller (a 401/403 maps to Unauthorized);
  4. calls Gemini with a prompt built from the answer text (scoring.ts systemInstruction);
  5. parses the model JSON into scores;
  6. inserts into ai_scores as the caller.

  CORS is `*`. `verify_jwt` is not set in config.toml, so the platform default applies.
- **Edge Function `score-voice`**: the same pattern, with audio plus transcript and `MAX_BODY_BYTES = 12_000_000` (voice.ts:71, handler.ts:65-74).
- **Mobile auth** (apps/mobile/lib/core/backend/supabase_backend.dart, guest_sign_in.dart):
  - a guest is created with anonymous sign-in;
  - "Save your progress" calls `updateUser(email)` with a redirect to `/verified`, and email confirmations are on;
  - sign-in on another device uses `signInWithOtp(shouldCreateUser:false)` with PKCE and the custom scheme `thelastroom://auth-callback` (AndroidManifest.xml:43-51, Info.plist:72-85);
  - the account merge is in core/sync/account_merge.dart and save_progress_controller.dart:463-485;
  - sign-out (save_progress_controller.dart:391-445) clears local data and continues if `signOut` fails.
- **Web `/verified`** (web/src/app/verified/page.tsx:25): an inline script reads the hash and query only to toggle the expired state, then calls `history.replaceState`. No headers are defined in next.config.ts. There is no vercel.json.
- **Logging and analytics**: apps/mobile/lib/core/logging (redaction) and core/analytics (PostHog/Sentry from dart-defines). Edge Functions log JSON via console.log.
- **CI**: release-apk.yml has `contents: write` and takes a dispatch input `TAG` in env.

## 4. Trust boundaries and strongest controls
| Boundary | Strongest source-visible control | Notes |
| --- | --- | --- |
| Player to other players' rows | Owner-only RLS with `(select auth.uid()) = user_id`, explicit revokes from anon, column grants | |
| Player to leaderboard integrity | CHECK `>= 0` only | No server recount, as the migration admits |
| Player to Gemini spend | Per-uid daily quota in SQL | Guests are free per IP, so per-person cost is bounded only by the anon sign-in rate limit, which is a hosted setting |
| Caller identity at the Edge Functions | PostgREST JWT validation on the first DB call | The function's own check is presence-only, and `verify_jwt` is a deployment fact |
| Email link and deep link | PKCE plus email confirmation | The custom scheme is not exclusive. The hosted redirect allowlist is not visible in source |
| Web pages | Static export | No CSP or framing headers are visible in source. The deployed headers are a Vercel fact |

## 5. Starting paths
- supabase/migrations/*.sql
- supabase/tests/*.test.sql
- supabase/functions/{score,score-voice}/*.ts
- supabase/config.toml
- apps/mobile/lib/core/{backend,sync,logging,analytics,db,env,leaderboard}
- apps/mobile/lib/features/{settings/account,debrief,leaderboard}
- apps/mobile/android/app/src/main/AndroidManifest.xml
- apps/mobile/ios/Runner/Info.plist
- web/src/app/verified/page.tsx
- web/next.config.ts
- .github/workflows/*.yml
- scripts/check-*.mjs

## 6. Prior coverage
No prior run exists (~/security-audit-skill/thelastroom/ contained only an empty run-1). Nothing is carried over or excluded.

## 7. Companion selection
| Companion | Boundary that requires it |
| --- | --- |
| DATA-ISOLATION-AND-LIFECYCLE | owner-only RLS, the leaderboard as a cross-player reader, logs and analytics |
| WEB-PROTOCOL-AND-AUTH | JWT handling in the Edge Functions, email linking and account merge |
| CLOUD-AND-DEPLOYMENT | Edge runtime `verify_jwt`, the function secret |
| AI-AND-LLM | answer text in the Gemini prompt, model output that becomes scores |
| RESOURCE-EXHAUSTION-AND-AVAILABILITY | Gemini quota and cost, the 12 MB voice body, leaderboard query cost |
| CLIENT-SIDE | the /verified inline script, missing headers |
| DESKTOP-MOBILE-AND-LOCAL-IPC | the custom-scheme deep link, sign-out clearing |
| SUPPLY-CHAIN-AND-RELEASE | release-apk.yml write token, dependency pinning |

Excluded: MEMORY-SAFETY-AND-BINARY (no native code) and PROTOCOLS-RPC-AND-MESSAGING (no broker or custom protocol).
