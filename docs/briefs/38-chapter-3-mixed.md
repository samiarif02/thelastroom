# Brief 38: Chapter 3, "The Final Round", voice and choices mixed (worktree w6)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w6`, branch
`feat/38-chapter-3-mixed` from `origin/lead/wave-6`. Written by a background agent of
thelastroom-w4-fe. Read `docs/briefs/wave-6.md` and brief 35 first. **PR green by Tue 3 Nov,
22:00.** Rebase on 37 if it merges first (both touch the `missions` list and `lessons.dart`).

## Why

The owner (2026-11-02): Chapter 3 mixes multiple-choice and voice missions. The final round
tests both knowing a strong answer and saying one.

## In scope

Seven missions (numbers 15–21, `chapter: 3`), titled exactly as `chapters.dart` teases them:

| # | Title | Mode | Why this mode |
| --- | --- | --- | --- |
| 15 | Solve the Problem | choices | structure is the skill; options show the shapes |
| 16 | The Interruption | voice | recovering mid-sentence has to be spoken |
| 17 | "I Don't Know" | voice | admitting a gap well is about how you say it |
| 18 | The Salary Question | choices | the traps (a number too early, no range) are best seen side by side |
| 19 | Your Turn to Ask | choices | choosing good questions to ask |
| 20 | The Final Interview | voice | the whole answer, out loud |
| 21 | The Decision | voice | the last room: closing the interview |

- **Choices missions** are built exactly like Chapter 1's (three beats of 3–4 plausible options,
  the "why" reasons and reactions, follow-ups by flag, lessons, the build step where Chapter 1
  uses one); study `m01`–`m07` and keep their quality bar: distractors are realistic mistakes,
  never jokes.
- **Voice missions** follow brief 37's pattern (`VoicePrompt`, 3–4 `listenFor` points, a spoken
  follow-up, a lesson).
- Every mission has its `practises` line. The Decision (21) is the last room: the offer
  conversation's close, and a short epilogue.

Flip Chapter 3 to `playable: true` once all seven validate. Content tests as in brief 37, plus
the existing choices-mission checks.

## Owns

`packages/content/lib/src/data/missions/m15…m21*.dart` (new), additions to `lessons.dart` and
`interviewers.dart`, the `missions` list and `chapters.dart` entry for Chapter 3, content tests,
`docs/status/38.md`. Nothing in `apps/` or `supabase/`.

## Acceptance

- [ ] Seven missions validate (three choices, four voice); `dart test` green.
- [ ] All gates, CI green. Never merge.
