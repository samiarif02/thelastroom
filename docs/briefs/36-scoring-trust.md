# Brief 36: Scoring you can trust (worktree w4)

Lead: thelastroom-w4-fe, 2026-11-02. Worktree `../thelastroom-w4`, branch
`feat/36-scoring-trust` from `origin/lead/wave-6`. Session: thelastroom-w4-fe (lead and worker).
Read `docs/briefs/wave-6.md` first. **PR green by Tue 3 Nov, 12:00** (it merges first).

## Why

The reviewer asked two questions: *on what basis does the AI score the player?* and *how are you
sure it scores well?* The README answers part of the first; the app barely shows it, and nothing
answers the second. And the AI scoring has only ever run against a mocked Gemini in tests (on
purpose: CI must never hold the key): it has never been run with the owner's real key.

## In scope

1. **A live run with the owner's key.** `supabase start`, `supabase functions serve score
   --env-file ../thelastroom/.env` (the CLI reads the key; no agent reads the file), a guest
   session, a real Mission 1 answer. Paste the verdict (scores + basis, no key, no JWT) in the PR.
   Fix whatever the real model does that the mock didn't.
2. **"How we scored this"** on the debrief: a sheet opened from the score. The four dimensions
   and their weights; the recruiter's one-sentence basis for each number; the offline engine's
   score beside it, with one line on how they differ; what the AI is told and never told (no
   name, nothing typed); the line "We score what you said, not how you sound". Also shows
   `Mission.practises`: what this mission was practising.
3. **An evaluation set** that answers "how do you know it scores well?":
   `supabase/functions/score/eval/`: about 20 answers across the missions, from strong to weak
   (built from the content's own options, so each has an engine score and an author's intended
   band), each with an expected range per dimension. A script runs them through the live
   function N times and writes `docs/scoring-eval.md`: agreement with the expected bands, the
   spread between repeated runs (consistency at temperature 0), and the correlation with the
   engine. Results published as they are, good or bad, with what we changed because of them.
4. **README "How the score works"**: link the eval report and the in-app sheet.

## Owns

`supabase/functions/score/**`, `features/debrief/scoring_basis*.dart` (new) and one insertion in
`debrief_view.dart` (tell thelastroom-de), the eval set and `docs/scoring-eval.md`, the README
section, an appended event (`score_basis_viewed`, `source`), `docs/status/36.md`.

## Acceptance

- [ ] A live verdict from the real key in the PR.
- [ ] The sheet opens from every debrief, AI or offline, and passes 2x text and reduced motion.
- [ ] `docs/scoring-eval.md` with real numbers from real runs.
- [ ] All gates (incl. the db job), CI green.
