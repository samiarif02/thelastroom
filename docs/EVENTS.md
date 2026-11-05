# Events

The analytics registry (brief §11). The source of truth is the `AnalyticsEvent` enum in
`apps/mobile/lib/core/analytics/analytics_event.dart`; this table is its documentation, and
`npm run check:events` fails if they disagree. Register an event here and in the enum **before**
building the feature that fires it. Rules: `docs/rules/analytics.md`.

Properties are ids, enums, numbers and booleans. **No personal data, never any answer text.**
The type enforces it: `track` takes `Map<String, EventValue>`, and `EventValue` has no
constructor that accepts a `String` (`apps/mobile/lib/core/analytics/event_value.dart`). An id
comes from a content item (`EventValue.id(mission)`), anything else that varies is an enum.
Property values below are planned; they're fixed when each feature's spec is written.

**The Mission 1 slice (milestone 10)** fires `intro_completed`, `mission_started`,
`draft_completed`, `answer_timer_expired`, `follow_up_answered`, `mission_completed`,
`baseline_recorded` and `user_activated`. `draft_completed` and `answer_timer_expired` were
added in brief 02 because the slice couldn't be measured without them (`docs/v1-plan.md`).

| Event | Fired when | Properties |
| --- | --- | --- |
| `intro_completed` | The 3-screen intro finishes (or is skipped) | `skipped` |
| `guest_started` | Anonymous sign-in succeeds on first launch | |
| `account_linked` | A guest links an email in Settings ("Save your progress", FR-3): the app sees the emailed link was tapped; the user id stays the same. Never the email | `provider` (`email`) |
| `account_signed_in` | "Sign in on another device" (FR-3): a player opens the emailed sign-in link on this device, it signs in to their saved account, and this device's progress merges with it. Never the email | `provider` (`email`), `had_progress` |
| `account_signed_out` | "Sign out" on a saved account in Settings (FR-3): every room had backed up (sign-out is blocked otherwise), the account stays saved to its email, and this device's player data is cleared and a new guest starts. Never the email | `had_unsynced` (always `false`: an unsynced device can't sign out) |
| `onboarding_completed` | The first-launch onboarding finishes, before the Tower (brief 13). Never the name | `skipped_steps`, `named`, `experience`, `target_role`, `nerves_level`, `calm_mode`, `weekly_goal` |
| `onboarding_explainer_viewed` | The "How it works" explainer (five pages before onboarding's questions, issue 75) ends: "Let's get you ready" on the last page, Skip, or, when replayed from Settings, closed. Once per showing | `page` (the furthest page reached, 1 to 5), `skipped`, `replay` |
| `tower_opened` | The Tower (home) is shown | `missions_done`, `after_mission` |
| `room_entered` | The player enters a room on the Tower (the elevator starts) | `mission_id`, `replay` |
| `mission_started` | A mission scene starts | `mission_id`, `chapter`, `attempt_number` |
| `mission_completed` | A mission's debrief is shown | `mission_id`, `chapter`, `score_bucket`, `attempt_number` |
| `baseline_recorded` | Mission 1's first completion stores the baseline | `score_bucket` |
| `draft_completed` | The player leaves the "draft first" step, by sending a draft or skipping | `mission_id`, `skipped` |
| `answer_timer_expired` | The soft 60-second timer runs out on a beat (never fires in calm mode) | `mission_id`, `beat` |
| `follow_up_answered` | The player answers the interviewer's follow-up | `mission_id`, `follow_up_id` |
| `recall_session_completed` | A Recall Room session ends | `cards`, `correct`, `box_moves` |
| `skill_unlocked` | A skill is demonstrated in an unhinted mission | `skill_id` |
| `chapter_completed` | A chapter's last mission (7, 14, 21) is completed for the first time | `chapter`, `score_delta_bucket` |
| `progress_report_viewed` | The progress screen (the report vs. baseline) is opened | `source` |
| `coach_feedback_requested` | "Say it your way" is sent to the AI coach | `mission_id`, `remaining_today` |
| `notification_permission_prompted` | The custom pre-prompt is shown | |
| `notification_permission_granted` | The OS permission is granted | |
| `notification_opened` | A local notification is tapped | `type`, `variant` |
| `waitlist_joined` | The player joins the Chapter 2 waitlist | |
| `user_activated` | The first `mission_completed` for a user | |
| `mission_left` | The player leaves a mission part-way (back, then "Leave"); the attempt is saved on the device | `mission_id`, `beat` |
| `mission_resumed` | The player continues a mission they left | `mission_id`, `beat` |
| `recall_room_opened` | The Recall Room opens, from the tower | `due_cards` |
| `recall_card_answered` | A Recall Room card is answered | `card_kind` (`trap`, `lesson`), `verdict` (`known`, `guessed`, `missed`), `box` (`one`, `three`, `seven`) |
| `ai_score_requested` | The debrief asks the AI recruiter (the `score` function) to score the answer | `mission_id` |
| `ai_score_shown` | The AI's verdict is shown on the dossier (`late`: it arrived after the offline score was showing, and the player tapped "The recruiter's score is ready" to swap it in; a late verdict never replaces the sheet on its own) | `mission_id`, `score_bucket`, `late` |
| `ai_score_fallback` | No AI verdict, so the dossier shows the engine's "Offline score" | `mission_id`, `reason` (`noBackend`, `noSession`, `timeout`, `limited`, `error`) |
| `answer_built` | The player locks in an answer built from fragments (brief 27) | `mission_id`, `beat`, `fragments`, `missing`, `out_of_order`, `decoy_used`, `guessed` |
| `score_basis_viewed` | The player opens "How we scored this" on the debrief (brief 36) | `mission_id`, `source` (`ai`, `offline`) |
| `voice_answer_recorded` | A spoken answer is submitted on a voice mission (brief 35), once per take: the answer, then the reply. Never audio or words | `mission_id`, `seconds`, `paused_count`, `retakes` |
| `voice_answer_scored` | A voice mission's answer is scored and its debrief shown | `mission_id`, `score_bucket`, `source` (`ai`, `selfCheck`) |
| `test_reminder_sent` | The player taps "Send a test reminder" in Settings and tomorrow's planned reminder is shown now (brief 42). Never its text | `type` (`recallDue`, `nudge`) |
| `welcome_back_shown` | The tower greets a player back after one or more calendar days away (brief 42), once per return | `days_away`, `target` (`recall`, `mission`, `progress`) |
| `welcome_back_closed` | The welcome-back card goes: its button was followed, or it was dismissed | `action` (`followed`, `dismissed`), `target` (`recall`, `mission`, `progress`) |
| `weekly_goal_closed` | A finished mission or Recall Room round brings the week's sessions up to the weekly goal, so the tower's ring closes (Daylight, moment 6). Once per week | `sessions`, `weekly_goal` |
| `recall_note_opened` | A Recall Room note (the taped card of a trap or a lesson) is shown, once per card per session | `card_kind` (`trap`, `lesson`), `box` (`one`, `three`, `seven`) |
| `floor_previewed` | A floor of the tower is opened as a sheet from Home (tapping the floor or one of its locked windows): its rooms, interviewers and how it's answered | `chapter`, `open` |
| `all_chapters_opened` | "View all chapters" under Northstar tower opens the chapters list (every floor with its rooms, played, up next or locked) | `missions_done`, `chapter` (the current floor) |
| `tip_shown` | A first-time tip (one line from the cast in a bubble, a spotlight on its target where there is one) is shown, once, the first time the player reaches its moment, or again after "Show tips again" in Settings. It replaces the tower tour's events (its door spotlight is the `towerDoor` tip) | `tip` (`towerDoor`, `answerCards`, `whyStep`, `firstResult`, `voiceMic`, `recallDue`, `yourFile`), `replay` |
| `tip_done` | A first-time tip is put away: its target was tapped (the door, a tab or the recorder then does its normal action; on answer or reason cards the tap only puts the tip away and picks nothing) or it was dismissed ("Got it", or a tap elsewhere) | `tip`, `action` (`followed`, `dismissed`) |
| `floor_card_shared` | The player taps "Share your floor card" on a floor-cleared screen (or the Chapter 1 report) and the share sheet closes, or sharing can't open. Never the card image or the player's name | `floor`, `outcome` (`shared`, `dismissed`, `unavailable`) |
| `promise_shown` | The debrief's dated promise card appears under the line that cost the most (brief 61), once per debrief: the real day this room's lines come back in the Recall Room (the engine's Leitner schedule, the same day the reminder plan counts them), or, with nothing to recall, the next room. Never its words | `mission_id`, `kind` (`recall`, `nextRoom`), `days_ahead` (0 for a next-room promise) |
| `first_day_shown` | The tower's first-day moment ("Day 1 of your prep": the weekly ring's first segment, the XP earned, tomorrow's hook) is shown after the player's first finished room ever (brief 61), once per device. The reminder explainer follows it if reminders were never offered | `recall_tomorrow` |
| `leaderboard_opened` | The leaderboard opens from the tower's tab bar, or the player switches its tab. Never a name, a tag, a rank or an XP figure | `tab` (`week`, `allTime`) |
| `leaderboard_visibility_changed` | "Show me on the leaderboard" is switched in Settings (on: other players see the first name and tag; off: hidden from them, the player still sees the board and their own rank) | `visible` |
