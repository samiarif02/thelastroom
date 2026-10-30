# DESIGN.md: The Last Room

> **The bar:** someone should screenshot it because it looks like a film, not like an app. If a
> screen could belong to any other quiz app, it isn't done. (Brief §9)

This is the design direction from the brief. The look is **Morning Office** (owner's pick,
2026-10-30, brief 16; see "Chosen direction"): bright, warm and friendly, with an illustrated
interviewer. It replaced **C, The Boardroom** (chosen earlier the same day), whose film kit
(brief 06a, `apps/mobile/lib/ui/`) and every animation stay; only the palette, the set and the
interviewer changed.

## The big idea: the building

Northstar Labs is a tall glass tower at night. **Each chapter is a floor; the last room is at
the top.**

- **Home is the tower, seen from outside.** Lit windows are completed missions, the current
  floor glows, floors above are dark (locked). Tapping a floor zooms the camera into it.
- **The elevator is the transition** between missions: doors close, the floor counter ticks, a
  soft chime, doors open on the next room. About 1.2 s, skippable.
- **The final room** (Chapter 3, the top floor): a dark office, the city skyline behind Sam.
  Visible from the start. That's the curiosity hook.

## Film language

| Technique | Where | Flutter approach |
| --- | --- | --- |
| Letterbox bars in for the scene, out for the choice phase | Mission scenes | Animated bars; the scene scales slightly (Ken Burns) |
| A pool of sunlight on the interviewer, sun shafts through the glass | Every scene | Radial gradient + CustomPainter, pre-composited |
| Film grain + vignette, very subtle | Global overlay | Fragment shader or tiled noise behind a `RepaintBoundary` |
| Camera cuts: wide → close-up on the question; over-the-shoulder for the follow-up | Mission flow | Hero + scale/translate; depth-of-field blur on the background layer only |
| Subtitle dialogue: typewriter reveal, speaker's name in small caps | All dialogue | Custom text animation; tap to complete |
| Chapter title cards ("CHAPTER ONE — GET THROUGH THE DOOR") | Chapter start | Full-screen serif, slow fade and tracking-in |
| A colour grade per chapter | Theme | `ChapterGrade`: Ch1 leaf green, Ch2 sky blue, Ch3 raspberry (Morning Office); the whole UI re-tints |
| Parallax: background, desk, interviewer on 3 layers | Scenes, tower | `sensors_plus` tilt (pointer on web); off under reduced motion |
| Trust meter as a heartbeat line; timer as the light dimming | Answer phase | CustomPainter; numbers only under 10 s |
| Debrief as a candidate dossier: a file slides onto the desk, scores stamped, red-pen notes | Debrief | Layered cards, stamp animation, haptic thud |
| Sound (optional, off by default): room tone, chime, paper, stamp | Key moments | Licensed, credited |

## Visual system

| Token group | Where | Status |
| --- | --- | --- |
| Colour: void (lightest), cream surface, white raised, line, charcoal text, paper/ink, pen red, leaf | `packages/brand/lib/src/colors.dart` (`BrandColors`) | **Final** (16, Morning Office), every text pair AA-tested, text over colour too |
| Chapter grades: key, shadow, tint per chapter (green → blue → raspberry) | `ChapterGrade` | **Final** (16) |
| Type: Cormorant Garamond + Manrope, small-caps speaker, tabular lining figures | `typography.dart` (`BrandFonts`, `BrandType`) | **Final** (06a), bundled |
| Spacing, radii, 44 pt targets | `layout.dart` | Initial scale |
| Motion: dolly 2.2 s, hard cut 1/24 s, letterbox, typewriter, title card, dossier, curves | `motion.dart` (`BrandMotion`) | **Final** (06a) |
| Film stock: grain 3.5% (daylight), vignette 0.65 | `motion.dart` (`BrandFilm`) | **Final** (16) |
| Cast: skin, hair, clothes for Priya, Marcus, Lena | `cast.dart` (`BrandCast`) | **Final** (16), decorative |
| Theme: light, no ripple, no stock transitions, Manrope for anything Material | `theme.dart` (`BrandTheme.light`) | Safety net in place |

**06b added:** cinematic states, `/dev/catalog` with goldens, the platform edges and a web
build with no network request (sections below). **Still to do:** the tower and elevator art
direction (13); edge to edge on Android (moved to brief 10).

### The film kit (brief 06a): `apps/mobile/lib/ui/`, one import `ui/film_kit.dart`

| Component | What it is | Seams (callbacks) |
| --- | --- | --- |
| `AmbientClock`, `FilmOverlay` | One free-running clock for grain, flicker and breathing; grain + elliptical vignette | — |
| `Letterbox`, `AnimatedLetterbox` | 13% cinema bars, driven by `t` or by `shown` | `onSettled` |
| `CameraRig`, `DollyCamera`, `CameraShot`, `CameraLayer` | Layered set framed wide → close; parallax from per-layer close-ups; 2.2 s dolly push | `onPushStart`, `onPushEnd` |
| `HardCut` | One frame of void (a cream blink) when `shot` changes (the follow-up) | `onCut` |
| `Spotlight`, `BankersLamp`, `Bokeh`, `Dust`, `lampFlicker` | The pool of sun (dust off by default), the desk mug (`BankersLamp` keeps its name; cold = offline), soft bokeh | — |
| `InterviewerSilhouette`, `SilhouetteFigure.priya/.marcus/.lena` | The scene's handle on an interviewer: draws the `FriendlyInterviewer` (names kept from the silhouettes the mission uses) | `expression` |
| `BoardroomSet.layers(...)` | The office in three parallax planes, wide/close/tight framings (name kept) | `expression` |
| `TypewriterSubtitle`, `TypewriterController`, `SpeechPanel` | Speaker in small caps, line typed at 30 ms/char on a soft speech panel (AA over her jacket), tap or controller completes | `onCharacter(char, index)`, `onComplete` |
| `AnswerCard`, `AnswerCardState` | Engraved plaque: idle, focused, selected, locked, disabled | `onTap` |
| `ChapterTitleCard`, `TrackedTitle` | Lamp, brass frame, tracking-in title that never breaks a word | `onTitleLanded`, `onFinished` |
| `Dossier`, `WaxSeal`, `StampIn`, `PenNote`, `PenStroke` | Letterhead slides in, scores stamped, total sealed, pen notes | `onStamp(i)`, `onSeal`, `onPen`, `onFinished` |
| `Timeline`, `cue`, `mix`, `AnchoredScroll` | Cue-sheet choreography on one clock; content anchored low that scrolls only at 2x | `cues`, `onFinished` |
| `SceneState.loading/empty/offline/error`, `LoadingRule` (06b) | The four designed states: lamp, brass ornament, italic line, note. Offline switches the lamp off; loading has a breathing brass rule, never a spinner | `onAction` (adds a `BrassButton`) |
| `BrassButton` (06b) | An engraved brass plate with a tracked caps label, 44 pt, brightens on hover/focus/press; null `onTap` is disabled | `onTap` |
| `FriendlyInterviewer`, `FriendlyFigure.priya/.marcus/.lena`, `InterviewerExpression`, `FaceShape`, `FaceGesture` (16) | The friendly cast: five expressions (eased; the nod moves the head), idle = breath, blink, sway; reduced motion stills it | `expression` |
| `OfficeBackdrop`, `OfficeDesk`, `DeskMug` (16) | The Morning Office set: wall, glass, far city, sun shafts, plant; the pale desk; the mug with steam | — |

Rules the kit holds to (and screens must too):

- **The vignette lies under text, never over it.** It darkens the frame's edges by up to 65%,
  which takes edge text below AA. The app wraps every route in grain only; a scene vignettes
  its set (`FilmOverlay(grain: 0, ...)`) beneath its subtitles and cards. Tested on the title.
- **The app never settles.** Grain, flicker and breathing run on the ambient clock, so
  `pumpAndSettle` times out. Tests `pump(duration)` through the choreography (and pump in
  steps: a single big pump skips the rests between beats).
- Every animated component has a reduced-motion path (a short cross-fade, or settled at once);
  beats don't fire under reduced motion, `onFinished`/`onComplete` still do.
- A hard cut moves every plane together; only the dolly pushes planes at different rates.

### `/dev/catalog` and goldens (06b)

- `/dev/catalog` (debug and profile builds only) lists every component; each opens on its
  states full frame, with **STILL** (reduced motion), **2X** (text) and the **grade** toggles,
  `?shot=<id>` and `?chrome=off` for screenshots. It replaced `/dev/directions`.
- `features/dev_catalog/catalog_entries.dart` is the one list: the catalog's pages *and* the
  golden tests (`apps/mobile/test/features/dev_catalog/goldens/`, one PNG per state, drawn with
  the real fonts). A new component added there gets a golden and a 1x/2x/reduced-motion
  play-through test for free. Redraw them on Linux (`goldens/README.md`: a Docker one-liner on
  CI's Flutter), then look at every changed image.
- Goldens are Linux pixels: CI compares them; macOS anti-aliases glyphs differently (1.5–6% of
  pixels), so there the tests render every state but skip the diff. Grain isn't in them.
- An unknown route shows `WrongFloorScreen` (the error state, "Back to the lobby").

### Platform edges (06b)

- **Icon:** a leaf-green "LR" in Cormorant Garamond over a rule with two diamonds, on cream
  with a pool of morning sun, inside the title card's double frame (brief 16; 06b's layout). Android legacy + adaptive
  (with monochrome), iOS, web favicon/icons/maskable. Drawn by
  `packages/brand/tool/make_icons.py` (Pillow); its colours mirror `colors.dart`.
- **Launch:** void with the monogram, so the jump to the first Flutter frame is invisible.
  Android: `drawable/launch_background.xml` and Android 12+'s splash, through
  `LaunchTheme.Boardroom` / `NormalTheme.Boardroom` (`values*/brand_themes.xml`), which extend
  `styles.xml` rather than edit it. iOS: `LaunchScreen.storyboard` on void (cream since 16).
- **Web, no network:** `build:web` uses `--no-web-resources-cdn` (CanvasKit and Roboto ship
  with the build); `web/index.html` sets `canvasKitBaseUrl` and `fontFallbackBaseUrl` so a
  plain `flutter run -d chrome` stays local too (Roboto vendored in `web/fonts/`, OFL). A glyph
  none of the fonts has shows as a box instead of fetching a Noto font.

## Brief 16: three brighter, friendlier options (the owner picked Morning Office)

After the first phone play (2026-10-30) the Boardroom read as **James Bond / a CID
investigation**: Priya as a silhouette in a spotlight feels like an interrogation. Every
animation, component and screen stayed; the **palette** and the **interviewer** changed. The
three options were compared live on the phone and in Chrome (a temporary `/dev/looks` and a
look switch over every screen, with the tokens briefly read at runtime); after the pick the
chosen palette became the `const` tokens again and the switch, the other two options and the
silhouette were deleted. Stills and phone recordings: `.pr-screenshots/16/`.

All three shared one **friendly interviewer** (`ui/figure/friendly_*`, D2 still "drawn in code"): Priya
(black bob, gold hoops, teal blazer), Marcus (cropped hair, beard, glasses, tie) and Lena
(auburn bun, freckles, mustard jumper), with five expressions (neutral, smile, thinking, nod,
hmm) and an idle (breath, blink, a little sway) that reduced motion stops. The head stays in
`MissionSet.faceInDesign`, so subtitles stay clear of the face; a subtitle sits on a soft
speech panel, so a line over her jacket stays AA. The rim light remains on the lit edge
(the grade's key in a dark look, a soft sheen in daylight).

AA (WCAG 4.5:1 for every pair, including the grade keys, which set small text) is tested for
every look in `packages/brand/test/contrast_test.dart`, with **text over colour**: the
choice text and numeral on the warmest card (raised mixed halfway into the tint) and every
text on the speech panel over every cast colour. Figures below are the lowest ratio across
void, surface and raised.

### 1 · Morning Office: Cormorant Garamond + Manrope

*A sunny office at 9 a.m.: cream, plants and glass, coffee on the desk.*

- **Palette:** void `#FFFCF6`, surface `#F8F1E4`, raised `#FFFFFF`, line `#E2D5BF`, text
  `#2A2420` (13.6:1), secondary `#665A50` (5.9). Paper `#FFFFFF`: ink `#2A2420` (15.3), ink soft
  `#665A50` (6.7), red pen `#B83A2A` (5.7).
- **Grades** (key / shadow / tint): Ch1 leaf green `#2C7356` / `#E9F2EA` / butter sun `#FFE7AE`
  (5.1). Ch2 sky blue `#2D5C9E` / `#E6EDF7` / `#D4E3F8` (6.0). Ch3 raspberry `#A8344A` /
  `#F9E7E8` / `#FAD3C8` (5.7). Tension rises through saturation and warmth, never darkness.
  Card text 13.1+, card numeral 5.2+.
- **Scene:** tall glass full of pale sky, the city soft and far, slanting sun shafts, a plant
  by the window, a mug with steam on a pale desk. No dust (it only shows in a dark beam).
- **Cards and dossier:** white plaques with a green rule; the dossier is a crisp white sheet.
- **Tower (13):** a white-and-glass tower in morning light, completed floors with leafy
  balconies, the current floor glowing butter yellow.

### 2 · Bold & Playful: Manrope for everything

*Confident colour blocks, a game you want to win, grown-up enough for work.*

- **Palette:** void `#1B1446`, surface `#261C62`, raised `#342885`, line `#5446B0`, text
  `#FFF9EE` (11.2:1), secondary `#D3C9FF` (7.6). Paper `#FFFFFF`: ink `#1B1446` (17.0), ink soft
  `#4C4390` (8.4), red pen `#C8174F` (5.7).
- **Grades:** Ch1 sunny yellow `#FFD23F` / `#140E3A` / violet `#5B3FD0` (8.1). Ch2 mint
  `#4CE0BE` / `#0E1840` / `#1F55C8` (7.1). Ch3 hot pink `#FF8CC0` / `#26103E` / `#9A2272` (5.5).
  The colour gets louder as the stakes rise. Card text 8.5+, card numeral 4.6+.
- **Type:** headings and the interviewer's lines in **Manrope** (no new font; brief 16 allows
  one option a friendlier voice): rounder, more game-like.
- **Scene:** flat colour blocks drifting slowly (a big halo disc behind Priya, a slab, a pill,
  a small sun), confetti dots, a chunky desk with a thick yellow edge and a pencil pot.
- **Cards and dossier:** violet plaques with yellow numerals; the dossier is a white card on
  indigo with a hot-pink seal.
- **Tower (13):** a stack of coloured blocks, each floor its own colour, the current one
  bouncing gently.

### 3 · Sunset City: Cormorant Garamond + Manrope

*Golden hour on the 40th floor: peach light, coral sky, the city glowing below.*

- **Palette:** void `#FFF5EE`, surface `#FFE9DD`, raised `#FFF8F3`, line `#F1C8B4`, text
  `#3A1C44` plum (12.6:1), secondary `#6E4466` (6.7). Paper `#FFFBF7`: ink `#3A1C44` (14.3), ink
  soft `#6E4466` (7.6), red pen `#B0303F` (6.1).
- **Grades:** Ch1 late-afternoon terracotta `#A8432C` / `#FFE2D2` / peach `#FFC9A3` (5.1). Ch2
  sunset violet `#6A3C9E` / `#EFE2F7` / coral `#F4B3B8` (6.5). Ch3 dusk magenta `#9A2260` /
  `#F8DDE9` / lilac `#D9B4E8` (6.5). The sky deepens chapter by chapter while the ground stays
  warm and light: the final round is dusk, not night. Card text 10.8+, card numeral 4.8+.
- **Scene:** the glass full of a peach-to-coral sky, a low sun, the skyline glowing with lit
  windows, a little globe lamp on the desk.
- **Cards and dossier:** warm cream plaques with terracotta numerals; the dossier on cream.
- **Tower (13):** the tower itself at golden hour, glass reflecting the sunset; it gets
  later in the day as you climb.

### Comparison

| | Morning Office | Bold & Playful | Sunset City |
| --- | --- | --- | --- |
| Mood | calm, optimistic, daylight | energetic, game-like | warm, cinematic, aspirational |
| Ground | light cream | deep indigo + colour blocks | light peach |
| Chapter climb | green → blue → raspberry | yellow → mint → hot pink | afternoon → sunset → dusk |
| Type | serif + sans | sans only | serif + sans |
| Still a film? | partly (quiet) | least | **most** |
| Show to clients | clean, safe, a little generic | memorable, but "kids' app" risk | **premium and distinctive** |
| Open it tomorrow | relaxing | **most habit-forming** | inviting, a place to return to |
| Lowest AA (any text pair) | 5.0 | 4.6 | 4.8 |

### Recommendation (before the pick): 3, Sunset City. **The owner chose 1, Morning Office.**

1. **It keeps what's loved.** The owner's favourite screens (candidate file, dossier) and
   the film language survive intact: golden-hour light, a skyline, depth. It's the only
   option that still passes the brief's bar ("looks like a film") while losing the
   interrogation.
2. **Beautiful enough to show clients.** Peach-to-violet gradients and a serif read premium
   and distinctive in a screenshot; Morning Office is pleasant but could be any HR SaaS.
3. **Makes you want to open it tomorrow.** It's warm and aspirational (the 40th floor at the
   best hour of the day), and the chapter arc is literally the day ending, so each chapter
   feels later, bigger and closer to the offer, without ever going dark.
4. **The tower writes itself.** Brief 13's tower at golden hour, reflecting the sky, is the
   most screenshot-able home screen of the three.

**What to borrow:** from Bold & Playful, its confidence for rewards and streaks (a flat
colour burst when a floor unlocks); from Morning Office, the desk props (the mug, the plant).

## Chosen direction: Morning Office (owner, 2026-10-30, brief 16)

The owner played all three options on the phone and picked **1 · Morning Office** (spec
above, now the real tokens in `packages/brand`). It settles the look: daylight, warm cream,
white glass, a plant and a mug, soft colour; the chapters climb leaf green → sky blue →
raspberry through saturation, never darkness. **D2** stays "drawn in code", now as the friendly
cast (Priya, Marcus, Lena) with expressions instead of silhouettes. **D4** is unchanged:
Cormorant Garamond + Manrope.

What carries over from the Boardroom unchanged: every camera move (the 2.2 s dolly push with
parallax, the follow-up's hard cut, now a one-frame cream blink), the letterbox, typewriter,
title card, dossier, seal and pen, the designed states, motion principles and reduced motion.

Rules the new look adds:

- **Text over the interviewer sits on the speech panel** (`SpeechPanel`, void at 94%); it is
  AA-tested over every cast colour.
- **A scene sets the interviewer's expression per beat**: smile on the greeting, thinking on
  the cards, a nod on lock-in, "hmm" on the follow-up (the kit and `/dev/catalog/scene` do;
  the mission player is a follow-up for its owner).
- **When the cards are up, the question shrinks to a one-line recap** so it never covers her
  face (owner, 2026-10-30).
- No dust in daylight; grain at 3.5%.

## Previous direction: C, The Boardroom (owner, 2026-10-30; replaced the same day)

*Kept for the record. Its palette, walnut set, banker's lamp and silhouettes are gone (brief
16).* The owner picked **C · The Boardroom** after comparing all three on a phone (PR #6). This
settled **D4**: **Cormorant Garamond** (display) + **Manrope** (body). The palette, grades,
type ramp and set pieces are exactly as written in "C · The Boardroom" below; that section is
now the spec, not a proposal.

**Motion principles**

- Slow, weighty glides (ease-out, no overshoot, nothing bouncy). The default camera cut is the
  2.2 s dolly push with parallax; the window layer moves less than the people.
- One deliberate exception, borrowed from B: the **follow-up question** lands on a hard cut
  through one black frame, so pressure reads as an edit, not a fade.
- Reduced motion: every push, parallax and tracking-in becomes a cross-fade.
- On low-end Android, if parallax costs frames, fall back to A's rack focus (blur the back
  layer only).

**What brief 06 builds**

1. The real tokens in `packages/brand` from `directions/boardroom.dart` (palette, three grades,
   type ramp with tabular lining figures, motion durations and curves), replacing the
   foundation placeholders; `ThemeData` from them.
2. Fonts: keep `cormorant_garamond/` and `manrope/`; **delete** `instrument_serif/`, `geist/`,
   `big_shoulders_display/`, `inter_tight/`, their pubspec entries, and
   `directions/night_glass.dart` and `directions/concrete_noir.dart`. `/dev/directions` goes
   once `/dev/catalog` replaces it.
3. The film kit promoted from `features/dev_directions/shared/` into reusable components
   (grain + vignette, letterbox, typewriter subtitle, camera rig, stamp/seal, pen note, bokeh),
   each in `/dev/catalog` in every state, with goldens.
4. Branded native launch screens and app icons in this look (brass monogram on walnut).
5. Web: no runtime fetch at all (`fontFallbackBaseUrl` to a local path in `web/index.html` so
   the engine stops fetching Roboto, and `--no-web-resources-cdn` for CanvasKit).
6. Edge to edge on Android: the scene draws under the status and navigation bars (today they
   show as flat black bands on the realme 8).

**Known issues from the phone review (fix in 06)**

- ~~The Boardroom title's tracking-in starts wide enough that "THROUGH" breaks mid-word
  ("THROU / GH").~~ Fixed in 06a: `TrackedTitle` decides the lines once at the final tracking,
  between words only, and draws each line unbreakable while it tracks in (tested at 320, 375
  and 412 wide, 1x and 2x text, every 50 ms of the animation).
- Edge to edge on Android: moved to brief 10 (owner, 2026-10-30).

**D2, portrait art (confirmed by the owner, 2026-10-30):** keep the **rim-lit silhouettes drawn in
code** that the prototype already uses, with a code-driven idle (breath, a slow head turn,
lamp flicker on the rim). It's original, needs no rights, costs no build days and suits the
Boardroom's low-key light. Painterly portraits (commissioned or AI-generated with commercial
rights) are a stretch goal after Chapter 1 is polished, credited in the README if they land.

## Prototype directions (brief 03): the three that were compared

Three throwaway directions for Mission 1 ("The Opportunity", Priya), built at `/dev/directions`
(debug and profile builds only). Run `cd apps/mobile && flutter run -d chrome`, then open
`/#/dev/directions`. Each direction shows a title card, a scene and a dossier, with the
controls pill top-right (`?frame=title|scene|dossier&chrome=off` for clean stills). The tokens
live in `packages/brand/lib/src/directions/`, beside the real ones. Brief 06 promotes the winner
and deletes the rest.

AA is tested for every text pair (`packages/brand/test/contrast_test.dart`). Each figure below
is the **lowest** ratio of that colour across void, surface and raised. The grade keys are held
to 4.5 (not 3) because they set small labels such as the speaker's name.

### A · Night Glass: Instrument Serif + Geist

*A glass tower at 3 a.m.: cold, hushed, perfectly still, and watching you.* (Severance, A24
title cards, Michael Mann night exteriors.)

- **Palette:** void `#04060A`, surface `#080B11`, raised `#10151D`, line `#232B36`, text
  `#E6EBF0` (15.3:1), secondary `#8F9BA8` (6.5:1). Dossier paper `#E4E7EA`: ink `#12161C`
  (14.6), ink soft `#4A5260` (6.3), red pen `#B8291F` (5.0).
- **Grades** (key / shadow / tint): Ch1 `#E8B169` / `#120C06` / `#3A2A16` (9.5:1). Ch2
  `#8FB3D9` / `#060B12` / `#1B2A3C` (8.4). Ch3 `#D4B36A` / `#16070A` / `#4A1218` (9.1). The UI
  stays cold blue-black; the grade is the only warm (or cold) thing in frame, the light itself.
- **Type:** title card Instrument Serif *italic* 54 / 1.02, tracking −0.8, tracking in from +10
  while it pulls focus (blur 10 → 0). Display serif 34. Body and subtitles Geist 15–17. Labels
  Geist 500 at 10.5 with +2.6 to +4 tracking. Scores Geist with **tabular figures** (Instrument
  Serif has none).
- **Composition and texture:** asymmetric, low left-aligned text, huge negative space,
  hairlines; frosted-glass answer panes; barely-there grain (5%).
- **Motion and light:** long dissolves and a **rack focus** as the camera cut: the push-in
  melts the city behind her while she sharpens (1.6 s, very slow out). Light is a cool,
  hard-edged downlight shaft; nothing flickers.
- **Set pieces:** the *tower* is one sharp glass slab in negative space, almost every window
  dark, the lobby and the top floor lit. The *elevator* is a slow cross-dissolve on brushed
  steel, floor numbers in hairline Geist. The *spotlight* is a narrow downlight cone with drifting
  dust. The *dossier* is a single clean Swiss-grid sheet on a dark glass desk: scores stamped into
  hairline boxes, one red ring, an italic note.

### B · Concrete Noir: Big Shoulders Display + Inter Tight

*An interrogation lit through blinds: hard light, hard cuts, words as tall as walls.* (Fincher
title sequences: Se7en, Zodiac, Mindhunter; Saul Bass.)

- **Palette:** void `#050505`, surface `#0B0B0A`, raised `#161614`, line `#2E2D29`, text
  `#F1EBDD` bone (15.2:1), secondary `#A39D8F` (6.7). Manila paper `#D8C8A2`: ink `#1A1712`
  (10.8), ink soft `#4A4235` (6.0), red marker `#9E1F17` (4.8).
- **Grades:** Ch1 sodium `#F0A836` / `#140C02` / `#3D2A0C` (8.9). Ch2 `#6FA0C8` / `#050A10` /
  `#14283A` (6.5). Ch3 `#D9B24C` / `#1A0405` / `#7A1A1E` (9.0). Graded like a duotone: the key
  floods the light, everything else is black.
- **Type:** title card Big Shoulders Display 800, each line fitted edge to edge (≈112 pt and up),
  line height 0.84, tracking in from +26. Speaker name in true small caps (`c2sc`/`smcp`).
  Subtitles Inter Tight 600 18. Scores Inter Tight with **tabular figures** (Big Shoulders'
  figures are proportional).
- **Composition and texture:** type *is* the set: her name runs two storeys tall up the wall
  behind her. Screenplay slug lines ("INT. NORTHSTAR LABS — LOBBY — NIGHT"), hard slabs for
  answers, heavy grain (16%).
- **Motion and light:** short and decisive (letterbox 0.52 s, cut 0.38 s on a hard ease),
  lines **flicker on** like a failing tube, and the camera cut is a real edit: a snap push
  through one black frame. Light is cut into bars by a venetian blind, falling across wall and
  face.
- **Set pieces:** the *tower* is a black monolith with blind-light bars across it and floor
  numbers in giant condensed type. The *elevator* is a hard cut to the floor number filling the
  screen, ticking up. The *spotlight* is a bare bulb above, dust in the bars. The *dossier* is
  a manila case file thrown onto the desk: ruled score boxes, redaction bars, UNDER REVIEW
  slammed on, a marker ring.

### C · The Boardroom: Cormorant Garamond + Manrope

*Old money after hours: walnut, brass, tungsten lamps and a city out of focus.* (Succession,
Michael Clayton, The Godfather office scenes.)

- **Palette:** void `#0C0806`, surface `#140E0B`, raised walnut `#1F1712`, line `#3A2D24`, text
  cream `#F3E7D3` (14.4:1), secondary `#BBA990` (7.7). Letterhead `#F1E7D3`: ink `#2A1E16`
  (13.2), ink soft `#65513F` (6.1), fountain-pen red `#A3201B` (6.2).
- **Grades:** Ch1 `#E2AE62` / `#1B1009` / `#5A3518` (8.8). Ch2 `#9DB4C8` / `#0D1218` /
  `#2A3644` (8.2). Ch3 `#CFAE5E` / `#22080B` / `#6E1A20` (8.3). Ch3's brass on oxblood *is*
  this room, so the final round lands where the whole look was heading.
- **Type:** title card Cormorant Garamond 500 caps at 40, tracking 7, tracking in from +22 with
  a slow push (1.06 → 1). Speaker name in Cormorant small caps. Subtitles in the serif at 22.
  Choices Manrope 14.5. Scores Cormorant with **tabular lining figures**.
- **Composition and texture:** symmetrical and centred; brass double rules, diamond ornaments,
  engraved plaques with italic roman numerals; bokeh, paper, walnut grain; medium grain (9%).
- **Motion and light:** slow glides. The camera cut is a 2.2 s **dolly push with parallax**:
  the window layer moves less than Priya, so the room has depth. Light is a warm tungsten lamp
  pool from the side; the city breathes as soft bokeh.
- **Set pieces:** the *tower* is warm amber windows in a dusk-blue mass, brass floor numbers.
  The *elevator* has brass doors, a needle floor dial and a soft chime. The *spotlight* is a
  green-shaded banker's lamp. The *dossier* is cream letterhead with a monogram, a ledger of
  scores, an oxblood wax seal with the total, and a fountain-pen note in the margin.

### Recommendation: C, The Boardroom

Against the bar ("someone should screenshot it because it looks like a film"):

1. **It looks most like a film for longest.** B makes the single most screenshot-able frame
   (its title card), but A and B are at their best on the title; C is at its best *in the room*,
   the scene and the dossier, where players spend 90% of their time. Warm practical light,
   parallax depth and bokeh read as cinematography, not UI.
2. **It's the brief's own type.** §9 asks for "a dramatic display serif … film-poster feel".
   C and A deliver that; B replaces it with a condensed sans and would need §9 changed.
3. **The chapter arc is built in.** Amber lobby → steel pressure → oxblood and gold: C's own
   material palette *is* the Chapter 3 grade, so the campaign visibly climbs toward the last
   room. In A and B the grades are washes on a neutral base.
4. **Right tone for anxious players.** This is daily practice for job interviews. B's
   interrogation room is thrilling once and stressful every day; A is beautiful but cold and
   closest to "premium minimal app". C is pressure with warmth: an expensive room you want to
   earn your way into.
5. **It has the most to grow into:** wax seals, brass dials, the elevator's needle, Sam's
   corner office are all natural extensions.

**What to borrow:** B's real-edit camera cut (one black frame) for the follow-up question,
and B's flicker-on for Chapter 2's "pressure" title card. A's rack focus is the best reduced-
cost depth cue if C's parallax costs too much on low-end Android.

### Fonts (all SIL OFL 1.1, bundled in `packages/brand/fonts/`, each with its `OFL.txt`)

Static, Latin-subset instances made with fontTools from the google/fonts originals (none
declares a Reserved Font Name, so subsetting and instancing are allowed). The subsets keep
`smcp`, `lnum` and `tnum` (small caps and tabular lining figures):

| Family | Weights bundled | Copyright |
| --- | --- | --- |
| Cormorant Garamond | 500, 600, 500 italic | The Cormorant Project Authors |
| Manrope | 400, 600 | The Manrope Project Authors |

06a deleted the two losing pairs (Instrument Serif + Geist, Big Shoulders Display + Inter
Tight): folders, pubspec entries and `directions/*.dart`.

## Design session brief: must-dos carried from the foundation

Found while booting the foundation build, and agreed by the owner (2026-10-29) to be fixed in the
design session. **All four are done** (1 in 06a; 2–4 in 06b, see "Platform edges" above):

1. **Bundle the fonts.** Choose the OFL display serif and body sans (decision D4), add the files
   to `packages/brand`, and set `fontFamily` on every `BrandType` style. Today the web build has
   no font, so Flutter downloads Roboto from fonts.gstatic.com at runtime, against brief §9
   ("bundled, offline-safe, no runtime fetch").
2. **Serve CanvasKit ourselves.** Build the web app with `--no-web-resources-cdn` (in
   `package.json` `build:web` and the deploy) so the renderer isn't fetched from Google's CDN.
   Check the first-frame budget (< 3 s) afterwards.
3. **Brand the native launch screens.** Android 12+ shows the Flutter logo on white
   (`android/app/src/main/res/values*/styles.xml`, `drawable*/launch_background.xml`); iOS shows a
   white `LaunchScreen.storyboard`. Both become `BrandColors.void_` with the title mark, so the
   jump from launch to the first Flutter frame is invisible. The web loading screen in
   `web/index.html` already does this.
4. **App icons** for Android, iOS and the web manifest (currently Flutter defaults).

## Rules that already hold

- **Tokens only.** No raw colours outside `packages/brand` (`check:standards`).
- **No stock Material** (AppBar, ListTile, Card, FAB, default buttons, ripple, default blue).
- **Every state designed**, loading/empty/offline/error included, in the same film language
  ("The lights are out. Your progress is safe on this device.").
- **Motion has a purpose**; reduced motion → cross-fades.
- **Performance:** 60 fps mid-range Android; `RepaintBoundary` around grain, particles, meters.

See `docs/rules/components.md` for the enforceable version.
