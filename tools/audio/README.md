# tools/audio: the game's sound library, from source

Every sound in `apps/mobile/assets/audio/` is synthesised here, so it is original (CC0) and can
be rebuilt bit for bit. Nothing is downloaded.

```sh
brew install ffmpeg vorbis-tools    # ffmpeg: EBU R128 meter + AAC; oggenc: Vorbis
pip3 install numpy                  # the only Python dependency
python3 tools/audio/build.py        # all cues (about 12 s)
python3 tools/audio/build.py stamp  # one cue while tuning it
```

| File | What it holds |
| --- | --- |
| `cues.py` | The cue sheet (`docs/sound-design.md`) as recipes: one `@cue(...)` function per sound, with its bus, loudness target and a one-line description. |
| `dsp.py` | The building blocks: oscillators, shaped noise, biquads, envelopes, a synthetic room reverb. |
| `build.py` | Renders each recipe (seeded), normalises loudness (EBU R128, -1 dBTP ceiling), writes mono OGG Vorbis + M4A AAC, and regenerates `docs/audio-credits.md`. |

- **Adding a cue:** a recipe in `cues.py`, a value in `Cue` (`apps/mobile/lib/core/audio/cue.dart`)
  with the same asset name, then run the build. `cue_assets_test.dart` fails until the files,
  the enum and the credits row all agree.
- **Loops** (`loop=True`) are built in the frequency domain with whole-cycle frequencies, so the
  last sample flows into the first: they repeat with no seam or click.
- **Loudness:** effects about -16 LUFS, ambience about -24 LUFS (spec); the repeating ticks are
  quieter on purpose. Very short transients hit the true-peak ceiling first; the credits mark them
  *peak-limited*.
- `build/` (the intermediate WAVs and `report.json`) is git-ignored.
