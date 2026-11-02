# The Last Room: landing page

The marketing page for The Last Room, in the **Daylight Tower** look
([`docs/design/direction.md`](../docs/design/direction.md), "The landing page"): the four
interviewers drawn as people who react, the game playing on a phone in the hero, the three
floors, how the score works with its published evaluation, a plain FAQ and one call to action
(the free Android preview). A static Next.js site: no server, no secrets, no environment
variables ([ADR 0007](../docs/decisions/0007-landing-page-on-vercel.md)). The game itself is in
`apps/mobile/` and isn't hosted ([ADR 0005](../docs/decisions/0005-zero-setup-offline-backend-optional.md)).

## Run it

Node 22 or later.

```bash
cd web
npm ci
npm run dev          # http://localhost:3000
```

## Check and build

The same commands CI's `web` job runs:

```bash
npm run lint         # ESLint, --max-warnings=0
npm run typecheck    # next typegen && tsc --noEmit (strict)
npm run build        # static export to web/out/
```

`out/` is plain HTML, CSS and images. To look at the exported site:
`npx serve out` (any static file server works).

## Where things are

```
src/app/            layout (fonts, metadata, FAQ schema), page (composition only), privacy/,
                    terms/, not-found (the branded 404), robots, sitemap, icon.svg,
                    opengraph-image.jpg (+ its alt text), globals.css (tokens and text styles)
src/cast/           the interviewers as inline SVG: people.ts (colours, the seven expressions),
                    Figure.tsx (the drawing), Figure.module.css (blends, breath, sway, blinks)
src/components/     one component per section, each with its CSS module; phone/ holds the
                    app's screens drawn in HTML at 390 × 844 and scaled into a phone
src/content/site.ts every word on the page, typed; change copy here, not in components
```

- **Look**: warm paper grounds, the floors' colours (green, blue, raspberry) as solid blocks,
  one action colour (honey, the primary button only), and dark only for the top floor at dusk
  (the final call to action). The arched window is the one motif: the logo, the portraits, the
  floors' screens, the 404. Colours are the custom properties at the top of
  `src/app/globals.css`, mirroring `packages/brand`; components never write a raw colour
  (the cast's illustration fills live in `src/cast/people.ts`). Every text pair is AA or better;
  the figures are in the comment there.
- **Type**: Bricolage Grotesque 600 for display, Geist 400/500/600 for reading, both SIL OFL,
  through `next/font/google`: downloaded at build time and served from the site, so a visitor's
  browser never calls Google (the build needs network access). Every size is a named text style
  (`heading-1` … `caption-4`) on the Tailwind scale; spacing and radii come from the
  landing-page-design skill's scales.
- **The cast** is a port of `docs/design/mockups/shared/cast.js`, the source of truth in the
  design direction, with the same geometry. When `packages/brand/assets/cast/cast.json` lands,
  `src/cast/people.ts` should read from it so the app and the site can't drift.
- **Motion** (only transform and opacity, the base curve `cubic-bezier(0.22, 1, 0.36, 1)`):
  the hero phone plays room 4 on a loop (`HeroDemo`, pausable, paused off screen; under reduced
  motion it rests on one frame until played), sections rise in once as they scroll in, the
  tagline lights word by word, and the interviewers breathe, sway, blink and react on hover
  (`PageMotion`, `Figure.module.css`). Nothing is hidden at rest: without JavaScript, or with
  reduced motion, everything shows. The idle starts after the load event, off the first paint.
- **Honesty**: no invented users, ratings, testimonials or numbers (`docs/rules/analytics.md`).
  Every figure is one the game's content, engine or `docs/scoring-eval.md` states, and every
  interviewer's line is one they say in the game. The hero's 82, its four dimensions and the
  91 XP are the offline engine's for room 4's strongest play.
- **The site's URL** is `site.url` in `src/content/site.ts` (canonical link, Open Graph,
  sitemap): Vercel's production address at build time, `https://thelastroom-ten.vercel.app` locally.

## Deploy on Vercel

The owner does this once; after that Vercel deploys every push by itself. Nothing in this
repository holds a Vercel token, and CI has no deploy job.

1. On [vercel.com](https://vercel.com), **Add New… → Project** and import the
   `samiarif02/thelastroom` repository.
2. **Root Directory:** `web` (Edit → pick the `web` folder).
3. **Framework Preset:** Next.js (detected). Leave the build command (`next build`), the
   install command (`npm install`) and the output settings as they are: with
   `output: 'export'`, Vercel serves the static export.
4. **Environment variables:** none.
5. **Deploy.** The production branch is `main`; every other branch and PR gets a preview URL.
6. Nothing to change afterwards: the site reads its own production address from Vercel at build
   time (`VERCEL_PROJECT_PRODUCTION_URL`), so the canonical link, Open Graph image and sitemap
   point at whatever address Vercel gives the project, free `*.vercel.app` or a custom domain.

Optional: under **Settings → Git → Ignored Build Step**, use
`git diff --quiet HEAD^ HEAD -- .` so Vercel only rebuilds when `web/` changes.
