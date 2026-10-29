# Brief 03: Cinematic direction (wave 1, worktree w1)

Written by the lead session, 2026-10-29 (Thu). Worktree `../thelastroom-w1`, branch
`feat/03-cinematic-direction`. **Timebox: PR up by Fri 30 Oct, 11:00**, so the owner picks by noon.

## Goal

The current look is cheap and basic: a centred title on a gradient in a fallback font. The owner
wants it **modern, stylish and cinematic**. Build **three genuinely different directions** as
throwaway prototypes the owner can compare side by side on a phone and in Chrome, recommend one
and say why. The owner picks; you then write the chosen direction into `DESIGN.md`. The real
design system is brief 06, so this is about choosing well, fast.

Read first: brief §9 (`docs/product-brief.md`), `DESIGN.md`, `docs/rules/components.md`,
`docs/rules/code-quality.md`, ADR 0005 if merged (otherwise: the rule below).

## Hard rules

- **Zero setup** (owner, 2026-10-29): `cd apps/mobile && flutter run` and `flutter run -d chrome`
  work from a fresh clone with **no keys, no env file, fully offline**. So the fonts are
  **bundled files**, never `google_fonts` or any runtime fetch.
- **Fonts, exactly these pairs** (owner's choice), one per direction:
  - **A:** Instrument Serif (display) + Geist (body)
  - **B:** Big Shoulders Display (display) + Inter Tight (body)
  - **C:** Cormorant Garamond (display) + Manrope (body)
  - **Banned:** Playfair, Bebas, Montserrat, Poppins (and Roboto, which is what shows today).
  All six are SIL OFL. Bundle only the weights you use (static TTFs, or variable with
  `FontVariation`), each with its `OFL.txt`, and credit them in `DESIGN.md`.
- No raw colours outside `packages/brand` (`check:standards` enforces it). No stock Material:
  no AppBar, ListTile, Card, ripple, default blue, default page transitions.

## In scope

1. **Three directions**, each with: a name; the mood in one line; a palette (hex) with **AA
   contrast results** for every text pair (extend `packages/brand/lib/src/contrast.dart`'s
   tests); the display + body pairing above with sizes, tracking and tabular numerals for scores;
   the three chapter grades (Ch1 warm amber lobby, Ch2 cold steel blue, Ch3 oxblood and gold) as
   that direction interprets them; and a paragraph on how the tower, the elevator, the spotlight
   and the dossier would look in it.
   They must differ in more than fonts: composition, texture (grain, glass, paper), motion
   vocabulary and how the light behaves. Starting points, not orders:
   A = quiet glass-and-night minimalism (Severance, A24 title cards); B = bold condensed
   neo-noir, big type as architecture (Fincher titles); C = warm, expensive boardroom drama
   (Succession).
2. **A prototype per direction at `/dev/directions`** (a picker, then each direction). Each one
   shows **three frames** of Mission 1 ("The Opportunity", interviewer Priya), composed like
   film stills:
   - **Title card:** "CHAPTER ONE — GET THROUGH THE DOOR", with the slow fade and tracking-in.
   - **Scene:** letterbox bars sliding in, Priya in a spotlight (a stylised figure or silhouette
     drawn in code; no stock photos, no AI images yet), a typewriter subtitle with her name in
     small caps (tap to complete), then the bars retract for **three answer cards**.
   - **Dossier:** the debrief file sliding onto the desk, four dimension scores stamped, one
     red-pen note.
   Plus the global grain + vignette. Fake data is fine; the engine isn't needed.
3. **Motion:** each direction has at least the letterbox, the typewriter and one camera cut, with
   eased, weighty curves. **Reduced motion** swaps camera moves for a cross-fade.
4. **A recommendation** in the PR and in `DESIGN.md`: which one, and why, against brief §9's bar
   ("someone should screenshot it because it looks like a film").
5. **After the owner picks** (in the PR conversation), add a "Chosen direction" section to
   `DESIGN.md` in the same PR: palette, type scale, grades, motion principles, what 06 builds.
   Also propose **D2** (interviewer portrait art: commission, Rive or AI images with rights)
   with a recommendation for the chosen direction.

## Out of scope

- The design system itself, goldens, `/dev/catalog`, icons, launch screens (all 06).
- Real screens, real routes beyond `/dev/directions`, the engine, any backend.
- Changing existing brand tokens that other code uses. Add the prototype palettes beside them
  (e.g. `packages/brand/lib/src/directions/`); 06 replaces them with the winner.

## File ownership (parallel wave: touch only these)

- `apps/mobile/lib/features/dev_directions/**` (new)
- `apps/mobile/lib/app/router.dart` (add `/dev/directions`, **not registered in release builds**)
- `apps/mobile/lib/app/app.dart` (only if needed)
- `apps/mobile/test/features/dev_directions/**` (new)
- `packages/brand/**` (fonts, `pubspec.yaml` font declarations, prototype tokens, contrast tests)
- `DESIGN.md`, `docs/status/03.md`, `.pr-screenshots/03/**`, your own `.claude-logs/` files

**Not yours** (others own them this wave; if you need a change, write it in `docs/status/03.md`
and tell the lead): `apps/mobile/pubspec.yaml`, `pubspec.lock`, `main.dart`, `providers.dart`,
the events registry and `docs/EVENTS.md`, CI, `package.json`, `scripts/`, `packages/engine`,
`packages/content`, `supabase/`, `AGENTS.md`, `docs/HANDOFF.md`, `docs/requirements.md`.
If adding fonts to `packages/brand/pubspec.yaml` changes `pubspec.lock`, stop and tell the lead.

## Acceptance criteria

- [ ] `/dev/directions` shows A, B and C, each with the three frames, on the OnePlus 9 (debug
      run) and in Chrome. The route doesn't exist in a release build (a test proves it).
- [ ] Fresh-clone check: with no `env/dev.json`, `flutter run -d chrome` shows the directions
      with the right fonts and **no network requests for fonts** (DevTools network tab, or run
      with the network off).
- [ ] Widget test: each direction's frames render without overflow at 375×667 and at 2x text.
- [ ] AA contrast tests pass for every text pair in every direction.
- [ ] PR has **9 screenshots** (3 directions × title, scene, dossier) on the phone, the same 9 in
      Chrome, and **one recording per direction** (≤ 20 s, `adb shell screenrecord` on the
      OnePlus 9: `adb -s 96239c4a ...`), as a comparison table.
- [ ] Recommendation stated with reasons; after the owner's pick, `DESIGN.md` "Chosen direction"
      written and the losing directions' fonts listed for 06 to delete.
- [ ] All local-review gates green; CI green; `docs/status/03.md` current.

## Events

None. `/dev/directions` is a dev tool and fires nothing.

## How to work

- Never edit `docs/HANDOFF.md` (parallel mode). Keep `docs/status/03.md`: done, half-done, next,
  so another profile can resume.
- Don't run Gradle, the iOS simulator and an emulator at once; other workers share this Mac.
  Use the OnePlus 9, not the emulator.
- Own branch, local-review, PR, CI green, never merge. End with the PR link and the screenshots.
