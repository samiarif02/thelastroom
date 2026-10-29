# The Last Room — Sound design (brief source for 09)

Sound is half of "cinematic". Every cue has a job: build **curiosity**, **suspense** or
**"what happens next"**, or confirm an action. Never punish (no fail buzzers).

## Engine
- `flutter_soloud` (low-latency game audio; layering, pitch, fades; works on Android, iOS and web).
- One `AudioService` in `apps/mobile/lib/core/audio/`, with named cues (an enum) and nothing
  else: widgets call `audio.play(Cue.stamp)`, never a file path.
- Preload every cue at boot (files are short). Ambience loops crossfade over 1.5 s.
- iOS: the *ambient* audio session, so it **respects the silent switch** and mixes with the
  user's music. Android: the media stream, and it ducks when focus is lost.
- Settings: master on/off, plus separate **Ambience/Music** and **Effects** volumes. Defaults:
  effects on at 60%, ambience on at 35%. Reviewers should *hear* it on first run, but quietly.
- Loudness: normalise effects to about -16 LUFS and ambience to about -24 LUFS. Ship OGG
  (Android/web) or M4A (iOS), mono, under 1 s for UI cues.
- A `/dev/sound` board plays every cue. Unit-test the throttling and cue mapping.

## The cue sheet
| Moment | Feeling | Cue |
| --- | --- | --- |
| **Dialogue subtitles typing** | Presence, rhythm | Soft, muted key tick on every 2nd–3rd character, random pitch ±6%, max 18 per second, silent on spaces and punctuation. A slight pause tick on "…". Stops instantly when tapped to complete. **Different timbre per interviewer** (Priya lighter, Marcus woodier, Lena drier, Sam deeper). |
| App open / title | Curiosity | A low, distant city hum and a single soft piano note that doesn't resolve |
| Chapter title card | Anticipation | A slow swelling pad, then one deep "boom" as the title settles |
| Elevator between missions | What happens next | Doors close (soft thud), hum, floor counter ticks, chime, doors open |
| Room ambience (loops) | Place | Ch1: warm lobby air and a faint office murmur. Ch2: colder, tighter drone. Ch3 boardroom: deep low drone and a slow clock |
| **The question lands** (camera cut) | **Suspense** | Short reverse whoosh into a held low tone; the ambience ducks by 40% |
| Answering (soft timer) | Rising tension | A quiet heartbeat-like pulse that speeds up slightly as the light dims; a clock tick in the last 10 s only. **Mission 1 is untimed, so no tension bed.** |
| Choice hover/select | Control | A soft wooden tap |
| Answer locked in | Commitment | A card-on-table thud and a short silence before the reaction |
| **Interviewer's follow-up challenge** | **Suspense** | A single dissonant low string pulse; for Lena, a sharper one |
| Trust goes up / down | Feedback | A warm, rising two-note shimmer / a low, soft descending note (gentle, not a buzzer) |
| Debrief file slides in | Reveal | A paper slide on wood |
| Each score stamped | Satisfaction | A stamp thud (paired with a haptic) and a short count-up tick |
| Strong result | Reward | A warm, resolving chord |
| Weak result | Encouragement | A neutral, soft, unresolved tone ("try again" energy, not failure) |
| Skill unlocked | Delight | A glassy rising shimmer and a soft bell |
| **Chapter-end cliffhanger** | **Curiosity / what's next** | The music stops mid-phrase on an unresolved chord; a single heartbeat; silence; then a quiet phone-buzz from the next interviewer |
| Locked floor tapped (tower) | Mystery | A muffled, distant version of the next chapter's ambience, heard "through the door" |
| Recall Room open | Focus | A soft low pad, a little brighter than the missions |

## Sourcing (licensing is a hard rule)
- **Only** CC0 or royalty-free commercial sounds: Kenney.nl (CC0 UI and impact packs), Pixabay
  Sound Effects / Music (Pixabay licence), Freesound **CC0-filtered** only.
- **Or synthesise** the simple ones (ticks, pulses, drones) in a script, so they're original.
- Every file goes in `docs/audio-credits.md`: file, source URL, licence, edits. No unlicensed or
  "found online" audio.
- The owner (Sami) approves the final set by ear on the `/dev/sound` board.
