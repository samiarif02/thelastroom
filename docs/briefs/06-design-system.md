# Brief 06: Design system + cinematic layer, The Boardroom (wave 2, worktree w1)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w1`, branch
`feat/06-design-system`. **Timebox: PR up by Sat 31 Oct, 10:00.** This is the critical path:
brief 10 (the mission player) builds on it.

## Goal

Turn the chosen direction into the real system. When this merges, the app opens on a Boardroom
title card that looks like a film, every film-kit component exists in `/dev/catalog` in every
state with goldens, and no Material default or runtime fetch is left anywhere.

Read first: `DESIGN.md` "Chosen direction: C, The Boardroom" (**that section is your spec**) and
"C · The Boardroom", brief §9, `docs/rules/components.md`, `docs/rules/code-quality.md`,
ADR 0005, and `apps/mobile/lib/features/dev_directions/` (the prototype you're promoting).

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
- Phone: the **OnePlus 9** (`adb -s 96239c4a`) is yours this wave; the realme is the lead's.
  Four workers share this Mac: one Gradle build at a time where you can.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
