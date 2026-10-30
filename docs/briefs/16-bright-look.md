# Brief 16: A brighter, friendlier look: three options, then the owner's pick (worktree w1)

Written by the lead session, 2026-10-30 (Fri), after the owner's first play and a feedback
session. Worktree `../thelastroom-w1`, branch `feat/16-bright-look` (from `main` with 06a, 06b,
07, 10). **Timebox: options on the phone by Sat 31 Oct, 11:00, so the owner picks by noon; the
chosen look merged by Sat evening.**

## Why

The owner played Chapter 1 on a phone and ran a feedback session. The animations, the film
pieces and the candidate-file screens are loved ("the candidate assessment and candidate file
screens are our best"). But the dark walnut look reads as **James Bond / a CID investigation**:
Priya as a dark silhouette in a spotlight feels like an interrogation, not a friendly practice
room. Reviewers asked for a UI that is **beautiful and attractive enough to show clients**, and
**engaging enough that players come back every day**.

So: keep every animation, component and screen; change the **palette** and the **interviewer's
character** to something colourful, warm and friendly. Because every colour is a brand token
(`packages/brand`), most of this is a re-skin.

Read first: `DESIGN.md` (chosen direction and the 03 comparison), brief §9, `docs/rules/components.md`,
`packages/brand`, `apps/mobile/lib/ui/` (especially `figure/`), the dev catalog.

## In scope

1. **Three bright, friendly options**, each genuinely different (not three shades of one idea).
   Each has: a name; the mood in one line; a palette (hex) with **AA contrast results** for every
   text pair; three chapter grades that still climb in tension (Chapter 1 welcoming, Chapter 2
   more pressure, Chapter 3 the big final round) without going dark and grim; and a note on how
   the tower, the scene, the answer cards and the dossier look in it. Starting points, not
   orders:
   - **Morning office**: daylight, warm cream and soft colour, plants and glass, optimistic.
   - **Bold and playful**: saturated, confident colour blocks, game-like (Duolingo energy), still
     grown-up enough for a career app.
   - **Sunset city**: warm gradients (peach, coral, violet), the tower at golden hour, cinematic
     but inviting.
   Typography: keep Cormorant Garamond + Manrope as the default. One option may propose a
   friendlier OFL pair, bundled (never Playfair, Bebas, Montserrat or Poppins).
2. **A friendly interviewer, drawn in code** (D2 stays "drawn in code", the owner now wants it
   friendly, not a silhouette): a simple, warm illustrated person with a face and
   **expressions**: neutral, smile, thinking, a small nod, and a "hmm" for the follow-up. Idle:
   breathing, blinking. Priya first; the same system makes Marcus and Lena distinct (hair, skin
   tone, clothing, accessories). Respect every interviewer: no caricature. The rim-light and
   subtitle-clear-of-face rules from brief 10 still hold.
3. **`/dev/looks`** (not in release builds): switch between the three options live on the real
   screens: title, an onboarding card if brief 13 has merged, Priya's scene with the answer
   cards, the follow-up, the dossier and candidate file, and (if merged) the tower. Each option is
   a theme built from tokens, so the switch is instant.
4. **Recommendation** in the PR and `DESIGN.md`: which option and why, judged against "beautiful
   enough to show clients" and "makes me want to open it tomorrow".
5. **After the owner's pick:** make the chosen option the app's real tokens and character
   (replace the Boardroom tokens and the silhouette), delete the other two, update goldens and
   `DESIGN.md` "Chosen direction", in the same PR.

## Out of scope

- New screens or flows (brief 13 builds onboarding, the tower and progress). Sound (09).
- Changing motion or layout beyond what a new palette or character needs.

## File ownership

- `packages/brand/**`, `apps/mobile/lib/ui/**`, `apps/mobile/lib/features/dev_looks/**` (new),
  `apps/mobile/lib/features/dev_catalog/**`, goldens and their tests, `DESIGN.md`,
  `docs/status/16.md`, `.pr-screenshots/16/**`, your own `.claude-logs/` files.
- Shared: one `/dev/looks` line in `router.dart` (brief 13 owns it; the lead resolves at merge).

**Not yours:** `features/{onboarding,tower,progress,intro,mission,debrief}` (brief 13 is changing
them; they must keep working because they only use tokens and components),
`core/**`, `packages/{engine,content}`, `supabase/`, pubspecs (ask for a font package change),
CI, `scripts/`, the events registry, `AGENTS.md`, `docs/HANDOFF.md`, `docs/requirements.md`.

## Acceptance criteria

- [ ] `/dev/looks` shows the three options on the real screens, on the OnePlus 9 and in Chrome.
- [ ] AA contrast tests pass for every text pair in every option, including text over colour.
- [ ] The interviewer has at least five expressions and an idle; Priya, Marcus and Lena are
      distinct; reduced motion stops the idle.
- [ ] PR before the pick: per option, compressed stills (≤ 300 KB) of title, scene with cards,
      follow-up and dossier, plus one ≤ 20 s phone recording; a comparison table.
- [ ] After the pick: the app uses the chosen look everywhere, goldens updated, the Boardroom
      tokens and the silhouette removed, `DESIGN.md` updated.
- [ ] All local-review gates green; CI green; `docs/status/16.md` current.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/16.md`: done, half-done, next.
- The **OnePlus 9** is yours (`adb -s 96239c4a`); the realme is the lead's.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link and the
  comparison table.
