# Brief 17: Vivid UI: the tower, onboarding and progress, redeveloped (worktree w1)

Lead session, 2026-10-31. Worktree `../thelastroom-w1`, branch `feat/17-vivid-ui` from
`origin/lead/wave-5`. Session: thelastroom-1e. Read `docs/briefs/wave-5.md` first.

## Why

The owner played #16's "Morning Office" on the realme 8: **"completely white screen and grey
text, no attraction, basic UI."** The tower lists Mission 1 at the bottom, and starting a mission
takes a scroll plus two taps. Reviewers judge Design (10 pts) and Completeness on exactly these
screens. This brief **redevelops** them; it is not a re-skin.

## Owns

`packages/brand`, `apps/mobile/lib/ui/**`, `apps/mobile/lib/features/tower/**`,
`features/onboarding/**`, `features/progress/**`, and their tests and goldens. Brief 18's mission
screen and 20's title/intro use your tokens and `lib/ui`. Keep existing public names working,
or tell those sessions what changed.

## In scope

1. **A vivid visual language in `packages/brand`.** Keep #16's friendly cast and warmth, but
   replace flat white and grey with **colour and depth**:
   - rich full-bleed backgrounds: a deep chapter colour or a gradient, never plain `#FFF`;
   - one confident accent for the primary action;
   - cards with real elevation and colour;
   - text that is never mid-grey on white;
   - each chapter its own strong colour (Ch 1 welcoming, Ch 2 pressure, Ch 3 final round).
   AA contrast tests for every text pair, as today. Display type should feel like a game title
   screen, not a form.
2. **The tower, rebuilt.**
   - Chapters top to bottom, **1, 2, 3**; missions **1, 2, 3 …** inside each.
   - The **current mission is a hero card** at the top of the first screen with **one big "Play"
     button: one tap starts the mission**. No scrolling to find it, no second "Enter" then
     "Start".
   - Each chapter is a colourful card with its title, a progress ring or bar (missions done /
     total) and the interviewer's face.
   - Locked missions look locked but inviting (a teaser line, what unlocks them).
   - Done missions show their grade or stars.
   - The greeting header must never show list content bleeding through it (the overlap visible
     in the owner's screenshot).
   - The Recall Room is a clear card, even while "coming soon".
3. **Onboarding, rebuilt**: 3 short, colourful, illustrated steps:
   - what the game is;
   - meet the interviewers;
   - your name.
   Big type, motion between steps, a progress dot row, one obvious button, skip allowed. It ends
   on the tower with Mission 1 ready to play.
4. **Progress ("Your file")**: the same visual language. Skill radar and stats in colour, not
   grey lists.
5. **Motion**: entrance animations on the tower cards (staggered), a press state on every
   tappable, a shared-element or hero transition into the mission where it's cheap. Respect
   reduced motion.

## Out of scope

The mission scene (18), the title, splash and intro screens and the back button (20), and the
content (19).

## Done when

The tower, onboarding and progress on the realme 8 look like a polished mobile game:
- colour everywhere, no white-with-grey screen;
- the order reads 1 → 7 top to bottom;
- one tap from the tower to Mission 1;
- goldens updated, gates green, before/after screenshots in the PR.
