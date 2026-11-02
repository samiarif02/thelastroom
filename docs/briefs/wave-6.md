# Wave 6: professional, spoken, explained, and marketed

Written by thelastroom-w4-fe, acting as lead on the owner's instruction, 2026-11-02 (Mon), after
the owner's feedback session. **Submission is Thu 5 Nov. Every PR open, green and checked by Tue
3 Nov, 22:00.** Wed is merges, a realme check and the release; Thu is submission.

## What the reviewer said (owner's words, condensed)

- Overall good. **The UI should be professional, sleek and modern.** Our users are job-seekers,
  professionals; if the app looks like a children's game they'll assume the questions aren't
  serious and ignore it. Keep the Duolingo model (it's a game so nobody gets bored), but not a
  game *look*.
- **The screens disagree.** The mission title card ("CHAPTER 1 · GET THROUGH THE DOOR") looks
  fully professional; everything around it looks playful. A player is confused by two apps in
  one.
- **A marketing landing page**: what the app is, "coming soon on Google Play and the App Store",
  a nice UI and a clean architecture, in its own `web/` folder so it deploys to Vercel by picking
  that folder.
- **Answer by voice** from Chapter 2 on: no options, the player records a spoken answer, so they
  practise speaking in front of a recruiter. The recruiter's lines are **spoken aloud** (text to
  speech). Recording **pauses by itself after 5–6 s of silence**; **Continue** resumes from there;
  **Delete** throws the take away to record again.
- **"How does the AI score, and how do you know it scores well?"** Justify every number.
- **Think from the user's side:** what does the player *learn* from each mission?

## Owner's decisions (2026-11-02)

- **Chapter 2 is all voice (7 missions); Chapter 3 mixes voice and multiple-choice missions
  (4 voice, 3 choices).** Chapters 2 and 3 become playable. The voice player and its scoring are
  brief 35; the missions are briefs 37 and 38, written in parallel against the contract.
- The landing page is Next.js, deployed on Vercel. ADR 0005's "no hosted demo" is about the
  game; a static marketing page is a separate decision (ADR 0007, brief 34).
- The demo video is done. Nothing in this wave touches it.

## The four briefs

| Brief | Worktree | Session | Owns |
| --- | --- | --- | --- |
| 33 professional UI, one look everywhere | `../thelastroom-w1` | thelastroom-de | `packages/brand`, `apps/mobile/lib/ui`, `features/{tower,onboarding,progress,progression,title,intro,settings,recall}`, the *visual* side of `features/{mission,debrief}`, goldens |
| 34 landing page (Next.js, `web/`) | `../thelastroom-w3` | agent of thelastroom-w4-fe | `web/**` (new), the CI `web` job + its `local-review` mirror, ADR 0007 |
| 35 voice missions: the player and scoring | `../thelastroom-w2` | thelastroom-75 | `features/voice/**` (new), the engine's self-check scorer, `supabase/functions/score-voice/**` (new), the voice attempt store + migration, mic/TTS lines in `android/` and `ios/`, its pubspec lines |
| 36 scoring you can trust | `../thelastroom-w4` | thelastroom-w4-fe | `supabase/functions/score/**`, `features/debrief/scoring_basis*.dart` (new) + one insertion in `debrief_view.dart`, the eval set and report, README "How the score works" |
| 37 Chapter 2, all voice | `../thelastroom-w5` | agent of thelastroom-w4-fe | missions 8–14 in `packages/content`, Chapter 2 lessons and cast additions |
| 38 Chapter 3, mixed | `../thelastroom-w6` | agent of thelastroom-w4-fe | missions 15–21 in `packages/content`, Chapter 3 lessons and cast additions |

**The contract** (committed on `lead/wave-6`, every branch starts there):

- `Mission.practises`, one line per mission saying what it teaches, filled for Missions 1–7. 33
  shows it before the mission, 36 on the debrief; 37 and 38 write one for every new mission.
- `Mission.answerMode` (`choices` | `voice`) and `Mission.voice` (`VoicePrompt` with
  `ListenFor` points, a spoken follow-up, a lesson), validated by `validateContent`. 35 plays
  them; 37 and 38 write them.

**Shared files, append-only:** `AnalyticsEvent` + `docs/EVENTS.md` (append at the end),
`apps/mobile/pubspec.yaml` + `pubspec.lock` (35 only), `router.dart` (35 adds one route),
`packages/content` `missions` list, `lessons.dart`, `interviewers.dart` (37 and 38 append).
`debrief_view.dart`: 36 inserts one widget call, 33 owns the rest; tell each other before
touching it.

**Merge order:** 36 → 33 → 35 → 37 → 38 (34 any time). The voice player (35) must land before
the content that turns Chapters 2–3 playable, or the tower would offer missions nothing can
play. The later branch rebases on `main` and reruns the gates. 35 builds on today's tokens and
components only (no new colours), then adopts 33's look after 33 merges. 33 makes the tower
show every playable chapter's rooms from the data (Chapters 2–3 open when 37/38 flip them).

## Rules for every brief

- Read `AGENTS.md`, your brief, this file, `DESIGN.md` and the rule files for what you touch.
- Keep `docs/status/NN.md` current (done, half-done, next, decisions). Never `docs/HANDOFF.md`.
- **Prompts in your own words.** The reviewer flagged the Claude logs: no pasted walls of text,
  one goal per session, say what you decided and why. Logs are 15 points.
- Gates: the `local-review` skill (with the db job if you touch `supabase/`), then the `ship`
  skill: a real PR (not a draft), green CI. **Never merge.**
- UI changes: before/after stills (Chrome 390×844 is fine; the owner checks the realme) in
  `.pr-screenshots/<brief>/`.
- When your PR is green, message thelastroom-w4-fe with the link.
