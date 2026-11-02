# Brief 34: Marketing landing page (Next.js, `web/`) (worktree w3)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w3`, branch
`feat/34-landing-page` from `origin/lead/wave-6`. Built by a background agent of
thelastroom-w4-fe. Read `docs/briefs/wave-6.md` first. **PR green by Tue 3 Nov, 22:00.**

## Why

The reviewer: a marketing page adds value and shows we think about how people find the app.
Simple, beautiful, honest: what The Last Room is, how it works, and "coming soon on Google Play
and the App Store". It lives in this repo in its own `web/` folder, so the owner deploys it on
Vercel by choosing `web` as the root directory.

## Stack and architecture

- **Next.js** (App Router, latest stable), **TypeScript strict**, ESLint with
  `--max-warnings=0`, **static export** (`output: 'export'`): no server, no secrets, no
  environment variables. That's 8x's own web stack, so the 8x standards apply as written.
- Plain CSS modules or Tailwind, your call; say why in the PR. Fonts self-hosted with
  `next/font` (Cormorant Garamond + Manrope, the app's pair). The palette comes from
  `DESIGN.md`'s professional direction (brief 33); until it lands, use the title card's ink,
  brass and serif.
- Components in `web/src/components/`, content (copy) in one typed file so wording changes don't
  touch layout, sections composed in `web/src/app/page.tsx`. Metadata, Open Graph image, favicon,
  `robots.txt`, `sitemap.xml`. Lighthouse ≥ 95 on performance, accessibility, SEO.
- `web/README.md`: run, build, deploy on Vercel (root directory `web`, framework Next.js).
- **ADR 0007** (`docs/decisions/0007-landing-page-on-vercel.md`): why a hosted marketing page is
  fine while ADR 0005 keeps the game zero-setup and unhosted.
- **CI:** a `web` job (Node 22: `npm ci`, lint, typecheck, build) in
  `.github/workflows/ci.yml`, mirrored in `.claude/skills/local-review/SKILL.md` so
  `check:standards` (`local-review-mirrors-ci`) stays green. `node_modules` and `.next`/`out`
  ignored.

## The page (sections)

1. Hero: the name, one line ("Practise the interview before the one that counts"), a still of
   the app, "Coming soon on Google Play · App Store" (text buttons, not Apple's or Google's
   badges: their brand rules), and "Get the Android preview" linking the GitHub Release.
2. How it works: a mission in three steps (hear the question, build or speak your answer, get a
   scored debrief with one lesson).
3. Why it works: the learning (each mission names what you practise; the Recall Room brings
   lessons back on day 1, 3 and 7; your score against your first try).
4. How we score: the four dimensions and their weights, the AI recruiter's one-line basis per
   number, the offline engine; link the README section. Honest: say what it doesn't do.
5. Privacy: no sign-up, your words stay on your phone, voice isn't stored.
6. Footer: GitHub, the privacy line, © 2026.

**Honesty rule** (docs/rules/analytics.md): no invented users, testimonials, ratings or
numbers.

## Owns

`web/**` (new), the CI `web` job and its local-review mirror, ADR 0007, `.gitignore` lines,
`docs/status/34.md`. Nothing in `apps/`, `packages/` or `supabase/`.

## Acceptance

- [ ] `cd web && npm ci && npm run build` produces a static site; `npm run lint` and
      `npm run typecheck` clean.
- [ ] Looks right at 390, 768 and 1440 px wide; stills of each in `.pr-screenshots/34/`.
- [ ] Every root gate and the new `web` job green in CI. Never merge.
