# Submission: The Last Room

An interview-practice game that plays like a film, built in Flutter for an 8x product
assessment. Repo: https://github.com/samiarif02/thelastroom

**Demo video:** _the owner's recording, link to be added here_ (TODO: owner)

**Android APK:** the draft release on [Releases](https://github.com/samiarif02/thelastroom/releases)
(published by the owner). It installs directly, needs no keys and plays offline.

## What was built, and why

**The problem.** People practise interviews by reading lists of model answers. That builds
recognition, not judgement: they can't tell why one answer works and a plausible one doesn't,
and they don't remember the lesson next week.

**The game.** You're a graduate interviewing for a Product Associate role at a fictional
company. Chapter 1 has seven missions, each one interview question, with three interviewers
(Priya the recruiter, Marcus the hiring manager, and Lena, who repeats your words back).
- **Build an answer** in three beats (open, evidence, land). Every option is plausible, and
  every wrong one is a realistic mistake: vague, "we" not "I", off the question, rambling,
  memorised.
- **Say why.** After each pick the interviewer asks "Why that line?", and you choose the
  principle behind it. Guessing (under 1.5 s) scores nothing; a strong line given for the wrong
  principle keeps 60%.
- **Get challenged.** The interviewer reacts in character, then asks a follow-up aimed at the
  weakest part of your answer.
- **Debrief.** A dossier with four scored dimensions, each with its basis, then "You said",
  "You fell for: …" and "What holds" for every beat, and the costliest line in red pen.
- **Recall Room.** Every trap you fell for comes back as a one-minute round of active cards on a
  Leitner schedule (1, 3, 7 days), until it stops catching you.
- **Progress.** A tower to climb, stars per mission, a skills radar, and your Mission 1 baseline
  beside your latest.

It plays fully offline with zero setup. The backend (sign-in, sync, AI scoring) is optional.

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

Flutter 3.47.8; no keys, no network. For AI scoring on a laptop, see the README section
"Optional: the backend and AI scoring".

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
- **Verification:** AI scoring is verified with a mocked Gemini (15 Deno tests and the app's
  fallback tests); the live run with a real key on a phone hasn't been done yet.

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

## What's next

- Chapters 2 and 3 (visible now as locked teasers): the panel interview and the final round.
- A free-text answer mode (not built): say your answer in your own words and get it graded on
  content only.
- More reminder types from FR-50 (the cliffhanger, the weekly win), and reminders tested on iOS.
- A hosted backend, so AI scoring works away from the laptop.
- Validating the scoring weights against human-rated answers.
- A store build: a release signing key, then Play Store and TestFlight.

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
