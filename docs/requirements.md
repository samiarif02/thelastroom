# The Last Room: requirements (v1)

Derived from `docs/product-brief.md` (the source of design intent). This file is the testable
version: each requirement has an id that specs, PRs and tests can cite. Per-feature specs
(`docs/<feature>-requirements.md` + `docs/<feature>-plan.md`) refine these before code.

**Scope:** Chapter 1 (Missions 1–7) complete and polished; Chapters 2–3 visible, locked and
teased. **Platforms:** Android, iOS, and a Flutter web build as the public demo link.

## Decisions needed (the owner's call)

| # | Decision | Options | Recommendation | Source |
| --- | --- | --- | --- | --- |
| D1 | **[Decision needed]** What happens after Chapter 1 | (a) designed Pro paywall with RevenueCat in sandbox, (b) "Chapter 2 is coming, notify me" waitlist, (c) just the teaser | **(b)**: honest, cheap, still shows business thinking; mock the paywall in `docs/SUBMISSION.md` | Brief §7 |
| D2 | **[Decision needed]** Interviewer portrait art | commission, draw in Rive (animated idle), or AI-generated images you have rights to | Decide in the design session; credit it in the README | Kit README §7 |
| D3 | **[Decision needed]** Web demo host | GitHub Pages, Firebase Hosting, Vercel/Netlify static, Cloudflare Pages | Decide in the deploy session; must serve WASM with the right headers for drift | Brief §10, kit README §5 |
| D4 | **[Decision needed]** Display serif and body sans | any OFL-licensed pair, bundled | Decide in the design session (DESIGN.md) | Brief §9 |
| D5 | **[Decision needed]** Sound design in v1 | none, or subtle licensed UI sounds (off by default) | Only if time allows after Chapter 1 is polished | Brief §9 |

## Functional requirements

### Core flow (brief §7)

- **FR-1** Splash → 3-screen intro (the hook) → Mission 1 as a guest, with no sign-up wall.
- **FR-2** First launch signs in anonymously (Supabase) and gets a real user id; offline, the
  game still starts and syncs the guest later.
- **FR-3** After Mission 1: "Save your progress" offers linking email or Google; the linked
  account keeps all progress.
- **FR-4** Short onboarding after Mission 1: target role (v1: general entry-level/product),
  nerves level 1–5 (sets calm mode), optional interview date.
- **FR-5** Missions 2–7 → Chapter 1 report → Chapter 2 teaser → D1's outcome.

### The mission loop (brief §3)

- **FR-10** Scene: interviewer portrait (idle animation, spotlight), 1–3 setup lines, then the
  question, as typewriter subtitles with the speaker's name (tap to complete).
- **FR-11** Draft first (optional): the player types a first line before seeing options. Stored
  locally; feeds "then vs. now"; graded by the coach only when online.
- **FR-12** Build the answer in three beats (Open → Evidence → Land), each offering 3–4 plausible
  options. Distractors are realistic mistakes, never jokes.
- **FR-13** A soft 60-second timer per answer, shown as the light dimming (numeric only under
  10 s). Calm mode turns it off.
- **FR-14** Follow-up: the interviewer reacts to the weakest part of the answer (vague → "What did
  *you* specifically do?", blame → "What was your part in it?"); the reply is scored for
  adaptability.
- **FR-15** Debrief as a candidate dossier: four dimension scores, the trust meter, **one**
  concrete lesson, the line that cost most marked in red pen. Optional "Say it your way" free
  text, graded by the coach when online.
- **FR-16** Progress: XP, any skill unlocked, a Recall Room card for each lesson missed.

### Scoring (brief §4)

- **FR-20** Deterministic and offline: each option scores 0–3 per dimension; mission score
  normalised to 0–100; weights relevance 25%, specificity 30%, structure 25%, adaptability 20%.
- **FR-21** Flags (`vague`, `we_not_i`, `blame`, `rambling`, `generic`, `off_question`,
  `memorized`) lower the relevant dimension and drive the follow-up.
- **FR-22** Structure is scored across beats as a whole, not per pick.
- **FR-23** The weights are documented as a hypothesis in the README.
- **FR-24** The coach grades content only, never accent, grammar polish or style; the UI says so.

### Campaign and progression (brief §6)

- **FR-30** Chapter 1's seven missions as specified, including: Mission 1 baseline (no hints, no
  model answer before), Mission 3 first recall checkpoint (no hint cards), Mission 6 continuity
  (Lena challenges the player's actual Mission 5 answer), Mission 7 review with a new question,
  report vs. baseline, the *Evidence Builder* badge, a cliffhanger and the Chapter 2 teaser.
- **FR-31** Chapters 2–3 are visible on the tower, locked, with their mission titles teased.
- **FR-32** Skill tree (Clear Introductions, Evidence Builder, Conflict Navigator, Think Under
  Pressure); a skill unlocks only on a demonstrated score in an unhinted mission.

### Retention (brief §2)

- **FR-40** Recall Room: a 2-minute warm-up of missed lessons, Leitner boxes at 1, 3 and 7 days.
- **FR-41** Skill radar (four dimensions, baseline vs. now) and "then vs. now" (Mission 1 draft
  beside the latest).
- **FR-42** No lives, no streak shaming; a soft weekly goal ("3 sessions this week").

### Notifications (brief §8, mobile only)

- **FR-50** Local scheduled notifications: daily nudge, recall due, cliffhanger, comeback ladder
  (2/4/7/14 days, then stop), weekly win, in a character's voice, 3+ variants each.
- **FR-51** At most 1 per day; quiet hours 21:30–08:30; back off to the ladder after 3 ignored;
  each type switchable in Settings; deep links to the right screen.
- **FR-52** Permission asked after Mission 2 behind a custom pre-prompt, never on first launch.
- **FR-53** Web: no notifications; Settings says reminders are in the mobile app.

### Sync and accounts (brief §10)

- **FR-60** Progress is written locally (drift) first; completed attempts go to an outbox
  flushed when online; the upsert is idempotent on a client `attempt_id`.
- **FR-61** On a fresh install after sign-in, progress is restored from the server.
- **FR-62** Tables: `profiles`, `mission_attempts`, `coach_usage`, each with RLS and owner-only
  policies, tested.
- **FR-63** Coach Edge Function: validates input, calls Claude with the rubric, returns
  schema-validated JSON, logs usage, enforces 3 per day.

### Analytics (brief §11–12)

- **FR-70** Every event in `docs/EVENTS.md` is registered before its feature; no PII, never
  answer text. `user_activated` = first `mission_completed`.
- **FR-71** Metrics: activation, D1/D3/D7 return, median score delta (Mission 1 → 7), Mission 3
  recall pass rate, notification open rate by type and variant.

## Non-functional requirements

- **NFR-1 Cinematic design** (brief §9): the tower home, elevator transition, letterbox,
  spotlight, grain and vignette, chapter colour grades, subtitle dialogue, dossier debrief. No
  default Material look anywhere. Tokens only (`packages/brand`).
- **NFR-2 Accessibility:** WCAG AA (including text over imagery), 44 pt targets, 2x text,
  reduced motion swaps camera moves for cross-fades, screen reader labels.
- **NFR-3 Performance:** 60 fps on a mid-range Android (120 on ProMotion); web first frame < 3 s
  with a branded loading screen; heavy assets deferred.
- **NFR-4 Offline:** Chapter 1 fully playable offline; offline, loading, empty and error states
  designed and cinematic.
- **NFR-5 Security:** no secret in the app; only public keys in `env/*.json`; server secrets in
  Edge Function secrets.
- **NFR-6 Honesty:** never promise a job; story outcomes are narrative; never invent metrics or
  testimonials; the README states the scoring and multiple-choice limits.
- **NFR-7 Quality gates:** CI green on every PR (strict analysis, format, tests, secrets,
  standards, events, env, web build); golden tests for key screens; a `/dev/catalog` route.

## Out of scope for v1 (brief §13)

Chapters 2–3 content, voice answers, remote push, role campaigns, "interview of the week",
leaderboards or social features, and real payments.
