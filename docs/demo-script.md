# Demo video script

A 2½-minute screen recording for the owner. Phone in portrait, sound on (the game has its own
sound), Do Not Disturb on, the default theme (Evening Forest). One line of narration per shot;
say it over the shot or add it as a caption.

**Two takes, edited together.**
- **Take A** is a fresh install (clear the app's data first), for the first launch and Mission 1.
- **Take B** is a phone with Chapter 1 finished, for Mission 4, the Recall Room, Your file, the
  report and themes.

Android's built-in screen recorder, or `scrcpy --record demo.mp4` with audio, both work.

## Take A: first launch to the first debrief (about 1:40)

| # | Time | Screen | What to do | Narration |
| --- | --- | --- | --- | --- |
| 1 | 0:00 | Splash, animated title | Nothing; let it play | "The Last Room: an interview-practice game that plays like a film." |
| 2 | 0:08 | Onboarding: "One room left between you and the offer." → "Meet your interviewers." → "What should we call you?" | Next, Next, type a first name, "Let's go" | "No sign-up. Three screens and a first name that never leaves the phone." |
| 3 | 0:20 | The tower, "UP NEXT · MISSION 1" | Tap **Play** | "Your search for a job is a tower. One tap to play." |
| 4 | 0:26 | Priya's office: her lines type out with a tick per letter | Tap once to complete a line if it's slow | "Priya, the recruiter, asks why you applied." |
| 5 | 0:34 | The first four answers appear | **Tap one immediately**, in under a second | "Tapping at random doesn't work. Pick in under one and a half seconds and it's a guess: that beat scores nothing…" |
| 6 | 0:38 | Priya: "That was quick, *your name*. Slow down, I've got time." | Wait for the line | "…and she notices." |
| 7 | 0:44 | The evidence beat | **Read**, then pick the strongest line ("I interviewed twelve students… from 40% to 75%"); Priya: "Twelve interviews, two screens, 75%. That's what I wanted." | "Now properly: one story, my own part, a number." |
| 8 | 0:52 | "Why that example?" with four reasons | Pick **"One story with my own part and a number beats a list of strengths."** | "Then she asks why. The reasons are interviewing principles: one holds, the others are the traps people fall for." |
| 9 | 1:04 | The land beat, then Priya's reaction and her follow-up | Pick a line, then pick a reply | "She reacts, then pushes on the weakest part of the answer." |
| 10 | 1:14 | Debrief: "The panel is deliberating…" → **"Scored by AI · Senior recruiter"** | Let it land; hold on one dimension's basis sentence | "A senior-recruiter AI grades the answer, with one sentence of basis for every number." |
| 11 | 1:24 | Scroll to **YOUR REASONING**: "GUESSED IN 0.7 SECONDS", "You said", **"You fell for: …"**, "What holds" | Scroll slowly | "And every beat explained: the guess, what you said, the trap you fell for, and the principle that holds." |
| 12 | 1:36 | Back to the tower: the room lights up, and "Want Priya to remind you?" | "Not now" (or "Yes") | "Kind reminders, only if you ask: at most once a day, never after nine." |

**If AI scoring isn't running live** (no laptop backend), shot 10 shows **"Offline score"**
instead. Narrate: *"Offline, the built-in engine scores it. With the backend running, a Gemini
senior recruiter scores it instead, with a reason for every number."* Don't fake it; the
README says AI scoring has only been verified against a mocked model so far.

## Take B: the rest of the game (about 1:00)

| # | Time | Screen | What to do | Narration |
| --- | --- | --- | --- | --- |
| 13 | 1:40 | Mission 4 with Marcus, a **build** beat: fragments as chips | Tap the fragments in the order you'd say them, leave the vague one out, then **Lock it in** | "Some answers you build: tap the pieces in the order you'd say them, and leave out the one that sinks you." |
| 14 | 1:52 | The tower's **Recall Room** card, "3 CARDS DUE" | Tap it | "Every trap you fell for comes back…" |
| 15 | 1:56 | A Recall Room card: "YOU FELL FOR" and the line it led to | Read, then pick the principle that beats it; the ring fills and the streak counts | "…as a one-minute round on a 1, 3, 7-day schedule, until it stops catching you." |
| 16 | 2:08 | **Your file**: missions with stars, "Scored by AI" or "Offline score", the skills radar | Scroll | "Your file: every mission, how it was scored, and your skills." |
| 17 | 2:16 | **Chapter 1 report**: first try against the review, two radars, Chapter 2's locked rooms | Scroll to the end | "The Chapter 1 report: your first answer beside your last. Chapter 2 is next." |
| 18 | 2:24 | Settings → **Theme** | Tap Sunset City, Ocean Night, Morning Light, back to Evening Forest | "Four themes, switched live." |
| 19 | 2:32 | The tower | Hold | "Clone it and run it: no keys, no account, fully offline. github.com/samiarif02/thelastroom" |

## Checklist before recording

- [ ] Take A: clear the app's data, so it's a true first launch.
- [ ] Take B: Chapter 1 finished (Mission 7 done) and at least one trap due in the Recall Room
      (fall for one in a mission the same day).
- [ ] Sound on, at a comfortable volume; notifications silenced.
- [ ] The AI backend running on the laptop if you want shot 10 live (README, "Optional: the
      backend and AI scoring"); otherwise use the fallback line.
- [ ] Put the link in `docs/SUBMISSION.md` (first line) and the README header.
