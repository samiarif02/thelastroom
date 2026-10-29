# The Last Room — Product Brief

> One room left between you and the offer.

**Track:** Open (career skill: answering interview questions). Theme: *learning that sticks*.
**Platform:** Flutter app for Android and iOS, plus a **Flutter web build as the playable demo
link** for reviewers.
**Status:** v1 brief. Items marked **[Decision needed]** are the owner's call.

---

## 1. What it is

An interview-practice game. The player is a candidate with little experience, interviewing at a
fictional company, **Northstar Labs**, for an entry-level product role. Each mission is one
interview moment. The player builds an answer under light time pressure, the interviewer reacts
and asks a follow-up, and a debrief shows exactly what made the answer stronger or weaker.

- **Audience:** university students, fresh graduates, career changers, early-career
  professionals. Many are non-native English speakers.
- **The skill:** answering hard interview questions with clear structure, real evidence, and
  calm handling of follow-ups.
- **The promise:** measurable improvement through practice. **Never** a promise of a job. Story
  outcomes are narrative, not predictions.
- **The feel:** Duolingo-style learning by playing. It's short, friendly and rewarding, with
  curiosity pulling you to "what happens next", and no pressure or punishment.

## 2. Why it sticks: answers to "Day 3, Day 7, and how do I know I'm better?"

| Question | Answer in the product |
| --- | --- |
| Why come back on Day 3? | The **Recall Room**: a 2-minute warm-up of lessons you got wrong, spaced 1, 3 and 7 days apart (Leitner boxes). There's also a story thread left open at the end of each session, and a **notification in an interviewer's voice** (section 8). |
| Why come back on Day 7? | Chapter 1 ends with a review compared with your Mission 1 baseline, a badge earned by demonstrating a skill, and Chapter 2 teased with a new, harder interviewer. |
| How do I know I'm improving? | (1) **Skill radar:** four dimensions, baseline vs. now. (2) **"Then vs. now":** your own typed first draft from Mission 1 shown beside your latest. (3) **Skills unlock only when demonstrated** without hints. |
| What keeps it from feeling like pressure? | No lives and no streak shaming. A soft **weekly** goal ("3 sessions this week"). A calm mode turns off the timer. Failing still teaches, because the interviewer just gets less receptive. |

## 3. The core loop (one mission, 4–6 minutes)

1. **Scene.** The interviewer appears (portrait with idle animation, spotlight) with 1–3 lines of
   setup, then the question.
2. **Draft first (optional, ungraded offline).** The player types a first line of their own
   answer before seeing options. It's stored locally and feeds "then vs. now". When online, the
   AI coach can grade it.
3. **Build the answer.** It has three beats: **Open → Evidence → Land**. Each beat offers 3–4
   plausible lines; distractors are realistic mistakes, never jokes. Each line is tagged with
   points per dimension and flags (`vague`, `we_not_i`, `blame`, `rambling`, `generic`,
   `off_question`, `memorized`). A soft 60-second timer runs (calm mode turns it off).
4. **Follow-up.** The interviewer reacts to the weakest part of the answer. Vague evidence gets
   "What did *you* specifically do?" and blame gets "What was your part in it?" The player picks
   a reply, which is scored for **adaptability**.
5. **Debrief.** Scores on four dimensions, the trust meter, **one** concrete lesson, and a
   highlight of the line that cost the most. An optional "Say it your way" lets the player
   rewrite the answer in free text, graded by the AI coach when online.
6. **Progress.** XP, any skill unlocked, and a Recall Room card scheduled for each lesson missed.

> **Why this isn't just multiple choice:** the distractors are plausible, the beats combine (the
> structure is scored across beats), follow-ups punish vagueness made earlier, recall
> checkpoints remove the hints, and the review missions use new questions to test transfer.
> Free-text practice is the AI coach's job. The README states this limit openly.

## 4. Scoring (deterministic, offline, unit-tested)

| Dimension | Weight | Measured from |
| --- | --- | --- |
| Relevance | 25% | Beat picks: does it answer *this* question? |
| Specificity | 30% | Concrete, personal, credible evidence (`we_not_i` and `vague` lower it) |
| Structure & clarity | 25% | The beat order works as a whole (`rambling` and `memorized` lower it) |
| Adaptability | 20% | Follow-up replies |

- Each option scores 0–3 per dimension. A mission score is normalised to 0–100.
- The weights are a **hypothesis**, and the README says so: validating them needs human-rated
  samples.
- The AI coach grades **content only**. It never grades accent, grammar polish, or style. This is
  stated in its system prompt and in the UI.

## 5. Characters (fictional, original)

| Interviewer | Style | Tests mostly |
| --- | --- | --- |
| **Priya**, recruiter | Warm, brisk | Relevance, concise intros |
| **Marcus**, hiring manager | Detail-oriented | Specificity, "what did *you* do" |
| **Lena**, senior engineer | Skeptical | Follow-ups, adaptability |
| **Sam**, head of product (final round) | Calm, high bar | Everything together |

Original art only, with no likeness of real people. One consistent illustration style. Each
character has 3 expressions (neutral, pleased, skeptical) that react to the answer.

## 6. Campaign

21 missions in 3 chapters. **v1 builds Chapter 1 fully; Chapters 2–3 are visible, locked, and
teased.**

### Chapter 1: Get Through the Door [v1]

| # | Mission | Interviewer | Mechanic / lesson |
| --- | --- | --- | --- |
| 1 | The Opportunity | Priya | **Baseline.** Draft first plus a card answer, with no hints and no model answer shown before. Records baseline scores. |
| 2 | Tell Me About Yourself | Priya | Present → past → future. Relevance over life story. |
| 3 | The Experience Gap | Priya | **First recall checkpoint:** "Others have more experience." No hint cards. |
| 4 | Show Me the Evidence | Marcus | "I" vs. "we". Vague picks trigger "What did *you* do?" |
| 5 | Something Went Wrong | Marcus | STAR without sounding memorised; `blame` flags. |
| 6 | The Follow-Up Trap | Lena | **Continuity:** Lena challenges the player's *actual* Mission 5 answer. |
| 7 | First Round Review | Priya + Marcus | A new question with no hints. **Report vs. baseline.** Badge: *Evidence Builder*. Cliffhanger, then the Chapter 2 teaser. |

### Chapter 2: Under Pressure [locked in v1]
8 Team Conflict · 9 The Failure · 10 No Clear Instructions · 11 Tight Deadline · 12 The
Uncomfortable Request · 13 The Unexpected Follow-Up · 14 Panel Review

### Chapter 3: The Final Round [locked in v1]
15 Solve the Problem · 16 The Interruption · 17 "I Don't Know" · 18 The Salary Question ·
19 Your Turn to Ask · 20 The Final Interview · 21 The Decision

**Skill tree:** Clear Introductions · Evidence Builder · Conflict Navigator · Think Under
Pressure. Each unlocks only on a demonstrated score in an unhinted mission.

## 7. Core flow

`Splash → 3-screen intro (the hook) → Mission 1 as a guest → "Save your progress" (email or Google)
→ short onboarding → Missions 2–7 → Chapter 1 report → Chapter 2 teaser`

- **Guest play:** Supabase **anonymous sign-in** gives a real user id instantly. The account is
  linked to email or Google later and keeps all progress. There's no sign-up wall before value.
- **Onboarding (after Mission 1):** target role (v1: general entry-level / product), nerves level
  (1–5, which sets calm mode), interview date (optional; tunes the weekly goal and notifications).
- **Notification permission:** asked **after Mission 2**, in context, behind a custom pre-prompt
  screen (section 8). Never on first launch.
- **[Decision needed]** What happens after Chapter 1: (a) a designed Pro paywall with RevenueCat in
  sandbox, (b) a "Chapter 2 is coming, notify me" waitlist, or (c) just the teaser.
  Recommendation: **(b)** for v1. It's honest, cheap, and still shows the business thinking.
  Mock the paywall design in the submission write-up.

## 8. Notifications (Duolingo-style, in-character, kind)

**v1 uses local scheduled notifications** (`flutter_local_notifications`). They work offline and
need no server. Remote push (FCM) is v2, for changing copy remotely and win-back after a
reinstall.

| Type | When | Example copy (in a character's voice) |
| --- | --- | --- |
| Daily nudge | The user's usual play hour (learned; default 19:00 local), only if they haven't played today | "Priya: Your interview slot is still open. Five minutes?" |
| Recall due | When a Recall Room card is due (days 1, 3, 7) | "Marcus remembers what you said about the deadline. Do you?" |
| Cliffhanger | About 20 h after a session that ended on an open thread | "Lena has one more question for you…" |
| Comeback ladder | 2, 4, 7 and 14 days after the last session, **then stop** | Day 2: "The room's gone quiet." Day 4: "Priya kept your seat warm 🪑" Day 7: "Northstar is still hiring. Are you still interviewing?" Day 14: "We'll stop knocking. Your seat stays open." |
| Weekly win | Sunday evening, only if they played that week | "This week: Specificity +18. That's real progress." |

Rules:
- **At most 1 per day.** Quiet hours are 21:30–08:30 local. The pattern is "cancel all, then
  reschedule the next 7 days" on every app open and close; iOS caps pending notifications at 64.
- **Back off:** after 3 ignored in a row, drop to the comeback ladder only. All copy is playful,
  never guilt or shame. Each type can be switched off in Settings.
- Each notification **deep-links** to its screen (Recall Room, next mission). Copy rotates
  across 3+ variants per type. All copy is original; don't reuse Duolingo's lines.
- Android 13+ `POST_NOTIFICATIONS` runtime permission, the boot receiver so schedules survive a
  restart, and inexact scheduling (`inexactAllowWhileIdle`) so we don't need the exact-alarm
  permission. iOS has its own permission request.
- Events: `notification_permission_prompted`, `notification_permission_granted`,
  `notification_opened` (type, variant). These measure which copy brings people back.
- Web demo: notifications are skipped, and Settings shows that reminders are available in the
  mobile app.

## 9. Design: CINEMATIC, the #1 priority (reviewers inspect the UI closely)

**The bar:** someone should screenshot it because it looks like a film, not like an app. If a
screen could belong to any other quiz app, it isn't done. No default Material look anywhere: no
stock AppBar, no plain ListTiles, no default blue, no generic cards.

### The big idea: the building
Northstar Labs is a tall glass tower at night. **Each chapter is a floor, and the last room is at
the top.**
- **Home is the tower,** seen from outside. Lit windows are completed missions, the current
  floor glows, and floors above are dark (locked). Tapping a floor zooms the camera into it.
- **The elevator is the transition** between missions: doors slide closed, the floor counter
  ticks up, a soft chime plays, the doors open on the next room. It's short (about 1.2 s) and
  skippable.
- **The final room** (Chapter 3) is the top floor: a dark office with the city skyline behind
  Sam. Players can *see* it from the start. That's the curiosity hook.

### The film language (how each screen should feel)
| Technique | Where | How in Flutter |
| --- | --- | --- |
| **Letterbox bars** slide in when a scene starts and out for the choice phase | Mission scenes | Animated black bars; the scene content scales slightly (Ken Burns) |
| **Spotlight lighting** on the interviewer, with a tiny slow flicker and dust in the light | Every scene | Radial gradient plus a particle layer (CustomPainter), pre-composited |
| **Film grain plus vignette** over everything, very subtle | Global overlay | Fragment shader (`FragmentProgram`) or tiled noise, behind a RepaintBoundary |
| **Camera "cuts"**: wide shot → close-up when the question lands; over-the-shoulder for the follow-up | Mission flow | Hero and scale/translate transitions; depth-of-field blur on the background layer only |
| **Subtitle-style dialogue**, a typewriter reveal with the speaker's name in small caps | All dialogue | Custom text animation; tap to complete |
| **Chapter title cards**, like a film opening ("CHAPTER ONE — GET THROUGH THE DOOR") | Chapter start | Full-screen serif title, slow fade and tracking-in |
| **A colour grade per chapter**: Ch1 warm amber lobby, Ch2 cold steel blue (pressure), Ch3 deep oxblood and gold (final round) | Theme per chapter | The chapter palette is in the brand tokens; the whole UI re-tints |
| **Parallax depth:** background, desk and interviewer on 3 layers that shift with the device tilt (and the pointer on web) | Scenes, home tower | `sensors_plus`, small offsets, disabled under reduced motion |
| **The trust meter is a heartbeat line** that calms or spikes; **the timer is the light slowly dimming** | Answer phase | CustomPainter; no numeric countdown unless it's under 10 s |
| **The debrief is a "candidate dossier"**: a paper file slides onto the desk, scores are stamped, red-pen notes mark the weak line | Debrief | Layered cards, stamp animation with a haptic "thud" |
| **Sound design** (optional, off by default): room tone, elevator chime, paper slide, stamp | Key moments | Short, licensed, credited |

### Visual system
- **Palette:** near-black and charcoal surfaces, warm off-white text, one hero accent (spotlight
  amber), and the per-chapter grade layered on top. WCAG AA everywhere, including text over
  imagery (use scrims).
- **Type:** a dramatic display serif for titles, chapter cards and the interviewers' names
  (high contrast, film-poster feel), a clean, legible sans for body and choices, and
  tabular numbers for scores. **The font files are bundled** (offline-safe, no runtime
  fetch).
- **Characters:** one consistent original illustration style (painterly, or flat with
  cinematic rim light), 3 expressions each, animated idle (blink, breathe) via Rive.
- **Motion:** every animation has a purpose (it tells the player what happened). Use eased,
  weighty curves, not bouncy toys. Haptics on choice, stamp and unlock. **Reduced motion** swaps
  every camera move for a cross-fade.

### Performance (cinematic must still be smooth)
60 fps on a mid-range Android, 120 on ProMotion. Blur only small regions; pre-bake gradients
into images where possible. Use RepaintBoundary around the grain, particles and meter. Precache
scene images before the elevator opens. Profile every scene in `--profile` mode with DevTools
and fix any jank before the PR. On the web, the first frame should appear in under 3 s on a
normal connection: a branded loading screen in `index.html`, deferred heavy assets.

### Proof of quality
Golden tests for every key screen and state, a `/dev/catalog` route showing every component in
every state, and before/after screenshots in every UI PR.

- **No game engine:** Flutter widgets, CustomPainter, shaders, `flutter_animate` and Rive are
  enough. **Flame is not needed:** it's for sprite and physics games.
- **Quality bar:** 44 pt targets, text that survives large font scaling, and empty, loading,
  offline and error states that are *also* cinematic (for example offline: "The lights are out.
  Your progress is safe on this device.").
- **Tokens:** all colours, type, spacing, radii, motion and chapter grades live in
  `packages/brand` (see DESIGN.md). Widgets use no raw hex values.

## 10. Architecture (Flutter)

```
apps/mobile (Flutter: Android, iOS, Web demo)
   │  plays fully offline: content + engine bundled, progress in local SQLite (drift)
   │  outbox ──(when online)──▶ Supabase Postgres (RLS: a user reads/writes only own rows)
   │  auth ─────────────────▶ Supabase Auth (anonymous → linked email/Google)
   └─ "Say it your way" ─────▶ Supabase Edge Function `coach` ──▶ Claude API (key server-side only)
packages/engine   pure Dart: scoring, follow-up choice, unlocks, Leitner recall, baseline compare
packages/content  missions/interviewers/lessons as typed Dart + validation tests
packages/brand    design tokens + ThemeData
```

- **Monorepo:** Dart pub workspaces (a root `pubspec.yaml` with `workspace:`). A root
  `package.json` holds only the stack-agnostic gate scripts from 8x's templates (commit-message
  check, secret scan, standards check) and `prepare` → `git config core.hooksPath .githooks`.
- **App:** Riverpod 3 (state), go_router (routing and deep links), drift (local DB and outbox;
  works on web via WASM), supabase_flutter, flutter_local_notifications + timezone,
  flutter_animate + Rive + fragment shaders (cinematic layer), sensors_plus (parallax),
  sentry_flutter (errors), posthog_flutter (analytics).
- **Sync:** completed attempts go into a local outbox and are flushed when online. The upsert is
  idempotent on a client-generated `attempt_id`. On a fresh install, progress is restored from
  the server.
- **Data (Supabase migrations in `supabase/migrations/`):** `profiles`, `mission_attempts`
  (user, mission id, content version, choices, per-dimension scores, total, timestamps,
  `attempt_id` unique), and `coach_usage` (daily limit, tokens, cost). Every table has RLS
  **with owner-only policies**. Note: this differs from 8x's template, where the client never
  touches tables. Record the divergence in AGENTS.md, as their STANDARDS.md asks.
- **AI coach:** an Edge Function validates input, calls Claude with the four-dimension rubric,
  returns Zod-validated JSON, logs usage, and enforces a free daily limit (3 per day). Pick the
  model with the `claude-api` skill.
- **Config:** one `Env` class reads `--dart-define-from-file` values. `.env.example` documents
  every key. Only public keys go in the app (the Supabase anon key); secrets live only in Edge
  Function secrets.
- **Voice answers:** v2.

## 11. Events (register them before building; the registry is a Dart enum)

`intro_completed` · `guest_started` · `account_linked` · `onboarding_completed` ·
`mission_started` · `mission_completed` (mission_id, chapter, score_bucket, attempt_number) ·
`baseline_recorded` · `follow_up_answered` · `recall_session_completed` · `skill_unlocked` ·
`chapter_completed` · `progress_report_viewed` · `coach_feedback_requested` ·
`notification_permission_prompted` / `_granted` · `notification_opened` ·
`waitlist_joined`. `user_activated` = the first `mission_completed`. There's no personal data
in properties, and never any answer text. A CI check fails if code fires an event that isn't in
the enum.

## 12. Success metrics

Activation (% of guests who finish Mission 1) · D1 / D3 / D7 return · median score delta from
the Mission 1 baseline to the Mission 7 review · the Mission 3 recall pass rate · notification
open rate by type and variant.

## 13. Out of scope for v1

Chapters 2–3 content, voice answers, remote push, role campaigns, "interview of the week",
leaderboards or social features, and real payments.
