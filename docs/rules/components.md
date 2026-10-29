# Components and design

The UI is the headline of this project (brief §9): **someone should screenshot it because it
looks like a film, not like an app.** These rules keep it that way as the app grows. The
direction and tokens are in `DESIGN.md`.

## Tokens only

- Every colour, chapter grade, text style, spacing value, radius, duration and curve comes from
  `packages/brand`. **No raw colours outside it**: `check:standards` (`brand-tokens-only`) fails
  on `Color(0x…)`, `Color.fromARGB`/`fromRGBO` and `Colors.*` in the app, engine and content.
- Deriving a variant from a token is fine (`grade.key.withValues(alpha: 0.2)`); a new base
  colour is a new token, added in `packages/brand` with a contrast test.
- The current chapter's `ChapterGrade` re-tints the UI. Screens read the grade; they don't
  hard-code the amber.

## No stock Material look

No `AppBar`, `ListTile`, `Card`, `FloatingActionButton`, `ElevatedButton`, default `Dialog`,
`SnackBar`, ripple or default blue on screen. Build our own components in
`apps/mobile/lib/core/ui/` (or `packages/brand` if they're pure styling): a choice card, a
subtitle line, a letterbox, a spotlight, a dossier. The theme removes ripples and stock page
transitions as a safety net, not as the design.

## Every state is designed

Each screen has designed **loading, empty, offline and error** states, in the same cinematic
language. A `CircularProgressIndicator` on a blank screen is not a loading state.

## Accessibility (non-negotiable)

- WCAG AA contrast, including text over imagery (use scrims). Token pairs are contrast-tested in
  `packages/brand/test`.
- **44 pt minimum targets** (`BrandSpace.minTarget`).
- Text survives 2x scaling: test it (see the placeholder screen's test).
- **Reduced motion** (`MediaQuery.disableAnimationsOf`) swaps every camera move, parallax and
  particle effect for a short cross-fade (`BrandMotion.reducedMotionFade`).
- Semantics: headers, button labels, and the game's state announced to screen readers.

## Motion with a purpose

Every animation tells the player what happened. Eased, weighty curves from `BrandMotion`, no
bouncy springs. Haptics on choice, stamp and unlock.

## Performance

60 fps on a mid-range Android. `RepaintBoundary` around grain, particles and meters; blur only
small regions; precache scene images before the elevator opens. Profile new scenes in
`--profile` mode before the PR.

## Proof

Golden tests for every key screen and state, a `/dev/catalog` route showing every component in
every state, and before/after screenshots in every UI PR.
