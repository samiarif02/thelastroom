# Submission: The Last Room

An interview-practice game that plays like a film, built in Flutter for an 8x product
assessment. Repo: https://github.com/samiarif02/thelastroom

**Demo video:** submitted by the owner with the assessment. Its shot list is
[`demo-script.md`](demo-script.md).

**What's built and what isn't:** every requirement and plan phase, checked, in
[`completion.md`](completion.md).

**Landing page:** [thelastroom-ten.vercel.app](https://thelastroom-ten.vercel.app), a static
Next.js site in [`web/`](../web/) that Vercel builds from `main`
([ADR 0007](decisions/0007-landing-page-on-vercel.md); [#43](https://github.com/samiarif02/thelastroom/pull/43),
[#48](https://github.com/samiarif02/thelastroom/pull/48), [#53](https://github.com/samiarif02/thelastroom/pull/53)).
It is the only hosted thing: the game itself stays zero-setup and unhosted (ADR 0005).

**Screenshots:** the README's grid ([`screenshots/`](screenshots/)), widget-test stills of the
real screens in the Daylight Tower look.

**Android APK:** the draft release on [Releases](https://github.com/samiarif02/thelastroom/releases)
(published by the owner). It installs directly, needs no keys and plays offline.

## What was built, and why

**The problem.** People practise interviews by reading lists of model answers. That builds
recognition, not judgement: they can't tell why one answer works and a plausible one doesn't,
and they don't remember the lesson next week.

**The game.** You're a graduate interviewing for a Product Associate role at a fictional
company. Three chapters of seven missions each, one interview question per mission, with
three interviewers (Priya the recruiter, Marcus the hiring manager, and Lena, who repeats your
words back), and Sam, who runs the final round. Every mission names what it practises before
it starts.
- **Chapter 1, Get Through the Door:** you build the answer from lines (below).
- **Chapter 2, Under Pressure:** you answer **out loud**. The interviewer's lines are spoken,
  you record your answer and your reply to the follow-up; recording pauses by itself after 5
  seconds of silence, Continue picks up where you stopped, Start again throws the take away. The
  AI recruiter scores what you said, never your accent or how you sound, and shows which of the
  mission's points you made. Offline, you listen back and tick the points yourself.
- **Chapter 3, The Final Round:** both: three missions built from lines, four spoken.

In Chapter 1:
- **Build an answer** in three beats (open, evidence, land). Every option is plausible, and
  every wrong one is a realistic mistake: vague, "we" not "I", off the question, rambling,
  memorised.
- **Say why.** After each pick the interviewer asks "Why that line?", and you choose the
  principle behind it. Guessing (under 1.5 s) scores nothing; a strong line given for the wrong
  principle keeps 60%.
- **Get challenged.** The interviewer reacts in character, then asks a follow-up aimed at the
  weakest part of your answer.
- **Debrief.** The *Candidate assessment* sheet: four scored dimensions, each with its basis, then "You said",
  "You fell for: …" and "What holds" for every beat, and the costliest line in red pen.
- **Recall Room.** Every trap you fell for comes back as a one-minute round of active cards on a
  Leitner schedule (1, 3, 7 days), until it stops catching you.
- **Progress.** The Northstar tower with a door per room (played, ajar, closed, locked), XP, a
  weekly ring instead of a streak, skills earned without hints, Your file with every past
  result, a floor-cleared reward, and the Chapter 1 report with your first try beside your
  latest.
- **Help when it's needed.** First-time tips one at a time (the first door, the answer cards,
  the why step, the first result, the microphone), and reminders in character on days 1, 3, 5
  and 8.

It plays fully offline with zero setup. The backend (sign-in, sync, AI scoring) is optional.

## Wave 6: what changed after the reviewer's feedback (2 to 3 Nov)

The reviewer said the app was good but looked like a children's game in places, that two looks
disagreed, and asked for a landing page, answers out loud from Chapter 2, and a justification
for every score. This is what came of it, PR by PR.

- **Three chapters, 21 rooms, all playable.** Chapter 2 is seven voice rooms
  ([#41](https://github.com/samiarif02/thelastroom/pull/41)), Chapter 3 mixes three built from
  lines and four spoken ([#42](https://github.com/samiarif02/thelastroom/pull/42)), both opened
  for the demo ([#47](https://github.com/samiarif02/thelastroom/pull/47)); the report starts
  Chapter 2 ([#49](https://github.com/samiarif02/thelastroom/pull/49)). A test plays every
  mission to its debrief and fixed what it found
  ([#54](https://github.com/samiarif02/thelastroom/pull/54)), and the tap-label check came
  back on ([#40](https://github.com/samiarif02/thelastroom/pull/40)).
- **Voice.** The interviewer's lines are spoken; you record; recording pauses after 5 s of
  silence; Continue and Start again; scored on content only, never accent; audio sent for
  scoring and never stored; a self-check offline
  ([#44](https://github.com/samiarif02/thelastroom/pull/44)).
- **Scoring you can trust.** The live Gemini recruiter, its basis on every result, "How we
  scored this", and a published evaluation that found two leniencies and fixed them
  ([#46](https://github.com/samiarif02/thelastroom/pull/46), [scoring-eval.md](scoring-eval.md)). What happens
  when the AI is wrong or down, and what it costs (≈ $0.0007 a score):
  [ai-reliability-and-cost.md](ai-reliability-and-cost.md).
- **One professional look: the Daylight Tower.** Research and three directions, then one
  ([#52](https://github.com/samiarif02/thelastroom/pull/52), [design/direction.md](design/direction.md));
  the brand, type and the drawn cast ([#55](https://github.com/samiarif02/thelastroom/pull/55));
  every screen, the tower with a door per room and floor sheets, the reward and retention
  surfaces ([#56](https://github.com/samiarif02/thelastroom/pull/56)); Your file with past
  results, the report, onboarding, the title and first-time tips
  ([#57](https://github.com/samiarif02/thelastroom/pull/57)); route transitions and animated
  back controls ([#58](https://github.com/samiarif02/thelastroom/pull/58)). One thing was
  kept on purpose: the debrief's *Candidate assessment* sheet, which the reviewer liked.
- **Retention.** "Send a test reminder", the next reminder's day and sender shown in
  Settings, a welcome-back card, and reminders on days 1, 3, 5 and 8
  ([#51](https://github.com/samiarif02/thelastroom/pull/51)); a weekly ring instead of a
  streak, XP, skills and a floor-cleared reward (#56). Then activation: a dated promise at the
  end of every room, from the real Recall schedule, and a once-only "Day 1 of your prep" moment
  after the first room. The day 1, 3, 5, 7 and 8 loop, and the events that measure it, are in
  [retention.md](retention.md).
- **The landing page** ([#43](https://github.com/samiarif02/thelastroom/pull/43),
  [#48](https://github.com/samiarif02/thelastroom/pull/48),
  [#53](https://github.com/samiarif02/thelastroom/pull/53)), and the design skills used for it
  ([#50](https://github.com/samiarif02/thelastroom/pull/50)).
- **Logs.** Every session's log regenerated and enforced by the pre-push hook
  ([#45](https://github.com/samiarif02/thelastroom/pull/45), below).

### The phone QA, and the lesson in it

On 3 Nov an agent played Chapter 1 to the end on the owner's realme 8 with a release build and
the local backend over USB ([status 51](status/51-phone-qa.md),
[#59](https://github.com/samiarif02/thelastroom/pull/59)). AI scoring worked live (rooms 2, 5,
6 and 7: 92, 90, 85, 82, each logged by the function with its model and latency), and so did
the floor-cleared reward, the report, Recall, reminders and the floor sheets.

Before any of that, it found a **P0 bug that every earlier test had missed: release APKs had
no `INTERNET` permission.** Flutter's template only declares it in the debug and profile
manifests, and no plugin merged it in. So every installed APK was offline-only: AI scoring,
voice scoring, sync and sign-in could never work, and because the game falls back to the
offline score by design (ADR 0005), nothing looked broken. It just looked like "no backend".

The lesson: **a graceful fallback hides failures, so test the real artefact, not just the
debug build.** The fix added the permission and a `check:standards` rule
(`android-release-permissions`) that fails CI if the main manifest ever loses it. The same
pass fixed a P2 where Your file mixed the AI's latest score with the engine's best, hardened
resuming a half-played room, and cleaned up several copy and layout details.

## Key decisions

| Decision | Where |
| --- | --- |
| Flutter widgets, not a game engine: cinematic UI, accessibility and the web from one codebase | [ADR 0001](decisions/0001-flutter-widgets-not-flame.md), foundation [#1](https://github.com/samiarif02/thelastroom/pull/1) |
| Offline-first: drift (SQLite) on the device, an idempotent outbox, owner-only RLS on Supabase | [ADR 0002](decisions/0002-offline-first-outbox.md), [#7](https://github.com/samiarif02/thelastroom/pull/7), [#17](https://github.com/samiarif02/thelastroom/pull/17) |
| A pure, deterministic scoring engine, unit-tested and reproducible offline | [ADR 0003](decisions/0003-deterministic-scoring-and-ai-coach.md), [#5](https://github.com/samiarif02/thelastroom/pull/5) |
| Zero setup: clone and run, no keys; the backend is optional at runtime | [ADR 0005](decisions/0005-zero-setup-offline-backend-optional.md), [#4](https://github.com/samiarif02/thelastroom/pull/4) |
| An AI senior recruiter (Gemini) scores online with one sentence of basis per number; the engine is the labelled offline score | [ADR 0006](decisions/0006-ai-scoring.md), [#25](https://github.com/samiarif02/thelastroom/pull/25) |
| Make random clicking stop paying: guess detection, the "why?" step built on principles and misconceptions, "You fell for" | [FR-25, FR-26](requirements.md), [#18](https://github.com/samiarif02/thelastroom/pull/18), [#19](https://github.com/samiarif02/thelastroom/pull/19) |
| Learn from mistakes: the Recall Room's active cards from the traps you fell for | [FR-16](requirements.md), [#23](https://github.com/samiarif02/thelastroom/pull/23) |
| A bright, friendly look after a dark cinematic first draft, with the owner choosing from three directions | [DESIGN.md](../DESIGN.md), [#6](https://github.com/samiarif02/thelastroom/pull/6), [#16](https://github.com/samiarif02/thelastroom/pull/16), [#20](https://github.com/samiarif02/thelastroom/pull/20), [#21](https://github.com/samiarif02/thelastroom/pull/21) |
| Sound: every cue synthesised in the repo (CC0, credited), quiet by default | [sound-design.md](sound-design.md), [audio-credits.md](audio-credits.md), [#13](https://github.com/samiarif02/thelastroom/pull/13), [#14](https://github.com/samiarif02/thelastroom/pull/14) |
| Android back returns to the tower and asks before exiting; leaving a mission keeps your place | [#22](https://github.com/samiarif02/thelastroom/pull/22) |
| Answer out loud from Chapter 2: spoken lines, a recorder that pauses on silence, scored on content only, a self-check offline; audio is never stored | [brief 35](briefs/35-voice-mission.md), [#44](https://github.com/samiarif02/thelastroom/pull/44), [#41](https://github.com/samiarif02/thelastroom/pull/41), [#42](https://github.com/samiarif02/thelastroom/pull/42), [#47](https://github.com/samiarif02/thelastroom/pull/47) |
| Prove the AI scores well: a published evaluation, the basis on every result, and the fixes it led to | [brief 36](briefs/36-scoring-trust.md), [scoring-eval.md](scoring-eval.md), [#46](https://github.com/samiarif02/thelastroom/pull/46) |
| A marketing landing page, hosted, while the game stays zero-setup | [ADR 0007](decisions/0007-landing-page-on-vercel.md), [#43](https://github.com/samiarif02/thelastroom/pull/43), [#53](https://github.com/samiarif02/thelastroom/pull/53) |
| One professional look, the Daylight Tower, with the Candidate assessment sheet kept as it was | [design/direction.md](design/direction.md), [#52](https://github.com/samiarif02/thelastroom/pull/52), [#55](https://github.com/samiarif02/thelastroom/pull/55)–[#58](https://github.com/samiarif02/thelastroom/pull/58) |
| Bring players back on days 3 and 5 without guilt: visible reminders, a welcome back, a weekly ring | [brief 42](briefs/42-retention.md), [#51](https://github.com/samiarif02/thelastroom/pull/51), [#56](https://github.com/samiarif02/thelastroom/pull/56) |

**How it was built.** Work ran in waves of parallel Claude Code sessions. A lead session wrote a
brief per feature (`docs/briefs/`) with file ownership, and each worker took one worktree and
one branch, kept a status file (`docs/status/`), passed the local gates, and opened a PR with
green CI. Only the owner's word merged anything. The engineering rules are in
[`AGENTS.md`](../AGENTS.md) and [`docs/rules/`](rules/).

## How to run it

```bash
git clone https://github.com/samiarif02/thelastroom && cd thelastroom
flutter pub get
cd apps/mobile && flutter run        # add -d chrome for the web
```

Flutter 3.47.8; no keys, no network. For live AI scoring: `supabase start`,
`supabase functions serve --env-file <your .env>` (with your own `GEMINI_API_KEY`), then
`flutter run --dart-define-from-file=env/dev.json` with the local URL and anon key; on an
Android phone over USB, `adb reverse tcp:54321 tcp:54321` first. The README section "Optional:
the backend and AI scoring" has the details.

## What the score is based on

- **AI score (online):** Gemini, prompted as a senior recruiter, grades relevance, specificity,
  structure and adaptability 0–100 with one sentence of basis each.
  - **Server side:** temperature 0, a JSON schema validated on the server, and a limit of 30 a
    day per player.
  - **Privacy:** only the game content the player picked is sent, never their name or anything
    they typed.
  - Details in [ADR 0006](decisions/0006-ai-scoring.md).
- **Offline score (the engine):** each line is scored 0–3 per dimension by the content author
  and weighted (relevance 25%, specificity 30%, structure 25%, adaptability 20%); structure is
  the weakest beat. Guessed beats score 0, and a strong line with the wrong principle keeps
  60%. It's deterministic and unit-tested, and it's what progress over time is measured with.
  See [FR-20–26](requirements.md).
- **Verification:** an evaluation against the live function ([scoring-eval.md](scoring-eval.md)):
  21 answers (strong, weak and guessed, for every Chapter 1 mission) scored 3 times each. 63 of 63
  verdicts returned, 92 % landed in the band the author intended, every mission ranked strong
  above weak and guessed, r = 0.91 with the engine, median 2.1 s. The first run found the AI too
  lenient on guesses (60) and on a blaming answer with good-sounding reasons (65); two prompt
  rules fixed both. Every result screen has "How we scored this": the weights, the recruiter's
  basis beside the game's own score, and what the recruiter is and isn't told.
- **On a phone:** live on a release build over USB, four rooms scored 82 to 92 by
  `gemini-3.5-flash-lite` in about 2 s each (status 51).
- **Voice (Chapters 2–3):** the same recruiter transcribes and scores the spoken answer on
  content only. Live: a strong spoken answer 95, a weak one 5, transcripts word for word. The
  audio is sent for scoring and never stored.
- **The key:** the owner's Gemini key is on the free tier, so heavy use hits per-model rate
  limits; the app then shows the offline score. Production needs billing on the key.

## Quality

- **CI on every PR:** a secrets scan, a 25-point standards check, format, strict analysis
  (`--fatal-infos`), the event registry, env, RLS and every package's tests (engine, content,
  the app with golden images on Linux). It also runs the web build, and pgTAP RLS tests on a
  fresh database.
- **Content:** a validator holds every mission to its rules (three beats, 3–4 options, flags
  priced into scores, one sound principle per beat, every weak line tempted by one
  misconception, no reason repeating a line).
- **Analytics:** events are registered in an enum before a feature ships, with no PII and no
  answer text ([EVENTS.md](EVENTS.md)).

## The business model: a paywall mock (designed, not built)

Chapter 1 is free and complete. What happens after it was decision D1
([requirements](requirements.md#d1-the-argument)). The owner first chose a **waitlist**: the
Chapter 1 report ended on Chapter 2's locked rooms and "Tell me when it opens", recording
`waitlist_joined`. Since 2 Nov this build opens Chapters 2 and 3 for the demo, so the report
offers "Start Chapter 2"; the waitlist still appears for any chapter that's locked. In a
store release, Chapters 2 and 3 are the Pro content below. A real paywall (RevenueCat in sandbox) would have cost a day for a purchase
no reviewer can make from a clone. So the paywall is designed here, as the plan asked, and the
waitlist measures the same thing: demand for what comes next.

```text
┌──────────────────────────────────────────┐
│  CHAPTER 2 · UNDER PRESSURE               │
│  Marcus and Lena are waiting.             │
│                                           │
│  ✓ Chapters 2 and 3: 14 new missions,     │
│    Under Pressure and The Final Round     │
│  ✓ AI recruiter scoring, unlimited        │
│    (Chapter 1 keeps 30 a day, free)       │
│  ✓ Say it your way: answer in your own    │
│    words, graded on content only          │
│  ✓ Your interview date: a plan that       │
│    paces the Recall Room to it            │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │  Start 7 days free                  │  │   then £4.99 / month
│  └─────────────────────────────────────┘  │   or £29.99 / year (save 50%)
│  Not now: keep practising Chapter 1       │
│                                           │
│  Cancel any time. We never promise a job. │
└──────────────────────────────────────────┘
```

- **Free forever:** Chapter 1 (seven missions), the Recall Room, the offline score, reminders,
  themes. Learning never stops at a paywall, so a player mid-Recall is never locked out.
- **Pro:** the content and the AI that cost money to make and to run.
- **When it's shown:** only at the end of the Chapter 1 report, never mid-mission, and only once
  per session after that.
- **Prices are a hypothesis**, pitched at a student budget (below a typical language-learning
  subscription). The waitlist's `waitlist_joined` ÷ `chapter_completed` is the first signal to
  test them against.
- **Honest copy:** "Cancel any time. We never promise a job." (NFR-6). No fake reviews, counts or
  countdown timers.

## What's next

- More voice missions, and answering Chapter 1 out loud as a second pass.
- Billing on the Gemini key, so AI scoring holds up under real use.
- More reminder types from FR-50 (the cliffhanger, the weekly win), and reminders tested on iOS.
- Own SMTP for the hosted project (Supabase's built-in sender allows only a few emails an hour).
- Validating the scoring weights against human-rated answers.
- Smoothing the door → room transition, the one path that drops frames on the realme (15 of 245;
  every path's p90 is under 16.6 ms, [status 56](status/56.md)).
- A store build: a release signing key, then Play Store and TestFlight.
- Metrics: a PostHog sink for the events (cut for v1 by the owner, 1 Nov; every event is already
  defined, registered and logged on the device).

## Claude Code logs

Every session's prompts and final responses are in [`.claude-logs/`](../.claude-logs/), one
Markdown file per session, each ending with a "Subagents" section. A hook in
`.claude/settings.json` (`.claude/hooks/extract-log.py`) writes them, and they're committed with
every PR.

**The 1 Nov logging fix.** The first review scored the logs 0/15. The hook had logged whichever
transcript in the project folder changed last, not the session that fired it. With several
sessions sharing a folder (parallel workers, two Claude profiles), they overwrote each other, and
a session that moved worktree was never logged again.
- [#27](https://github.com/samiarif02/thelastroom/pull/27) makes the hook read the
  `transcript_path` Claude Code passes it, and backfills all 17 sessions from their full
  transcripts (136 KB → 268 KB, with the owner's prompts restored).
- [#28](https://github.com/samiarif02/thelastroom/pull/28) names each log after the repo, not
  the worktree folder.

**The 2 Nov enforcement.** Background agents log inside their parent session, so PRs they
opened could reach `main` without a log commit. [#45](https://github.com/samiarif02/thelastroom/pull/45)
regenerates every session from its transcript and makes the pre-push hook refuse any branch
without a session-log commit, or with newer log changes left uncommitted. Each later PR carries
the log of the session that made it.
