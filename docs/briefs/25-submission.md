# Brief 25: comms and demos, the submission package (worktree w4)

From the lead (thelastroom-w1-ba), 2026-11-01. Worktree `../thelastroom-w4`, branch
`docs/25-submission` from `origin/main`. Worker: thelastroom-9a.

## Why

The owner's first review scored Comms 12/15 and Demos 3/10. The owner records the demo video
themselves, and nothing is hosted on the web, so the repo has to sell itself to a reviewer in
five minutes.

## In scope

1. **Rewrite `README.md`** for a reviewer with 5 minutes:
   - what the game is, with 4–6 screenshots from `~/Downloads/thelastroom-ui-31oct/` (copy the
     best into `docs/screenshots/`);
   - a 3-command run guide;
   - how scoring works: the AI score online (Gemini as a senior recruiter, and why) and the
     rule-based offline score;
   - the architecture at a glance, linking the ADRs;
   - honest limits.
2. **`docs/SUBMISSION.md`** (8x asks for it):
   - what was built and why;
   - the key decisions, with links to ADRs and PRs;
   - how to run it, and what the score is based on;
   - what's next;
   - where the Claude logs are, including the 1 Nov logging fix (PRs #27 and #28);
   - a placeholder line for the owner's demo video link.
3. **APK:** a GitHub Actions workflow (or a documented script) that builds the release APK, and
   a **draft** GitHub release (`gh release create --draft`) with the APK and notes. Draft only:
   the owner decides when to publish it.

## Owns

`README.md`, `docs/SUBMISSION.md`, `docs/screenshots/`, the new release workflow. CI's `ci.yml`
stays unchanged unless needed; if it changes, keep `local-review` in step.

## Done when

local-review, then ship; the lead gets the PR link.
