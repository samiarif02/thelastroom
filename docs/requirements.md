# The Last Room: requirements (v1)

Derived from `docs/product-brief.md` (the source of design intent). This file is the testable
version: each requirement has an id that specs, PRs and tests can cite. Per-feature specs
(`docs/<feature>-requirements.md` + `docs/<feature>-plan.md`) refine these before code.

**Milestones.** Each requirement is tagged with the milestone it lands in, e.g. **[10]**: the
brief number in `docs/v1-plan.md`. Requirements in the first playable slice (Mission 1 offline,
milestone 10) carry acceptance criteria: a PR that claims one shows each bullet holds, by a test
where it can and by a screenshot or recording where it's visual.

**Scope:** Chapter 1 (Missions 1–7) complete and polished; Chapters 2–3 visible, locked and
teased. **Platforms:** Android, iOS, and a Flutter web build run locally (nothing is
hosted; ADR 0005).

## Decisions needed (the owner's call)

| # | Decision | Options | Recommendation | Source |
| --- | --- | --- | --- | --- |
| D1 | **Decided (owner, 2026-10-29): (b) waitlist**, as a flag on the player's profile (`chapter_2_waitlist_at` on `profiles`), not a separate email form | (a) designed Pro paywall with RevenueCat in sandbox, (b) "Chapter 2 is coming, notify me" waitlist, (c) just the teaser | See "D1: the argument" below | Brief §7 |
| D2 | Interviewer portrait art. **Decided (owner, 2026-10-30): rim-lit silhouettes drawn in code for v1**, with a code-driven idle; painterly portraits are a stretch goal | commission, draw in Rive (animated idle), or AI-generated images you have rights to | Decide in the design session; credit it in the README | Kit README §7 |
| D3 | **Decided (owner, 2026-10-29): no hosted web demo.** Reviewers clone and run; the owner records a video. Web build is a CI compile check (ADR 0005) | GitHub Pages, Firebase Hosting, Vercel/Netlify static, Cloudflare Pages | [ADR 0005](decisions/0005-zero-setup-offline-backend-optional.md); `docs/rules/deployment.md` | Brief §10, kit README §5 |
| D4 | Display serif and body sans. **Decided (owner, 2026-10-30): Cormorant Garamond + Manrope** (direction C, The Boardroom) | any OFL-licensed pair, bundled | Decide in the design session (DESIGN.md) | Brief §9 |
| D5 | Sound design in v1. **Decided (owner, 2026-10-30): sound ships in v1**, on by default but quiet (effects 60%, ambience 35%), with a master toggle and two volumes, licensed sounds only (brief 09, FR-17) | none, or subtle licensed UI sounds (off by default) | Brief 09; the spec is `docs/sound-design.md` (lands with brief 09) | Brief §9 |

### D1: the argument

**Agree with the owner's lean, (b), with one change: the waitlist is a flag on the profile, not a
new email form.**

- **Why not (a), the paywall.** RevenueCat in sandbox means store products and sandbox testers
  on two platforms plus entitlement checks: about a day out of four build days, for a purchase
  nobody can make (reviewers run it from a clone, often on the web, where there's no store at all). The design
  of a paywall can be shown as a mock in `docs/SUBMISSION.md` for a fraction of that.
- **Why not (c), just the teaser.** Chapter 1 ends on a cliffhanger (FR-30); a teaser with no
  action wastes the moment the player most wants more, and measures nothing.
- **Why (b).** It's honest (Chapter 2 really isn't built), it costs a button and a column, and
  `waitlist_joined` ÷ `chapter_completed` is a real demand signal: the business question a paywall
  would answer, asked without charging anyone.
- **The change.** "Notify me" needs a way to reach the player. Rather than collect emails in a
  new form (new PII, a new table, a new consent flow), joining sets `chapter_2_waitlist_at` on
  the player's own `profiles` row (milestone 05's migration, owner-only RLS). A guest who taps it
  is offered "Save your progress" first (FR-3), because a guest has no address to notify; that
  turns the cliffhanger into an account-link moment too. The confirmation copy says what we'll
  do ("We'll tell you in the app, and by email if you saved with email") and nothing more.
- **Acceptance:** Given a linked player on the Chapter 2 teaser, when they tap "Notify me", then
  their profile records the time, `waitlist_joined` fires once, and the button shows "You're on
  the list". Given a guest, the same tap opens "Save your progress" first.

## Functional requirements

### Core flow (brief §7)

- **FR-1** **[10]** Splash → 3-screen intro (the hook) → Mission 1 as a guest, with no sign-up
  wall.
  - Given a first launch with no network, when the splash ends, then the intro shows and
    Mission 1 can be played to its debrief without any sign-in, form or permission prompt.
  - The intro can be skipped from its first screen; `intro_completed` fires with `skipped`.
  - On the web, the first frame is the branded loader, and the intro's first screen is
    interactive (NFR-3).
  - A second launch skips the intro and goes to Mission 1 (home arrives in 13).
- **FR-2** **[05, 08]** First launch signs in anonymously (Supabase) and gets a real user id; offline, the
  game still starts and syncs the guest later.
- **FR-3** **[08]** After Mission 1: "Save your progress" offers linking an email address (Google sign-in is v2);
  the linked account keeps all progress.
- **FR-4** **[08]** Short onboarding after Mission 1: target role (v1: general entry-level/product),
  nerves level 1–5 (sets calm mode), optional interview date.
- **FR-5** **[13]** Missions 2–7 → Chapter 1 report → Chapter 2 teaser → D1's outcome.

### The mission loop (brief §3)

- **FR-10** **[10]** Scene: interviewer portrait (idle animation, spotlight), 1–3 setup lines,
  then the question, as typewriter subtitles with the speaker's name (tap to complete).
  - Each line types out with the speaker's name in small caps; a tap completes the line, a
    second tap advances. `mission_started` fires when the first line starts.
  - The content validator rejects a mission with fewer than 1 or more than 3 setup lines, or a
    speaker that isn't an interviewer (`validateContent`, tested).
  - Under reduced motion, lines appear whole and the camera cuts become cross-fades.
  - A screen reader reads each line once, whole, with the speaker's name.
- **FR-11** **[10]** Draft first (optional): the player types a first line before seeing options.
  Stored locally; feeds "then vs. now"; graded by the coach only when online.
  - The draft step offers "Skip" as clearly as "Continue"; both fire `draft_completed`
    (`skipped`), and neither reveals the options before the step is left.
  - The draft is written to the local database before the options appear, survives an app
    restart, and never appears in a log, an event or a crash report (test on the log redaction
    and the event type).
  - Offline, nothing about the draft waits on the network; coach grading is milestone 12.
- **FR-12** **[04, 10]** Build the answer in three beats (Open → Evidence → Land), each offering
  3–4 plausible options. Distractors are realistic mistakes, never jokes.
  - The validator rejects a mission whose beats aren't exactly open, evidence, land in order, or
    a beat with fewer than 3 or more than 4 options (tested).
  - Options are shown in a fixed order per mission (no shuffle), so an attempt can be replayed.
  - Each option is a 44 pt target that survives 2x text without truncation (widget test).
  - "Never jokes" is a content review rule: the 04 PR lists every distractor and its flag.
- **FR-13** **[10]** A soft 60-second timer per answer, shown as the light dimming (numeric only
  under 10 s), on missions with `Mission.timed`. Calm mode turns it off.
  - The light dims continuously over 60 s; a number appears only for the last 10 s.
  - When it runs out, the player is never forced or penalised on score: the interviewer reacts
    (an expression and a line), trust dips, and the beat stays open. `answer_timer_expired`
    fires with `mission_id` and `beat`.
  - With calm mode on, no timer is drawn and the event never fires.
  - **Mission 1 is untimed (owner confirmed, 2026-10-29)**: its content sets `timed: false`, and
    the validator rejects a timed baseline. The baseline should measure the answer, not reading
    speed, and calm mode is only offered after Mission 1 (FR-4). See `docs/v1-plan.md`, "Where the brief is wrong or risky".
- **FR-14** **[04, 10]** Follow-up: the interviewer reacts to the weakest part of the answer
  (vague → "What did *you* specifically do?", blame → "What was your part in it?"); the reply is
  scored for adaptability.
  - `selectFollowUp` returns the follow-up triggered by a flag on the weakest pick, then the next
    weakest, then the mission's default; ties go to the earliest beat (engine unit tests,
    including "no flags at all" and "two picks equally weak").
  - The validator rejects a mission without exactly one default follow-up, or with two
    follow-ups for the same flag.
  - `follow_up_answered` fires with `mission_id` and `follow_up_id` when a reply is picked.
- **FR-15** **[10]** Debrief as a candidate dossier: four dimension scores, the trust meter,
  **one** concrete lesson, the line that cost most marked in red pen. Optional "Say it your way"
  free text, graded by the coach when online.
  - The dossier shows exactly four dimension scores (0–100) and the total, all from
    `scoreAttempt`, and they match the engine's output for the same picks (widget test).
  - Exactly one lesson is shown: the lesson of the costliest line that has one
    (`MissionScore.optionIdsByCost`).
  - The costliest line is quoted and marked in red pen.
  - `mission_completed` fires when the dossier appears; the first one per player also fires
    `user_activated`, and Mission 1's first also fires `baseline_recorded`.
  - "Say it your way" is milestone 12; until then the dossier has no dead button for it.
- **FR-16** **[10, 13]** Progress: XP, any skill unlocked, a Recall Room card for each lesson
  missed.
  - [21] Every mistake becomes a card: each weak beat line gives the card of the misconception
    that tempted it ("You fell for: …", `Reason.tempts`), and a weak follow-up reply gives its
    lesson's card. Cards are built from the stored attempts when the Recall Room or the tower
    loads, each attempt once, and kept on the device. A new card goes in box one **due the same
    day**, because a first-time player must find something in the room right after Mission 1;
    after that, Leitner at 1, 3 and 7 days. Making the same mistake again puts its card back in
    box one.
  - [21] A round is up to 5 cards, about a minute. The player picks the principle that beats
    the misconception (or answers the lesson's recall check) with one tap, timed like a mission
    beat: right after thinking promotes the card; **right but guessed (under 1.5 s) leaves it in
    its box, due tomorrow**; wrong sends it back to box one, due tomorrow. A streak and progress
    ring sits at the top.
  - [10] Skills come from `newlyUnlockedSkills`; a hinted attempt unlocks none (engine test).
  - [13] XP and the Recall Room screen.
- **FR-17** **[09]** Sound design: typing ticks, named cues and per-chapter ambience, under the
  scene and never in the way of it (D5; spec in `docs/sound-design.md`).
  - Every sound is licensed for this use, and the README credits each one.
  - Settings has a master toggle and two volumes: effects (default 60%) and ambience
    (default 35%). Sound is on by default.
  - If audio can't start (no device, a browser that blocks autoplay, an engine error), the game
    plays on silently: no error shown, nothing blocked, one `warn` log.
  - Subtitle lines type with a tick voice chosen per interviewer.

### Scoring (brief §4)

- **FR-20** **[04]** Deterministic and offline: each option scores 0–3 per dimension; each
  dimension is scaled to 0–100 and rounded; the total is the four rounded dimension scores,
  weighted, rounded half up. Weights: relevance 25%, specificity 30%, structure 25%,
  adaptability 20%.
  - `scoreAttempt` is a pure function in `packages/engine` (no Flutter, I/O or clock;
    `check:standards` engine-pure-dart). The same input gives the same output (tested).
  - All 3s score 100; all 0s score 0; a worked example per dimension is a unit test, with the
    arithmetic in its comment.
  - Relevance and specificity: the mean over the three beats and the follow-up reply.
    Adaptability: the follow-up reply only. Each scaled to 0–100 and rounded half up; the
    total is the four rounded dimension scores, weighted, rounded half up, so it can be checked
    by hand from the four numbers the dossier shows.
- **FR-21** **[04]** Flags (`vague`, `we_not_i`, `blame`, `rambling`, `generic`, `off_question`,
  `memorized`) lower the relevant dimension and drive the follow-up.
  - Flags are the closed `Flag` enum; an unknown flag doesn't compile.
  - Each flag names the dimension it lowers (`Flag.lowers`), and the validator holds a flagged
    option to at most 1 on that dimension. Flags don't subtract points a second time: the
    author's score already prices the mistake, and the validator proves it agrees with the flag.
- **FR-22** **[04]** Structure is scored across beats as a whole, not per pick.
  - Structure is the **lowest** structure score of the three beats: an answer is as well built as
    its weakest beat. Unit test: a 3-3-0 answer scores 0 on structure, not 67.
- **FR-23** **[15]** The weights are documented as a hypothesis in the README.
- **FR-24** **[22]** An AI senior recruiter scores the mission's answer (ADR 0006): relevance,
  specificity, structure and adaptability 0–100 plus an overall 0–100, each with one sentence of
  basis (why this score, never advice), on content only (never accent, grammar polish or style).
  - The `score` Edge Function calls Gemini (`GEMINI_MODEL`) at temperature 0 with a JSON schema,
    validates and repairs the verdict on the server, needs the player's JWT and allows 30 a day
    per player (`claim_ai_score`); Deno unit tests with the API mocked.
  - It is sent each beat's line, the reason given and whether it was guessed, the follow-up and
    the reply: never the player's name or anything they typed.
  - The dossier says "Scored by AI · Senior recruiter" and shows the basis; while it waits,
    "The panel is deliberating…", for at most 8 s.
  - No backend, no session, no network, a timeout, a spent quota or an error: the engine's
    score, labelled "Offline score", never an error (widget tests for each path).
  - The engine still scores every attempt for offline play, the traps, the Recall Room and
    progress; each verdict is stored in `ai_scores` (owner-only RLS, pgTAP tested).
- **FR-25** **[19]** A guessed beat scores nothing. A pick made less than 1.5 s
  (`guessThreshold`) after the options appear is a guess: that beat counts as 0 on every
  dimension, whatever line was picked, and the score says which beats were guessed
  (`MissionScore.guessed`, `guessedBeats`) so the debrief can explain the drop.
  - The player measures the time (`BeatPick.decidedIn`); the engine never reads a clock.
  - A guessed beat is also the weakest line for the red pen and the follow-up (FR-14, FR-15),
    and the trust meter treats it as a 0 line (`trustAfterPicks`).
  - Unit tests: a guessed evidence beat in an otherwise perfect answer gives relevance and
    specificity 75, structure 0; exactly 1.5 s is not a guess.
- **FR-26** **[19]** The reason counts. After each pick the interviewer asks "why that line?"
  and offers 3–4 reasons. Reasons are **principles about interviewing**, never a restatement of
  a line: exactly one is sound (the real reason the strongest line works), and each other is
  the misconception that tempts people into one weak line (`Reason.tempts`), so the debrief can
  say "You fell for: …". **The reason step can cost a lucky strong pick; it never deepens a
  weak one, which the debrief explains instead.** A strongest line given with the wrong
  principle keeps **60 %** (`unsoundReasonKeepPercent`, `PickCredit.unsoundReason`); a weak
  line keeps its own points whatever the reason (`ReasonPick.counts`, set by
  `Beat.reasonPick`).
  - Points are credited in integer hundredths, so the score stays exact and reproducible.
  - **Attempts saved before wave 5** (no timing, no reason) keep 100 % and score exactly as they
    did. Unit test: every 0–3 combination scores identically with and without a sound reason.
  - Content: every beat of every mission has a why step and a reaction (strong, weak, guessed)
    in the interviewer's voice. The validator enforces it, and that each beat has exactly one
    sound reason, sound only for its strongest line(s); that every weak line is tempted by
    exactly one reason; that reasons name only options of their own beat; and that no reason
    shares five words in a row with a line.

### Campaign and progression (brief §6)

- **FR-30** **[04, 07]** Chapter 1's seven missions as specified, including: Mission 1 baseline (no hints, no
  model answer before), Mission 3 first recall checkpoint (no hint cards), Mission 6 continuity
  (Lena challenges the player's actual Mission 5 answer), Mission 7 review with a new question,
  report vs. baseline, the *Evidence Builder* badge, a cliffhanger and the Chapter 2 teaser.
- **FR-31** **[13]** Chapters 2–3 are visible on the tower, locked, with their mission titles teased.
- **FR-32** **[04, 13]** Skill tree (Clear Introductions, Evidence Builder, Conflict Navigator, Think Under
  Pressure); a skill unlocks only on a demonstrated score in an unhinted mission.

### Retention (brief §2)

- **FR-40** **[04, 13]** Recall Room: a 2-minute warm-up of missed lessons, Leitner boxes at 1, 3 and 7 days.
- **FR-41** **[13]** Skill radar (four dimensions, baseline vs. now) and "then vs. now" (Mission 1 draft
  beside the latest).
- **FR-42** **[13]** No lives, no streak shaming; a soft weekly goal ("3 sessions this week").

### Notifications (brief §8, mobile only)

- **FR-50** **[11]** Local scheduled notifications: daily nudge, recall due, cliffhanger, comeback ladder
  (2/4/7/14 days, then stop), weekly win, in a character's voice, 3+ variants each.
- **FR-51** **[11]** At most 1 per day; quiet hours 21:30–08:30; back off to the ladder after 3 ignored;
  each type switchable in Settings; deep links to the right screen.
- **FR-52** **[11]** Permission asked after Mission 2 behind a custom pre-prompt, never on first launch.
- **FR-53** **[11]** Web: no notifications; Settings says reminders are in the mobile app.

### Sync and accounts (brief §10)

- **FR-60** **[08, 10]** Progress is written locally (drift) first; completed attempts go to an
  outbox flushed when online; the upsert is idempotent on a client `attempt_id`.
  - [10] Every completed attempt (picks, scores, draft, `contentSchemaVersion`, a UUID
    `attempt_id`) is written to the local database before the dossier shows, and survives a
    restart. No screen awaits the network.
  - [10] The attempt is also queued in the outbox, which simply waits until 08.
  - [08] Flushing the outbox twice, or after a timeout, leaves one server row (test against a
    local Supabase); offline then online flushes everything queued, oldest first.
  - [08] A row is removed from the outbox only after the server confirms it.
- **FR-61** **[08]** On a fresh install after sign-in, progress is restored from the server.
- **FR-62** **[05]** Tables: `profiles`, `mission_attempts`, `coach_usage`, each with RLS and owner-only
  policies, tested.
- **FR-63** **[12]** Coach Edge Function: validates input, calls Claude with the rubric, returns
  schema-validated JSON, logs usage, enforces 3 per day.

### Analytics (brief §11–12)

- **FR-70** **[02, every milestone]** Every event in `docs/EVENTS.md` is registered before its
  feature; no PII, never answer text. `user_activated` = first `mission_completed`.
  - `Analytics.track` takes an `AnalyticsEvent` and `Map<String, EventValue>`; `EventValue` has
    no `String` constructor, so typed text can't become a property (brief 02, tested).
  - `check:events` passes: the enum and `docs/EVENTS.md` agree, no string event names.
  - Every event the 10 slice fires is registered (listed in `docs/EVENTS.md`), and the 10 PR
    shows each one in the log while playing Mission 1.
  - `user_activated` fires exactly once per player, on the first `mission_completed`, even
    across restarts (stored locally).
- **FR-71** **[14, 15]** Metrics: activation, D1/D3/D7 return, median score delta (Mission 1 → 7), Mission 3
  recall pass rate, notification open rate by type and variant.

## Non-functional requirements

- **NFR-1 Cinematic design** **[03, 06, then every UI milestone]** (brief §9): the tower home,
  elevator transition, letterbox, spotlight, grain and vignette, chapter colour grades, subtitle
  dialogue, dossier debrief. No default Material look anywhere. Tokens only (`packages/brand`).
  - `check:standards` passes: no raw colour outside `packages/brand`.
  - No stock `AppBar`, `ListTile`, `Card`, `Scaffold` chrome, ink ripple or default blue on any
    screen (local-review manual pass; the no-ripple theme is tested).
  - Mission 1 [10] has the letterbox, spotlight, grain + vignette, subtitle dialogue and the
    dossier; the tower and elevator land in 13.
  - Every UI PR carries screenshots from the running app, and every key screen has a golden
    test once 06 lands (NFR-7).
- **NFR-2 Accessibility** **[06, every UI milestone]:** WCAG AA (including text over imagery), 44 pt targets, 2x text,
  reduced motion swaps camera moves for cross-fades, screen reader labels.
- **NFR-3 Performance** **[10, 14]:** 60 fps on a mid-range Android (120 on ProMotion); web first frame < 3 s
  with a branded loading screen; heavy assets deferred.
- **NFR-4 Offline** **[10, then 07 and 13 for all of Chapter 1]:** Chapter 1 fully playable offline;
  offline, loading, empty and error states designed and cinematic.
  - [10] With the device in airplane mode from a cold start, Mission 1 plays from the scene to
    the dossier and the attempt is stored. On the web (run locally; nothing is hosted, ADR 0005),
    a loaded session keeps playing when the network drops.
  - [10] Nothing in the mission loop shows a spinner waiting on the network.
  - [08] Going offline mid-session shows the designed offline state ("The lights are out. Your
    progress is safe on this device.") only where the network matters (account, sync), never
    blocking play.
  - Every state (offline, loading, empty, error) has its own design in the catalog (NFR-7).
- **NFR-5 Security** **[every milestone]:** no secret in the app; only public keys in `env/*.json` (optional; NFR-8); server secrets in
  Edge Function secrets.
- **NFR-6 Honesty** **[15]:** never promise a job; story outcomes are narrative; never invent metrics or
  testimonials; the README states the scoring and multiple-choice limits.
- **NFR-7 Quality gates** **[01, 06]:** CI green on every PR (strict analysis, format, tests, secrets,
  standards, events, env, web build); golden tests for key screens; a `/dev/catalog` route.
- **NFR-8 Zero setup** **[every milestone]:** clone → `flutter pub get` → `flutter run` works
  with no keys and fully offline; the backend is optional at runtime
  ([ADR 0005](decisions/0005-zero-setup-offline-backend-optional.md)).
  - A fresh clone runs with `cd apps/mobile && flutter run` and no env file (no
    `--dart-define`); a test boots the app with an empty `Env`.
  - No network is needed for any part of Chapter 1.
  - With Supabase keys but no network, nothing blocks or shows an error: backend features are
    silently off until the network returns.

## Out of scope for v1 (brief §13)

Chapters 2–3 content, voice answers, remote push, role campaigns, "interview of the week",
leaderboards or social features, and real payments.
