# Retention: activation and the day 1, 3, 5, 7 and 8 loop

The reviewer asked (2 Nov): *"When someone opens your app, how are you activating them in a way
that they come back tomorrow?"* and *"What exactly brings the user back on day three, on day
seven?"* This page answers both. It covers what the player sees each day, the mechanism behind
it, and the events that measure it.

There are three rules. **No streak to lose**: the habit gauge is a weekly ring that closes
after any N days of the week (N is the player's goal, 3 by default), so a day off costs nothing.
**No guilt copy.** **At most one notification a day**, then silence (direction.md, "Reward and
retention").

## The mechanism, in one paragraph

Every mistake the player makes becomes a **Recall note** on a Leitner schedule
(`packages/engine/lib/src/recall.dart`): due the same day, then 1 day after a miss, 3 days after
the first right answer, 7 after the second, then retired. The pure engine also computes the
**dated promise** (`promise.dart`, `promiseAfterRoom`). That is the first day from tomorrow on
when a note is due, and it counts notes exactly the way the reminder plan does (every card due on
or before that day). So the debrief, the Recall Room, the welcome-back card and the notification
all name the **same day**. A test proves it: `test/features/debrief/room_promise_test.dart`
plans the real reminders from the same schedule. Local reminders (`core/notifications`) go out on
**days 1, 3, 5 and 8** after the last open, at the player's usual hour. They lead with Recall
when notes are due, otherwise the next interviewer nudges in character, and both count down to
the interview date if one is set.

## Day by day

| Day | What the player sees | Why they come back |
| --- | --- | --- |
| **0: install** | Room 1 is about 5 minutes. The debrief ends with the **dated promise** under the line that cost the most: *"Priya will bring this line back tomorrow. Room 2 opens now."* (a real date from the schedule; after a clean room, *"Room 2 opens now. Marcus has your next question."*). Back on the tower, room 1 lights up and the **first-day moment** plays once: Priya smiling in her arch, *"Day 1 of your prep"*, the weekly ring filling its first segment (1/3), the XP earned (and a skill, if one unlocked), and the hook *"Tomorrow: your first Recall note, about a minute, plus room 2."* Then, if reminders were never offered, the existing explainer asks: *"Want Priya to remind you?"* | A concrete, dated, two-minute task, promised by a person rather than a counter. The ring has started, and it only fills. |
| **1** | Reminder 1, Recall first: *"1 note is waiting in the Recall Room. Then room 2."* A tap opens the Recall Room. The tower shows the **welcome-back card** (notes due, the next room, *"1 of 3 this week"*), the Recall card with "due today", and a tab badge. | The note is fading, and the debrief said it would be here. One round is about a minute. |
| **3** | Reminder 2. If a note is due (one answered right on day 0 or 1 is back in box three around now), it's *"2 notes from your rooms are back. One minute to keep them. Then room 3."* If none is due, the next interviewer nudges in character (*"I'll want the numbers this time. Ready when you are."*). The welcome-back card says what's waiting, and with nothing due today it says when: *"Your next Recall note comes back on Saturday."* | The second Leitner box ("Marcus caught you on this one. Want another go?"), and a session here usually closes the week's ring. |
| **5** | Reminder 3. With an interview date set it leads with the countdown: *"5 days to your interview. Your next interview is waiting. Bring one real example."* The welcome-back card shows *"Interview in 5 days. One room makes a good warm-up."* | The interview is real and close. The ring has one session left to close. |
| **7** | Notes promoted on day 0 come back from box seven. The welcome-back card names them, or the day they're due. When the week's ring closes, the tower plays its sparks (`weekly_goal_closed`). | Proof the lesson stuck: a box-seven note answered right retires. |
| **8** | Reminder 4, the last. A longer gap, as FR-51 backs off. Then **silence** until the player opens the game again, which re-plans from that day. | Never a pile of ignored nudges. |

Any open re-plans the schedule. Whatever happened, the next four reminders run from that day.

## The events that measure it

All are registered in `AnalyticsEvent` and `docs/EVENTS.md`. They carry no personal data and no
answer text.

| Question | Events |
| --- | --- |
| Activation: did they finish room 1? | `mission_completed`, `user_activated` (the first one) |
| Did they see the hook? | `promise_shown` {`mission_id`, `kind`: `recall` or `nextRoom`, `days_ahead`}, `first_day_shown` {`recall_tomorrow`} |
| Did they opt in to reminders? | `notification_permission_prompted`, `notification_permission_granted` |
| Did a reminder bring them back? | `notification_opened` {`type`: `recallDue` or `nudge`, `variant`} |
| D1, D3 and D7 return | `tower_opened` and `welcome_back_shown` {`days_away`, `target`}, by install cohort |
| Did they keep the promise? | `recall_room_opened` {`due_cards`}, `recall_session_completed`, `recall_note_opened` {`box`} |
| The habit | `weekly_goal_closed` {`sessions`, `weekly_goal`} |

The funnel the reviewer asked about is `user_activated` → `first_day_shown` →
`notification_permission_granted` → `notification_opened` (day 1) → `recall_session_completed`,
with D3 and D7 read from `welcome_back_shown.days_away`. Feature code fires events through one
`Analytics` interface. Until PostHog is wired they go to the structured log, so **there are no
retention numbers yet, and none are claimed here.**

## Where it lives

- Engine: `packages/engine/lib/src/promise.dart` (`promiseAfterRoom`, `nextRecallDay`,
  `notesDueBy`) and `recall.dart` (the Leitner boxes), tested in `packages/engine/test/`.
- Debrief: `apps/mobile/lib/features/debrief/room_promise.dart` (the reading, the copy) and
  `promise_card.dart`. The card sits outside the Candidate assessment sheet and appears after its
  timeline; `ui/paper/**` is unchanged.
- First day: `apps/mobile/lib/features/progression/first_day.dart` and `first_day_moment.dart`.
  It shows once, then hands over to the existing `offerReminders`.
- Days 3 and 7: `features/tower/welcome_back.dart` (next note, interview countdown) and
  `core/notifications/reminder_plan.dart` (Recall reminders name the next room and count down).
- Stills: `.pr-screenshots/61/`, from `apps/mobile/test/features/debrief/stills/`.
