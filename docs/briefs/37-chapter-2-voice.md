# Brief 37: Chapter 2, "Under Pressure", all voice (worktree w5)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w5`, branch
`feat/37-chapter-2-voice` from `origin/lead/wave-6`. Written by a background agent of
thelastroom-w4-fe. Read `docs/briefs/wave-6.md` and brief 35 first. **PR green by Tue 3 Nov,
20:00.**

## Why

The owner (2026-11-02): Chapter 2 is entirely spoken. The player has learned *what* a strong
answer is in Chapter 1; now they say one, under more pressure.

## In scope

Seven voice missions (numbers 8–14, `chapter: 2`, `answerMode: AnswerMode.voice`), titled
exactly as `chapters.dart` teases them: Team Conflict, The Failure, No Clear Instructions, Tight
Deadline, The Uncomfortable Request, The Unexpected Follow-Up, Panel Review. Each one:

- `practises`: one line on what it teaches.
- 1–3 scene lines and a question from the cast (`interviewers.dart`; Marcus and Lena carry
  more of this chapter; add an interviewer only if the cast needs one, with its silhouette id).
- `VoicePrompt`: 3–4 `listenFor` points (each a thing a strong answer *does*, tied to the
  dimension it earns, phrased so a player can tick it in the self-check), a spoken follow-up
  that pushes on the most common miss, 1–3 points for the reply, and a lesson (reuse Chapter 1's
  lessons where they fit; add new ones with recall checks where they don't).
- The answers draw on the player's own experience now (it's their voice, not Jordan's CV), so
  the question tells them they can use their own story or the practice CV.
- Panel Review (14) is the chapter's review: two interviewers, every Chapter 2 skill.

Flip Chapter 2 to `playable: true` once all seven validate. Content tests: every mission
validates, numbers and titles match the chapter, each mission's points cover at least three
dimensions, no figure outside the character sheet's set.

## Owns

`packages/content/lib/src/data/missions/m08…m14*.dart` (new), additions to `lessons.dart` and
`interviewers.dart`, the `missions` list and `chapters.dart` entry for Chapter 2, their content
tests, `docs/status/37.md`. Nothing in `apps/` or `supabase/`.

## Acceptance

- [ ] Seven voice missions validate; `dart test` in `packages/content` green.
- [ ] Copy in the Chapter 1 voice: plain, specific, a real recruiter, no clichés.
- [ ] All gates, CI green. Never merge.
