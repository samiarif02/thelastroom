# The Last Room

> One room left between you and the offer.

**An interview-practice game that looks like a film.** You're a candidate with little experience,
interviewing at a fictional company, Northstar Labs. Each mission is one interview moment: you
build an answer under light time pressure, the interviewer reacts and pushes back with a
follow-up, and a debrief shows exactly what made your answer stronger or weaker. Built in Flutter
for Android, iOS and the web.

**▶ Watch the demo:** _video coming soon_. To play, clone and run it (below): no keys, no setup,
fully offline.

## Why

Hard interview questions are a skill, and most people practise them by reading lists of
"top 50 answers". The Last Room teaches by playing, Duolingo-style: short missions, plausible
wrong answers that are realistic mistakes rather than jokes, follow-ups that punish vagueness, a
Recall Room that brings back what you missed on days 1, 3 and 7, and a report that shows your
own first draft beside your latest. It's for students, fresh graduates, career changers and
non-native English speakers.

What it doesn't promise: a job. Story outcomes are narrative, not predictions. The scoring
weights are a hypothesis that would need human-rated samples to validate, and choosing between
written options isn't the same as answering live (free-text practice is the optional AI coach's
job, and it grades content only, never accent or grammar).

Built for a product assessment by [8x](https://github.com/8xsocial). The full design is in
[`docs/product-brief.md`](docs/product-brief.md); requirements in
[`docs/requirements.md`](docs/requirements.md); the visual direction in [`DESIGN.md`](DESIGN.md).

## Run it

Requirements: Flutter **3.47.8** (stable; pinned here and in CI), Node 22+ (for the gate scripts
and git hooks), and for the backend later, the Supabase CLI and Docker.

```bash
git clone https://github.com/samiarif02/thelastroom && cd thelastroom
flutter pub get        # resolves the whole Dart workspace
npm install            # no dependencies; installs the git hooks (core.hooksPath)

cd apps/mobile
flutter run -d chrome  # the web, locally
flutter run            # a running emulator/simulator or a connected phone
```

No env file, no keys, no network needed: the game plays fully offline.

**Optional backend.** To turn on sign-in and sync, give it public Supabase config:

```bash
cp env/dev.example.json env/dev.json          # public config only; every key is optional
flutter run --dart-define-from-file=env/dev.json
```

With no keys, or keys but no network, every backend feature is silently off and the game is
unaffected ([ADR 0005](docs/decisions/0005-zero-setup-offline-backend-optional.md)).

### Gates (what CI runs on every PR)

```bash
npm run check:secrets && npm run check:standards && npm run format:check && npm run analyze \
  && npm run check:events && npm run check:env && npm run test && npm run build:web
```

## Repository layout

```
apps/mobile/        Flutter app (Android, iOS, web)
packages/engine/    pure-Dart scoring, follow-ups, unlocks, recall scheduling
packages/content/   missions, interviewers, lessons + validation tests
packages/brand/     design tokens and theme
supabase/           migrations, Edge Functions (AI coach)
docs/               brief, requirements, events, rules, memory, decisions, HANDOFF
scripts/            gate scripts (commit messages, secrets, standards, events, env, tests)
.claude-logs/       the Claude Code session transcripts behind every change
```

Engineering rules for people and agents: [`AGENTS.md`](AGENTS.md). It follows 8x's
[template](https://github.com/8xsocial/template-web) standards, ported from Next.js/Expo to
Flutter; the divergences are listed there.

## Credits

Fonts, illustrations and sounds will be credited here as they're added.
