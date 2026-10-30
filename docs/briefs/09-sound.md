# Brief 09: Sound design: audio engine, cues, sound library (wave 2, worktree w4)

Written by the lead session, 2026-10-30 (Fri). Worktree `../thelastroom-w4`, branch
`feat/09-sound`. **Timebox: PR up by Sat 31 Oct, evening.**

## Goal

Sound is half of "cinematic". Build the audio engine, every named cue and a licensed sound
library, so the mission player (brief 10) and the tower (13) never name a file. **`docs/sound-design.md` is your spec** (the owner's, copied into the repo
in this branch's first commit): the engine, the full cue sheet, loudness and sourcing rules.

Owner decision (2026-10-30): **D5 is decided: sound ships in v1**, on by default but quiet
(effects 60 %, ambience 35 %), per `docs/sound-design.md`. That replaces "off by default" in
brief §9.

## Order change: brief 10 lands before you (owner, 2026-10-30)

To keep Mission 1 playable by Sunday, the mission player (10) is built before this brief. It
calls sound through a small interface it creates, **`apps/mobile/lib/core/audio/game_sounds.dart`**:
`abstract interface class GameSounds` (typing character, question lands, choice, lock-in,
follow-up challenge, trust up/down, dossier, stamp, results, chapter card, ambience per chapter),
a no-op implementation and its provider. **Your job includes implementing `GameSounds` on top of
`AudioService`** and overriding that provider (one line), so the player gains sound without
editing a single screen. Don't rename its methods; add to it if a cue needs a new hook.

## Hard rules

- **Licensed sounds only.** CC0 or royalty-free commercial: Kenney.nl (CC0), Pixabay (Pixabay
  licence), Freesound **CC0 only**, or synthesised by a script in this repo. Every file is listed
  in `docs/audio-credits.md` (file, source URL, licence, edits). Nothing "found online".
- **Zero setup and offline:** every file is bundled; nothing streams. If audio can't start (no
  device, web autoplay policy before the first tap, init error), the game plays silently and
  logs a `warn`. Audio never blocks a frame or shows an error.
- Never punish: no fail buzzers (the weak-result cue is "try again" energy).
- No widget ever names a file: only `Cue` values.

## In scope

1. **`AudioService`** in `apps/mobile/lib/core/audio/` on `flutter_soloud`, behind an interface so
   tests use a fake: `play(Cue)`, `startAmbience(Chapter)` with a 1.5 s crossfade, `duck`/
   `unduck` (−40 % when the question lands), `stopAll`. Preload every cue at boot. iOS ambient
   session (respects the silent switch, mixes with music); Android media stream, ducks on focus
   loss. A Riverpod provider in its own file under `core/audio/`.
2. **`Cue`** enum covering the whole cue sheet: typing ticks (per interviewer), title/app open,
   chapter card, elevator sequence, room ambience ×3 chapters, question lands, timer pulse +
   last-10 s tick (never in untimed missions), choice tap, answer locked, follow-up challenge
   (sharper for Lena), trust up/down, dossier slide, stamp + count-up tick, strong/weak result,
   skill unlocked, chapter-end cliffhanger, locked floor "through the door", Recall Room pad.
3. **Typing ticks:** a `TypingVoice` per interviewer id (`priya` lighter, `marcus` woodier,
   `lena` drier, `sam` deeper) with the sheet's rules: a tick every 2nd–3rd character, pitch
   ±6 %, max 18 per second, silent on spaces and punctuation, a pause tick on "…", stops
   instantly on tap-to-complete. Expose it as a function brief 10 plugs into 06's typewriter
   `onCharacter` callback. **Randomness gets an injectable seed** so it's testable.
4. **The sound library** in `apps/mobile/assets/audio/`: mono OGG (Android, web) and M4A (iOS),
   UI cues < 1 s, loudness normalised (effects ≈ −16 LUFS, ambience ≈ −24 LUFS). Synthesis or
   processing scripts go in `tools/audio/` (new) so the files are reproducible.
5. **Audio settings:** master on/off, Ambience/Music volume, Effects volume, with the defaults
   above, persisted (`shared_preferences`), as a provider plus a **settings section widget**
   in `apps/mobile/lib/features/settings/audio/` that the future Settings screen embeds. Brand
   tokens only (06's components land in parallel; restyle notes go in your status file).
6. **`/dev/sound` board** (not in release builds) in `core/audio/dev/`: every cue with a play
   button, the four typing voices typing a sample line, the ambience crossfade, the duck, and the
   settings section. **The owner approves the set by ear here**, before merge.
7. **Tests:** typing throttle and silence rules, cue → asset mapping (every cue has a file for
   each platform format and a credits row), settings defaults and persistence, master-off
   mutes everything, "no Cue plays in an untimed mission's timer", init failure falls back to
   silent.

## Out of scope

- Wiring cues into real screens (10, 13). Haptics (paired by 10). Music beyond the cue sheet.

## File ownership (parallel wave: touch only these)

- `apps/mobile/lib/core/audio/**`, `apps/mobile/assets/audio/**`,
  `apps/mobile/lib/features/settings/audio/**` (all new), `apps/mobile/test/core/audio/**`,
  `apps/mobile/test/features/settings/audio/**`, `tools/audio/**` (new),
  `docs/audio-credits.md` (new), `docs/sound-design.md`, `docs/status/09.md`, your own
  `.claude-logs/` files

**Shared one-liners (add only these lines; the lead resolves at merge):**
- `apps/mobile/pubspec.yaml` / `pubspec.lock`: `flutter_soloud`, `shared_preferences`, the
  `assets/audio/` entry. Brief 08 adds drift there too; whoever merges second rebases and reruns
  `flutter pub get`.
- `apps/mobile/lib/app/router.dart` (06's): one `/dev/sound` entry in the dev routes.
- `apps/mobile/lib/main.dart` (08's): one preload call.
- `apps/mobile/web/index.html` (06's): only the script tags `flutter_soloud` needs on the web.

**Not yours:** `ui/**`, other `features/**`, `core/{db,sync,backend,analytics}`, `packages/**`,
`supabase/`, CI, `scripts/`, the events registry (no new events), `AGENTS.md`, `DESIGN.md`,
`docs/HANDOFF.md`, `docs/requirements.md`.

## Acceptance criteria

- [ ] `GameSounds` implemented on `AudioService`; with it, the merged mission player plays its
      cues with no screen edits.
- [ ] Every cue in the sheet exists, plays on the `/dev/sound` board on the phone and in Chrome,
      and has a credits row with a real licence.
- [ ] Fresh clone, no env file: `flutter run -d chrome` starts silently until the first tap, then
      sound works; no network request for audio.
- [ ] iOS silent switch respected (simulator or device note); Android ducks on focus loss.
- [ ] The tests in item 7 pass. Asset weight reported in the PR (aim < 3 MB total).
- [ ] PR: a **Chrome screen recording with sound** of the `/dev/sound` board (all cues, the four typing
      voices, the ambience crossfade), compressed. The owner listens before merge.
- [ ] All local-review gates green; CI green; `docs/status/09.md` current.

## How to work

- Never edit `docs/HANDOFF.md`. Keep `docs/status/09.md`: done, half-done, next.
- **No phone:** the OnePlus is 06's only and the realme is the lead's. Test with unit tests and
  Chrome; the lead checks Android (and records with scrcpy, audio included) in review. The owner
  runs two workers at a time.
- Own branch, local-review, PR (not a draft), CI green, never merge. End with the PR link.
