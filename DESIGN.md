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

## Rules that already hold

- **Tokens only.** No raw colours outside `packages/brand` (`check:standards`).
- **No stock Material** (AppBar, ListTile, Card, FAB, default buttons, ripple, default blue).
- **Every state designed**, loading/empty/offline/error included, in the same film language
  ("The lights are out. Your progress is safe on this device.").
- **Motion has a purpose**; reduced motion → cross-fades.
- **Performance:** 60 fps mid-range Android; `RepaintBoundary` around grain, particles, meters.

See `docs/rules/components.md` for the enforceable version.
