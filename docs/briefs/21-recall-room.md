# Brief 21: the Recall Room (worktree w4)

From the lead (thelastroom-w1-ba), 2026-10-31, at the owner's request. Worktree
`../thelastroom-w4`, branch `feat/21-recall-room` from `origin/main`. Worker: thelastroom-9a.
This file is the brief as received, plus the worker's design notes (marked).

## Goal

Players learn from their mistakes in a fun loop. The tower shows "Recall Room · coming soon"
today. Every "You fell for: <trap>" and every costly line from a mission becomes a recall card.
The Recall Room serves short, fun rounds (about 5 cards, about 60 s) on a Leitner schedule
(`packages/engine/lib/src/recall.dart` already has the boxes).

## The card is active, not reading

- The player sees a line or a misconception and picks which principle beats it: one tap, the
  same vivid cards.
- Guesses are timed exactly as in missions (`decidedIn` + `isGuess`).
- A correct answer promotes the card; a wrong one demotes it.
- A streak/progress ring sits at the top.

Data comes from the merged content: `Reason.tempts`, the sound principles, and lessons.

## Owns

- `packages/engine`: the recall rules and tests. Keep it pure.
- `packages/content`: only if a card needs data.
- `apps/mobile/lib/features/recall/**` (new), with its route registered in `app/router.dart`.
  That's one additive line; 1e also edits `router.dart` on brief 20, so coordinate.
- The tower's Recall Room card: it only opens the room and shows a due-cards count. Tell 1e.

Persist the schedule locally (`shared_preferences`, or the drift db if 08's store fits). Use the
`lib/ui/vivid` kit, `BrandVivid` and `ChapterVivid`. Register analytics events first (the enum
plus `docs/EVENTS.md`, appended at the end). local-review, then ship; send the lead the PR link
when it's green. The phone is shared: ask the lead for it.

## Design notes (worker)

- **Where cards come from:** the stored attempts, read through `ProgressRepository`, so no
  mission or debrief file changes. Attempts store the picked option ids. Since brief 19, every
  weak beat line is tempted by exactly one misconception, so the trap the player fell for is
  derived from the line: card id = that reason's id. A costliest follow-up reply (which has no
  why step) gives a lesson card from its lesson's existing `RecallCheck`: card id = the lesson id.
- **The trap card:** "You fell for: <misconception>", with the weak line underneath. The player
  picks the principle that beats it, from the beat's sound principle plus two other
  misconceptions, in a seeded order.
- **Scheduling (engine):** cards are keyed by a card id (a reason or lesson id). Correct after
  thinking: up a box (1 → 3 → 7 days), then retired. Wrong: back to box one. **Correct but
  guessed** (under 1.5 s): not promoted, stays in its box, due tomorrow. Falling for the same
  trap again in a later mission puts a retired or promoted card back in box one.
- **New cards are due the same day**, so the room has something to play right after the first
  mission (a reviewer's first session). FR-16 said "due tomorrow"; flagged to the lead.
- **Round size:** 5 cards (`recallSessionCardLimit`, was 6).
- **Storage:** `shared_preferences`, one JSON document of cards plus the attempt ids already
  turned into cards. The drift store holds attempts, not schedules, and a new table is a
  migration for little gain.
