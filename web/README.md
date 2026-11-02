# The Last Room: landing page

The marketing page for The Last Room: what the game is, how a mission works, how the score
works, privacy, and "coming soon on Google Play and the App Store". A static Next.js site:
no server, no secrets, no environment variables
([ADR 0007](../docs/decisions/0007-landing-page-on-vercel.md)). The game itself is in
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
src/app/            layout (fonts, metadata), page (composition only), robots, sitemap,
                    icon.svg, opengraph-image.jpg (+ its alt text), globals.css (the tokens)
src/components/     one component per section or piece, each with its CSS module
src/content/site.ts every word on the page, typed; change copy here, not in components
public/screens/     stills from the app (docs/screenshots/ and .pr-screenshots/35/), status bar
                    cropped, 480 px wide, compressed
```

- **Identity**: "wayfinding", shared with the app. The page is Northstar Labs' building: the
  lobby's directory board (21 rooms on three floors, the last room at the top, each row a link),
  then a section per floor with its colour band and sign, the Recall Room, the notice board
  (scoring) and the house rules (privacy). The lift's floor indicator in the header rolls to
  the floor you've scrolled to (`LiftIndicator`, the page's only client component;
  with reduced motion it changes without rolling).
- **Colours** are the custom properties at the top of `src/app/globals.css`: petrol ground,
  concrete text, slate, one action colour (lift-button amber, the primary call to action only)
  and a colour per floor (teal, signal blue, oxblood). Components use the roles (`--fg`,
  `--muted`, `--tone`…), never a raw colour; `.light` flips them for the notice board. Every
  text pair is AA (4.5:1) or better; the figures are in the comment there.
- **Fonts**: Overpass (display), Atkinson Hyperlegible (text) and Overpass Mono (labels and
  numbers), all SIL OFL, through `next/font/google`, one weight each to stay inside the mobile
  performance budget. They're downloaded at build time and served from the site, so a visitor's
  browser never calls Google. The build needs network access for that.
- **Honesty**: no invented users, ratings, testimonials or numbers (`docs/rules/analytics.md`).
  Every figure on the page (weights, intervals, thresholds) is one the game's code states.
- **The site's URL** is `site.url` in `src/content/site.ts` (canonical link, Open Graph,
  sitemap): Vercel's production address at build time, `https://thelastroom.vercel.app` locally.

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
