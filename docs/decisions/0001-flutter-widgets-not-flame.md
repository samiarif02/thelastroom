# 0001. Flutter widgets for the cinematic layer, not Flame

- **Status:** accepted (2026-10-29)
- **Memory:** [`docs/memory/decision-flutter.md`](../memory/decision-flutter.md)

## Context

The Last Room is a narrative card-choice game whose headline is how it looks (brief §9): letterbox
bars, a spotlight with dust, film grain, an elevator transition, a dossier with stamps. It must
run on Android, iOS and the web (run locally; ADR 0005 dropped the hosted demo), at 60 fps on a
mid-range Android, with text that survives 2x scaling and a screen reader.

Almost every screen is text, buttons and layered images. There are no sprites, physics,
collisions or a game loop.

## Decision

Build everything with Flutter widgets: `CustomPainter` for the spotlight, particles, trust meter
and timer light; fragment shaders (`FragmentProgram`) for grain and vignette; `flutter_animate`
for choreography; Rive for the interviewers' idle animation. No game engine.

## Consequences

- Text, focus, semantics, text scaling and hit targets come from the widget tree for free. In
  Flame they'd be rebuilt by hand, and accessibility (NFR-2) is where that usually breaks.
- One rendering model for menus and scenes: the tower home, the mission and the debrief share
  transitions, tokens and golden tests.
- We own frame-rate discipline ourselves: `RepaintBoundary` around grain, particles and the
  meter, and profiling each scene in `--profile` before its PR (brief §9).
- Shaders on the web need the CanvasKit renderer, which is heavier to load: the branded loader
  and the first-frame budget (NFR-3) matter more.

## Alternatives considered

- **Flame.** Built for sprite and physics games with a game loop. It would cost the
  accessibility and layout work above and give us nothing the game needs.
- **Unity or Godot with a Flutter shell.** Two toolchains, a much larger web build and no shared
  design system, for a game that is mostly typography.
- **Pre-rendered video for the cinematic moments.** Looks right in a trailer but can't react to
  the player (the trust meter, the timer light, the red pen on *their* line) and bloats the
  bundle.
