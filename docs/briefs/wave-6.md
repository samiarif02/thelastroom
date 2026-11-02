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

- One voice mission: **the last mission in the game (Mission 8, a Chapter 2 preview), mixing
  both** spoken answers and the multiple-choice beats. The rest of Chapter 2 stays "coming soon".
- The landing page is Next.js, deployed on Vercel. ADR 0005's "no hosted demo" is about the
  game; a static marketing page is a separate decision (ADR 0007, brief 34).
- The demo video is done. Nothing in this wave touches it.

## The four briefs

| Brief | Worktree | Session | Owns |
| --- | --- | --- | --- |
| 33 professional UI, one look everywhere | `../thelastroom-w1` | thelastroom-de | `packages/brand`, `apps/mobile/lib/ui`, `features/{tower,onboarding,progress,progression,title,intro,settings,recall}`, the *visual* side of `features/{mission,debrief}`, goldens |
| 34 landing page (Next.js, `web/`) | `../thelastroom-w3` | background agent of thelastroom-w4-fe | `web/**` (new), the CI `web` job + its `local-review` mirror, ADR 0007 |
| 35 one voice mission | `../thelastroom-w2` | thelastroom-75 | `features/voice/**` (new), the voice mission in `packages/content`, `supabase/functions/score-voice/**` (new), mic/TTS permission lines in `android/` and `ios/`, its pubspec lines |
| 36 scoring you can trust | `../thelastroom-w4` | thelastroom-w4-fe | `supabase/functions/score/**`, `features/debrief/scoring_basis*.dart` (new) + one insertion in `debrief_view.dart`, the eval set and report, README "How the score works" |

**The contract** (committed on `lead/wave-6`, every branch starts there): `Mission.practises`,
one line per mission saying what it teaches, filled for Missions 1–7. 33 shows it before the
mission; 36 shows it on the debrief; 35 writes one for the voice mission.

**Shared files, append-only:** `AnalyticsEvent` + `docs/EVENTS.md` (append at the end),
`apps/mobile/pubspec.yaml` + `pubspec.lock` (35 only), `router.dart` (35 adds one route).
`debrief_view.dart`: 36 inserts one widget call, 33 owns the rest; tell each other before
touching it.

**Merge order:** 36 → 33 → 35 → 34 (34 is independent). The later branch rebases on `main` and
reruns the gates. 35 builds on today's tokens and components only (no new colours), then adopts
33's look after 33 merges.

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
