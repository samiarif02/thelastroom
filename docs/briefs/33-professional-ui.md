# Brief 33: Professional UI, one look everywhere (worktree w1)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w1`, branch
`feat/33-professional-ui` from `origin/lead/wave-6`. Session: thelastroom-de. Read
`docs/briefs/wave-6.md` first. **PR green by Tue 3 Nov, 18:00** (the first merge after 36).

## Why

The reviewer: our players are professionals looking for jobs. Today the app looks like a
children's game (dark green gradients, cartoon faces, yellow pill buttons, stars), so a
job-seeker may not take the questions seriously. And it disagrees with itself: the mission's
chapter title card (serif title, tracked caps, dark, calm) already looks professional, so the
player meets two apps. Keep the game *mechanics* (missions, progress, XP, badges, the weekly
goal): that's the Duolingo model and it stays. Change the *look* to sleek, modern and
professional, one language on every screen.

## The direction: "the title card, everywhere"

Use the chapter title card (`ui/title/chapter_title_card.dart`) as the reference for the whole
app. Think an executive-search firm's app, or Linear / LinkedIn Premium, not a quiz game.

- **Palette:** a deep ink base (near-black navy), surfaces one step lighter, hairline borders,
  **one** restrained accent (brass or a calm blue: pick one, prove it on two screens, then
  commit). Chapter colours become a thin accent (a rule, a small tag), never a whole-screen
  gradient. Make it the **default theme** ("Executive") in the theme set from brief 28; keep the
  others selectable only if they don't fight it, otherwise drop them.
- **Type:** serif display (Cormorant Garamond) for screen and mission titles, Manrope for
  everything else, tracked small caps for eyebrows: exactly the title card's pairing.
- **Components:** rectangular buttons (small radius, solid accent primary, outline secondary),
  no glowing pills; flat cards with a hairline, no heavy gradients or glows; numbers instead of
  stars ("72 / 100" with a thin bar); restrained icons, one weight.
- **The interviewer:** the cartoon faces are the loudest "game" signal. Replace them with a
  refined portrait that matches the title card: the rim-lit silhouettes already in the film kit
  (`ui/figure/`), or a flat, adult, geometric portrait. No big cartoon eyes. Same choice on the
  tower, onboarding and in the mission.
- **Motion:** keep the film language (letterbox, typewriter, the dossier) but calmer: shorter,
  smaller, no bounces. Reduced motion still cross-fades.
- **Copy tone:** professional and warm. "Play" → "Start", "Your file" stays, no exclamation
  marks, no "Niiice".
- **What you learn (owner's "think from the user's side"):** show `Mission.practises` (the new
  contract field) on the tower's "Up next" card and on the mission card before the scene:
  "You'll practise: …".

## In scope

Every screen a player sees, in this order of importance: the tower (home), the mission scene and
answer cards, the debrief (visual side only, see wave-6 for the shared file), onboarding, the
title/intro, Your file (progress, radar, badges), the Recall Room, settings, the splash and the
web loader. Update `DESIGN.md`'s "Chosen direction" with the new direction and why (the
reviewer's words), and the goldens.

## Out of scope

The game rules, scoring, content (except reading `practises`), the voice mission's screens
(35 adopts your look after you merge), the landing page (34 will copy your palette and type:
put the tokens in `DESIGN.md` so they can).

## Acceptance

- [ ] Side by side, the tower, a mission and the debrief read as one product, as calm as the
      title card. Before/after stills of each screen in `.pr-screenshots/33/`.
- [ ] No cartoon faces, no stars, no pill-shaped glowing buttons anywhere.
- [ ] `practises` shows before each mission.
- [ ] AA contrast tests pass for every pair; 48 dp targets; 2x text and reduced motion pass;
      goldens redrawn.
- [ ] All gates green, CI green, `docs/status/33.md` current. Message thelastroom-w4-fe with
      the PR link.
