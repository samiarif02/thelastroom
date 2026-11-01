# Brief 30: Chapter 1 playthrough, then fixes (worktree w2)

Lead session (w1-ba), 2026-11-01. Branch `fix/30-playthrough` from `origin/main`. Session:
thelastroom-w2-c1. Recorded here from the lead's message. v1-plan phase 14.

## Why

The owner wants the whole flow complete. Nobody has played Chapter 1 end to end as a new player.

## In scope

1. **Play it all as a brand-new player** in headless Chrome at 411×914 (muted), fresh profile, no
   local-only patches:
   - title → Begin → onboarding (3 steps, name) → tower;
   - Missions 1–7 in order, mixing strong, weak and guessed answers, and the build mode in 4, 6
     and 7;
   - every debrief; Mission 7 → the Chapter 1 report → the Chapter 2 teaser and the waitlist;
   - the Recall Room after Missions 1 and 3; Your file; Settings (theme, sound, reminders);
   - back from every screen; a relaunch mid-mission → Continue.
2. **Write down every bug or rough edge** (dead button, wrong text, overflow, state not saved,
   missing sound cue, wrong "up next"…) in `docs/status/30.md`, with screenshots.
3. **Fix them** in `features/mission`, `debrief`, `progress` and `tower`. For other areas, message
   the owner session (1e: brand/ui/settings/title; 9a: engine/content/notifications) and the lead.

## Done when

local-review green, PR open (never merged), link and a short bug list sent to the lead.
