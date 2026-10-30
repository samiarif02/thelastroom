# Brief 06: Design system + cinematic layer, The Boardroom (wave 2, worktree w1)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w1`, branch
`feat/06-design-system`. **Two PRs** (owner, 2026-10-30): **06a merged by Sat 31 Oct morning**
(PR up by **Fri 30 Oct, 22:00**), then 06b. 06a is the critical path: brief 10 (the mission
player) starts on it straight away.

## Goal

Turn the chosen direction into the real system. When this merges, the app opens on a Boardroom
title card that looks like a film, every film-kit component exists in `/dev/catalog` in every
state with goldens, and no Material default or runtime fetch is left anywhere.

Read first: `DESIGN.md` "Chosen direction: C, The Boardroom" (**that section is your spec**) and
"C · The Boardroom", brief §9, `docs/rules/components.md`, `docs/rules/code-quality.md`,
ADR 0005, and `apps/mobile/lib/features/dev_directions/` (the prototype you're promoting).

## Two PRs: 06a first, then 06b (owner, 2026-10-30)

So Mission 1 is playable by Sunday, not Monday, this brief ships in two PRs. Items below refer
to "In scope".

**06a: the foundation brief 10 builds on** (this branch, PR up by Fri 22:00, small):
- Item 1 (tokens, theme, AA tests) and item 2 (delete the losing fonts and direction files;
  keep `features/dev_directions/` until 06b's catalog replaces it).
- From item 3, the **core film kit** the mission player needs, each with widget tests (no
  goldens yet): grain + vignette, letterbox, typewriter subtitle with `onCharacter`, camera rig
  (dolly push + black-frame hard cut), spotlight / banker's lamp, rim-lit silhouette with idle,
  answer card (all five states), chapter title card, dossier with stamped scores, wax seal and
  pen note.
- Item 6 (the Boardroom title card as home) and the "THROU / GH" fix from item 7.
- A **public API note** in the PR: each component's constructor and callbacks, so brief 10 can
  start before reading the code.

**06b: the rest** (a new branch `feat/06b-catalog-platform` from `main` after 06a merges; the
lead creates it): item 4 (cinematic loading/empty/offline/error states), item 5 (`/dev/catalog`,
goldens, reduced-motion and 2x toggles; then delete `features/dev_directions/`), the
edge-to-edge part of item 7, item 8 (no runtime fetch on the web), item 9 (icons, launch
screens), the profile-build jank check. Components brief 10 is already using must keep their
public API; additions only.

Acceptance: 06a meets the criteria below that cover its items (fonts, AA, title never breaks a
word, zero setup, gates, compressed screenshots of the title card and the components); 06b
meets the rest.

## 06b changes (owner, 2026-10-30, after 06a merged as PR #10)

You're on `feat/06b-catalog-platform` (from `main` with 06a and 07 merged). Two things moved:

- **Edge to edge is now brief 10's** (the owner wants it in the mission player now), including
  `app.dart`'s system UI and the Android `styles.xml`. Don't touch those.
- **`ui/figure/silhouette_figure.dart` and `ui/figure/interviewer_silhouette.dart` are brief 10's**
  this wave (it fixes a stray rim-light dot). Leave them alone.

Brief 10 (w2) and brief 09 (sound, w4) run in parallel with you. Components 10 uses keep their
public API; additions only. 09 adds one `/dev/sound` route and the `flutter_soloud` script tags to
`web/index.html`; keep the dev routes a simple list.

## Hard rules

- Zero setup (AGENTS.md non-negotiable 6): `flutter run` / `flutter run -d chrome` from a fresh
  clone, no keys, **no network request at all** (fonts, Roboto fallback, CanvasKit all local).
- No raw colours outside `packages/brand`; no stock Material (AppBar, ListTile, Card, ripple,
  default transitions, default blue).
- Every animation has a reduced-motion cross-fade. 44 pt targets. Survives 2x text.

## In scope

1. **Tokens** in `packages/brand` from `directions/boardroom.dart`: palette, the three chapter
   grades, type ramp (tabular lining figures), spacing, radii, motion durations and curves.
   Replace the foundation placeholders; `BrandTheme` built from them. AA tests for every pair.
2. **Delete the losers:** `instrument_serif/`, `geist/`, `big_shoulders_display/`,
   `inter_tight/` fonts and pubspec entries, `directions/night_glass.dart`,
   `directions/concrete_noir.dart`, and `features/dev_directions/` once the catalog replaces it.
3. **The film kit as real components** in `apps/mobile/lib/ui/` (promoted and cleaned up from
   the prototype's `shared/`): grain + vignette overlay, letterbox, typewriter subtitle (with a
   per-character callback hook for sound, see "Seam for 09"), camera rig (dolly push with
   parallax, plus the black-frame hard cut for follow-ups), spotlight / banker's lamp, bokeh,
   paper dossier with stamped scores and wax seal, fountain-pen note, answer card (idle,
   focused, selected, locked, disabled), chapter title card, the rim-lit silhouette with a
   code-driven idle (breath, slow head turn, lamp flicker on the rim): **D2 confirmed by the
   owner, 2026-10-30**. Each is `RepaintBoundary`-wrapped where it animates.
4. **States are cinematic too:** loading, empty, offline ("The lights are out. Your progress is
   safe on this device."), error. Components for each, in the catalog.
5. **`/dev/catalog`** (not in release builds): every component in every state, with a reduced-
   motion toggle and a 2x-text toggle. **Golden tests** for each component's key states.
6. **The app's home** becomes the Boardroom title card (replacing `features/placeholder`), so a
   fresh `flutter run` already looks like the film.
7. **Fix the bugs found on the phone** (DESIGN.md "Known issues"): the title's tracking-in must
   never break a word ("THROU / GH"); draw **edge to edge** on Android (no black status/nav bands).
8. **No runtime fetch on the web:** `fontFallbackBaseUrl` to a local path in `web/index.html`
   (the engine stops fetching Roboto) and `--no-web-resources-cdn` in `package.json`'s
   `build:web`. Prove it with a network log.
9. **Brand the platform edges:** app icons (brass monogram on walnut) and native launch screens
   on Android (incl. the Android 12+ splash) and iOS, web favicon/icons and `manifest.json`.

## Out of scope

- Real game screens (mission player is 10; tower, Recall Room, report are 13). Sound (09).
- Painterly portraits (stretch goal, not v1).

## Seam for 09 (sound)

Brief 09 builds `AudioService` with named cues in parallel. Don't import it. Give the typewriter
an optional `onCharacter(String char, int index)` callback and the camera rig / stamp / dossier
optional `onBeat` style callbacks, so brief 10 can wire sound without editing your components.

## File ownership (parallel wave: touch only these)

- `packages/brand/**`, `apps/mobile/lib/ui/**` (new), `apps/mobile/lib/features/title/**` (new),
  `apps/mobile/lib/features/dev_catalog/**` (new), delete `features/dev_directions/**` and
  `features/placeholder/**`, `apps/mobile/lib/app/app.dart`, `apps/mobile/lib/app/router.dart`
- `apps/mobile/test/ui/**`, `apps/mobile/test/features/{title,dev_catalog}/**`, goldens
- `apps/mobile/android/app/src/main/res/**`, `AndroidManifest.xml`, `MainActivity.kt`,
  `apps/mobile/ios/Runner/Assets.xcassets/**`, `LaunchScreen.storyboard`, `Info.plist`
- `apps/mobile/web/**` (index.html, icons, manifest), `package.json` (`build:web` only)
- `DESIGN.md`, `docs/status/06.md`, `.pr-screenshots/06/**`, your own `.claude-logs/` files

**Shared this wave (the lead resolves at merge):** brief 09 adds one `/dev/sound` line to the
dev routes in `router.dart` and two script tags to `web/index.html`. Keep the dev routes a
simple list so those merge cleanly.

**Not yours:** `apps/mobile/pubspec.yaml` and `pubspec.lock` (08 and 09 add packages; if you need
one, ask the lead first), `main.dart`, `providers.dart`, `core/**`, `packages/engine|content`,
`supabase/`, CI, `scripts/`, the events registry, `AGENTS.md`, `docs/HANDOFF.md`,
`docs/requirements.md`.

## Acceptance criteria

- [ ] Fresh clone, no env file: `flutter run -d chrome` shows the Boardroom title card with
      **zero** cross-origin requests (network log in the PR), and the same on the phone.
- [ ] Only Cormorant Garamond and Manrope remain; the four losing families are gone.
- [ ] `/dev/catalog` shows every component in every state; absent from release (test).
- [ ] Goldens for every component's key states; AA tests for every pair; 2x text and reduced
      motion tested.
- [ ] Edge to edge on Android; branded icon and launch screen on Android, iOS and web.
- [ ] The title never breaks a word at any moment of its animation (test).
- [ ] Profile build on the OnePlus 9: no jank in the catalog's animated components (DevTools
      frame chart screenshot).
- [ ] PR: before/after of the home screen, **compressed** stills (JPEG/WebP ≤ 300 KB each; the
      03 stills were 15 MB), one short recording of the title card and the scene components.
- [ ] All local-review gates green; CI green; `docs/status/06.md` current.

## Events

None new. The title card fires nothing until the intro exists (brief 10).

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/06.md`: done, half-done, next.
- Phone: the **OnePlus 9** (`adb -s 96239c4a`) is yours, and **only yours**: other workers test
  with unit tests and Chrome; the realme is the lead's for reviews. The owner runs two workers
  at a time so the Mac stays responsive.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
