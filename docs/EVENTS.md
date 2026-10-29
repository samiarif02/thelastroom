# Events

The analytics registry (brief §11). The source of truth is the `AnalyticsEvent` enum in
`apps/mobile/lib/core/analytics/analytics_event.dart`; this table is its documentation, and
`npm run check:events` fails if they disagree. Register an event here and in the enum **before**
building the feature that fires it. Rules: `docs/rules/analytics.md`.

Properties are ids, enums, numbers and booleans. **No personal data, never any answer text.**
Property values below are planned; they're fixed when each feature's spec is written.

| Event | Fired when | Properties |
| --- | --- | --- |
| `intro_completed` | The 3-screen intro finishes (or is skipped) | `skipped` |
| `guest_started` | Anonymous sign-in succeeds on first launch | |
| `account_linked` | A guest links email or Google | `provider` |
| `onboarding_completed` | The post-Mission-1 onboarding finishes | `nerves_level`, `has_interview_date` |
| `mission_started` | A mission scene starts | `mission_id`, `chapter`, `attempt_number` |
| `mission_completed` | A mission's debrief is shown | `mission_id`, `chapter`, `score_bucket`, `attempt_number` |
| `baseline_recorded` | Mission 1's first completion stores the baseline | `score_bucket` |
| `follow_up_answered` | The player answers the interviewer's follow-up | `mission_id`, `follow_up_id` |
| `recall_session_completed` | A Recall Room session ends | `cards`, `correct`, `box_moves` |
| `skill_unlocked` | A skill is demonstrated in an unhinted mission | `skill_id` |
| `chapter_completed` | The chapter's review mission is completed | `chapter`, `score_delta_bucket` |
| `progress_report_viewed` | The report vs. baseline is opened | `source` |
| `coach_feedback_requested` | "Say it your way" is sent to the AI coach | `mission_id`, `remaining_today` |
| `notification_permission_prompted` | The custom pre-prompt is shown | |
| `notification_permission_granted` | The OS permission is granted | |
| `notification_opened` | A local notification is tapped | `type`, `variant` |
| `waitlist_joined` | The player joins the Chapter 2 waitlist | |
| `user_activated` | The first `mission_completed` for a user | |
