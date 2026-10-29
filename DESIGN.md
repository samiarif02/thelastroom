# DESIGN.md: The Last Room

> **The bar:** someone should screenshot it because it looks like a film, not like an app. If a
> screen could belong to any other quiz app, it isn't done. (Brief §9)

This is the design direction from the brief. **The token values in `packages/brand` are
provisional** and get filled in during the design session (Prompt 3a: choose the direction;
3b: build the system). The token *names* and structure are already in place, so screens built
before then won't need restructuring.

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
| Spotlight on the interviewer, a slow flicker, dust in the light | Every scene | Radial gradient + CustomPainter particles, pre-composited |
| Film grain + vignette, very subtle | Global overlay | Fragment shader or tiled noise behind a `RepaintBoundary` |
| Camera cuts: wide → close-up on the question; over-the-shoulder for the follow-up | Mission flow | Hero + scale/translate; depth-of-field blur on the background layer only |
| Subtitle dialogue: typewriter reveal, speaker's name in small caps | All dialogue | Custom text animation; tap to complete |
| Chapter title cards ("CHAPTER ONE — GET THROUGH THE DOOR") | Chapter start | Full-screen serif, slow fade and tracking-in |
| A colour grade per chapter | Theme | `ChapterGrade`: Ch1 warm amber lobby, Ch2 cold steel blue, Ch3 oxblood and gold; the whole UI re-tints |
| Parallax: background, desk, interviewer on 3 layers | Scenes, tower | `sensors_plus` tilt (pointer on web); off under reduced motion |
| Trust meter as a heartbeat line; timer as the light dimming | Answer phase | CustomPainter; numbers only under 10 s |
| Debrief as a candidate dossier: a file slides onto the desk, scores stamped, red-pen notes | Debrief | Layered cards, stamp animation, haptic thud |
| Sound (optional, off by default): room tone, chime, paper, stamp | Key moments | Licensed, credited |

## Visual system

| Token group | Where | Status |
| --- | --- | --- |
| Colour: near-black/charcoal surfaces, warm off-white text, one spotlight-amber accent, red pen | `packages/brand/lib/src/colors.dart` (`BrandColors`) | **Provisional values**, AA-tested |
| Chapter grades: key, shadow, tint per chapter | `ChapterGrade` | **Provisional values** |
| Type: display serif (titles, chapter cards, names), legible sans (body, choices), tabular figures | `typography.dart` (`BrandType`) | **Fonts to choose and bundle** (OFL, offline) |
| Spacing, radii, 44 pt targets | `layout.dart` | Initial scale |
| Motion: durations (quick, standard, cinematic, elevator, title card), eased weighty curves, reduced-motion fade | `motion.dart` (`BrandMotion`) | Initial values |
| Theme: no ripple, no stock transitions, brand colours for anything Material | `theme.dart` (`BrandTheme`) | Safety net in place |

**To fill in during the design session:** final palette and grades (checked against WCAG AA,
including text over imagery with scrims), the font pair, the illustration style for the four
interviewers (3 expressions each, animated idle via Rive), grain/vignette intensity, the tower
and elevator art direction, and golden tests for every key screen.

## Chosen direction: C, The Boardroom (owner, 2026-10-30)

The owner picked **C · The Boardroom** after comparing all three on a phone (PR #6). This
settles **D4**: **Cormorant Garamond** (display) + **Manrope** (body). The palette, grades,
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

- The Boardroom title's tracking-in starts wide enough that "THROUGH" breaks mid-word
  ("THROU / GH") for the first moments of the animation. Lay out at the final tracking and
  animate a transform, or forbid breaks inside a word.

**D2, portrait art (proposal, owner to confirm):** keep the **rim-lit silhouettes drawn in
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
declares a Reserved Font Name, so subsetting and instancing are allowed):

| Family | Weights bundled | Copyright |
| --- | --- | --- |
| Instrument Serif | Regular, Italic | The Instrument Serif Project Authors |
| Geist | 400, 500 | The Geist Project Authors (Vercel) |
| Big Shoulders Display | 600, 800 | The Big Shoulders Project Authors |
| Inter Tight | 400, 600 | The Inter Project Authors |
| Cormorant Garamond | 500, 600, 500 italic | The Cormorant Project Authors |
| Manrope | 400, 600 | The Manrope Project Authors |

Brief 06 deletes the two losing pairs (folders, pubspec entries, `directions/*.dart`).

## Design session brief: must-dos carried from the foundation

Found while booting the foundation build, and agreed by the owner (2026-10-29) to be fixed in the
design session:

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
