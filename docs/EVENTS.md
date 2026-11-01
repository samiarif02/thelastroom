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
| `account_linked` | A guest links email or Google | `provider` |
| `onboarding_completed` | The first-launch onboarding finishes, before the Tower (brief 13). Never the name | `skipped_steps`, `named`, `experience`, `target_role`, `nerves_level`, `calm_mode`, `weekly_goal` |
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
| `chapter_completed` | The chapter's review mission is completed | `chapter`, `score_delta_bucket` |
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
| `ai_score_shown` | The AI's verdict is shown on the dossier | `mission_id`, `score_bucket` |
| `ai_score_fallback` | No AI verdict, so the dossier shows the engine's "Offline score" | `mission_id`, `reason` (`noBackend`, `noSession`, `timeout`, `limited`, `error`) |
| `answer_built` | The player locks in an answer built from fragments (brief 27) | `mission_id`, `beat`, `fragments`, `missing`, `out_of_order`, `decoy_used`, `guessed` |
