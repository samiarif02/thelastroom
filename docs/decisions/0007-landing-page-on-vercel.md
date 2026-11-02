# 0007. A static landing page in `web/`, hosted on Vercel

- **Status:** accepted (2026-11-02)
- **Relates to:** [0005](0005-zero-setup-offline-backend-optional.md) (no hosted web demo of the
  game), which this does not change

## Context

The reviewer asked for a marketing landing page (wave 6): what The Last Room is, how it works,
"coming soon on Google Play and the App Store", in its own `web/` folder so it deploys on Vercel
by choosing that folder. ADR 0005 dropped the hosted web demo of the *game*: a hosted Flutter
build needed repository secrets, a deploy job, a `vercel.json` and cross-origin isolation
headers, all for a link reviewers who clone the repo don't need. A page that tells people about
the game is a different thing with a different cost.

## Decision

- **A static Next.js site in `web/`** (App Router, TypeScript strict, ESLint with
  `--max-warnings=0`, `output: 'export'`). `next build` writes plain HTML, CSS and images to
  `web/out/`. That is 8x's own web stack, so 8x's web standards apply as written.
- **Nothing server-side and nothing secret.** No API routes, no environment variables, no
  analytics, no forms, no cookies. The fonts (Cormorant Garamond and Manrope, the app's pair)
  are downloaded at build time by `next/font` and served from the site itself.
- **Vercel hosts it from its own Git integration**: the owner imports the repository once and
  sets the root directory to `web` (`web/README.md`). Vercel builds every push itself, so the
  repository holds **no Vercel token or secret** and CI has **no deploy job**.
- **CI checks it like the rest of the repo**: a `web` job (Node 22: `npm ci`, lint, typecheck,
  build), mirrored in the `local-review` skill and enforced by `check:standards`.
- The game itself stays exactly as ADR 0005 decided: zero setup, fully offline, not hosted.
  `flutter build web` stays a compile check only.

## Consequences

- People who will never clone the repo have somewhere to land, and the store listings will have
  a URL to point at.
- `web/` is a second toolchain (npm and Node) beside Flutter. It has its own `package.json` and
  lockfile and never touches `apps/`, `packages/` or `supabase/`; the root `package.json` still
  has no npm dependencies.
- The site's URL is one constant, `site.url` in `web/src/content/site.ts` (canonical link, Open
  Graph, sitemap), set once the Vercel project has its domain.
- The copy follows the honesty rule (`docs/rules/analytics.md`): no invented users, ratings,
  testimonials or numbers, and the scoring section says what the score doesn't do.

## Alternatives considered

- **No landing page.** Keeps one toolchain, but leaves the store listings and the reviewer's
  request without an answer.
- **A page inside the Flutter web build.** One codebase, but it reintroduces the hosted Flutter
  web build ADR 0005 dropped, ships a multi-megabyte engine for a page of text, and does poorly
  on SEO and Lighthouse.
- **GitHub Pages from a CI deploy job.** No third-party account, but it adds a deploy job and a
  base path; Vercel's Git integration deploys with no job and no secret, which is what the
  reviewer asked for.
- **Tailwind CSS.** Fast to write, but CSS modules with custom properties need no extra
  dependency and keep every colour in one token block, the same discipline as `packages/brand`.
