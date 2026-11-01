# Brief 29: close out the plan (worktree w4)

From the lead (thelastroom-w1-ba), 2026-11-01. Worktree `../thelastroom-w4`, branch
`docs/29-completion-audit` from `origin/main`. Worker: thelastroom-9a. The owner wants every
stage complete before any new ideas.

## In scope

1. **Requirements audit** (start here; send the lead the gap list **early**, before the PR).
   - Go through every FR and NFR in `docs/requirements.md` and every phase row in
     `docs/v1-plan.md` (01–15).
   - Mark each Built (with its PR #), Partly or Not built, in a new table, `docs/completion.md`.
   - For each gap, say whether it's a deliberate cut (cite the ADR or decision) or still missing.
   - Known suspects: FR-15 "Say it your way" free text, email linking (brief 08), FR-23, the
     paywall mock that phase 15 mentions for `SUBMISSION.md`, iOS notifications, NFR-3
     performance.
2. **Demo video script** (`docs/demo-script.md`) for the owner's screen recording: a 2–3 minute
   shot list, in order, with what to tap and one line of narration per shot. It covers:
   - first launch → onboarding → tower;
   - Mission 1: a guess called out, the why step, the build mode in Mission 4, the debrief's "You
     fell for";
   - the Recall Room, Your file, the Chapter 1 report;
   - themes;
   - AI scoring ("Scored by AI"), with a fallback line if it isn't run live.
3. **The paywall mock,** if it's in scope (check phase 15 and the brief): add it to
   `SUBMISSION.md` as described there.

## Owns

`docs/` (`completion.md`, `demo-script.md`, `SUBMISSION.md`). No app code.

## Done when

local-review, then ship; the lead gets the PR link.
