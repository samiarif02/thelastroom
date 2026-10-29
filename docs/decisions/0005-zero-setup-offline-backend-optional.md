# 0005. Zero setup, fully offline, backend optional

- **Status:** accepted (2026-10-29)
- **Amends:** [0002](0002-offline-first-outbox.md) (the backend is optional at runtime)
- **Reverses:** D3 in `docs/requirements.md` (Vercel), decided earlier the same day

## Context

Reviewers judge the game by playing it, and the deadline is Thursday 5 November. Earlier on
29 October we chose Vercel for a hosted web demo, with a preview link per PR. That meant three
repository secrets, an extra CI job, a `vercel.json` to keep right, and a deploy surface to
watch, all for a link that reviewers who clone the repo don't need. A hosted Flutter web build
also pulls in cross-origin headers (COOP/COEP) for drift's fastest storage, and those break
fonts fetched from other origins and OAuth popups.

The game is already offline-first (ADR 0002): content and engine ship in the app, and progress
is written to the device first. The backend only stores progress, links accounts and runs the
optional AI coach. Nothing in Chapter 1 needs it.

## Decision

- **No hosted web demo.** Nothing is deployed for the web. Reviewers clone the repo and run it;
  the owner records a demo video, which is the public face of the project.
- **Zero setup.** `git clone` → `flutter pub get` → `cd apps/mobile && flutter run` works with
  no env file, no `--dart-define` and no keys.
- **Fully offline.** The game works with no network at all, on every platform we run.
- **The backend is optional at runtime.** With no Supabase keys, or with keys but no network,
  every backend feature (sign-in, sync, restore, waitlist, coach) is silently off and the game
  is unaffected. No error, spinner or prompt appears because the backend is missing.
- `flutter build web --release` stays in CI **only as a compile check**. `flutter run -d chrome`
  stays a local run target.

## Consequences

- The README's run guide is three commands: clone, `flutter pub get`, `flutter run`. The
  `--dart-define-from-file` flag is shown as the optional way to turn the backend on.
- Every feature that needs the backend has a designed offline / no-backend state, and the game
  never waits on it.
- Tests prove the app boots and plays Mission 1 with an empty `Env` (every value blank).
- CI keeps the web release build as a compile check; there's no deploy job and no host secrets.
- The demo video replaces the public link for the Demos criterion. The APK on a GitHub Release
  is still the way to play on a phone without building.
- COOP/COEP and the web service worker stop mattering: there's no hosted build to configure.

## Alternatives considered

- **Vercel previews** (the earlier D3 decision, reversed). A link per PR is nice for review, but
  it costs secrets, an extra CI job and a deploy surface for little gain when reviewers run the
  code. A hosted web demo also wants cross-origin isolation headers that break fonts fetched
  from another origin and OAuth popups.
- **GitHub Pages.** No secrets, but it still means a deploy job, a base-path setup for
  go_router deep links, and a hosted build we'd have to keep working. Same gain, smaller cost,
  still not needed.
- **A required `.env` (or `env/dev.json`).** The usual setup, but every reviewer would have to
  copy a file or ask for keys before the first run, and the game would depend on a backend it
  doesn't need to be played.
