# Code quality

The goal of every rule here, as in 8x's template: keep the codebase predictable enough that an
agent (or a new engineer) can extend it or fix a bug without first reverse-engineering intent.
Predictable structure and honest types do more for that than documentation.

## Strict analysis, and infos are errors

`analysis_options.yaml` (one file, at the root, for the whole workspace) turns on
`strict-casts`, `strict-inference` and `strict-raw-types`, and CI runs
`flutter analyze --fatal-infos`. There is no "just a lint": anything the analyzer reports fails
the build. Packages don't get their own `analysis_options.yaml` (`check:standards` fails if one
overrides the root).

## No `dynamic` (the Dart `any`)

`dynamic` switches off type checking for every value it touches, silently. Instead, in order of
preference:

- **`Object?`** for a value of unknown shape. It can't be used until it's narrowed with a
  pattern or `is` check, which forces a real runtime check.
- **Generics** to keep the relationship between input and output types.
- **A real model class** (or a sealed class hierarchy) for the actual shape.
- **Parse at the boundary**: JSON from Supabase, the coach or local storage is decoded once,
  into a typed model, with a test for the malformed case. Nothing past the boundary sees a
  `Map<String, dynamic>`.

`avoid_dynamic_calls` is an error. A genuine exception (an untyped plugin API) is wrapped once,
with a comment saying why, and typed from there on.

## No god files

Line count is a proxy; the real signal is responsibility count. A widget file that builds UI,
holds state, talks to the database and computes scores is four files. The usual split:

- `features/<feature>/` holds the screen widgets and their small private components;
- state lives in Riverpod providers/notifiers next to the feature (`*_controller.dart`);
- data access lives in `core/db` and `core/sync` repositories;
- game logic lives in `packages/engine`, never in a widget.

## The engine is pure

`packages/engine` has no Flutter, no I/O, no `DateTime.now()`, no unseeded `Random()`
(`check:standards` `engine-pure-dart`). Time and randomness are passed in. Every rule in it is
unit-tested, including edge cases; a score must be reproducible from the same inputs.

## Named constants, not magic numbers

A threshold, weight, duration, limit or retry count whose meaning isn't obvious gets a named
constant (or a `packages/brand` token for anything visual). This is a review rule, not a lint:
`no-magic-numbers`-style lints are mostly noise.

## DRY: the Rule of Three

Two occurrences are fine. Before a third copy lands, extract it.

## Comments

Explain *why*, not *what*. A comment that restates the code is noise; a missing comment on a
non-obvious invariant (why a list must stay sorted, why a value is clamped) is a finding.
Public API in `packages/` gets a `///` doc comment.

## Naming

`lowerCamelCase` for members and variables, `UpperCamelCase` for types, `snake_case.dart` for
files, `snake_case` for database columns and event wire names. `SCREAMING_CAPS` is not Dart
style; constants are `lowerCamelCase`.

## Tests

- `packages/engine` and `packages/content`: unit tests for every rule and every content
  invariant (each mission has 3 beats, each beat 3–4 options, every option is tagged).
- `apps/mobile`: widget tests for each screen state; golden tests for key screens once the
  design system exists (brief §9 "Proof of quality").
- A bug fix starts with a failing test.
