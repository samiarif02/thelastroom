/// The event registry (brief §11, docs/EVENTS.md). An event that isn't a value of this enum
/// can't be fired: `Analytics.track` only takes these. Register the event here and in
/// docs/EVENTS.md before building the feature that fires it; `check:events` keeps the two in
/// step and bans string event names anywhere else.
///
/// Names are `object_action`, snake_case, past tense. Properties are ids, enums, numbers and
/// booleans only: no personal data and never any answer text (docs/rules/analytics.md).
enum AnalyticsEvent {
  introCompleted('intro_completed'),
  guestStarted('guest_started'),
  accountLinked('account_linked'),
  onboardingCompleted('onboarding_completed'),
  missionStarted('mission_started'),
  missionCompleted('mission_completed'),
  baselineRecorded('baseline_recorded'),
  followUpAnswered('follow_up_answered'),
  recallSessionCompleted('recall_session_completed'),
  skillUnlocked('skill_unlocked'),
  chapterCompleted('chapter_completed'),
  progressReportViewed('progress_report_viewed'),
  coachFeedbackRequested('coach_feedback_requested'),
  notificationPermissionPrompted('notification_permission_prompted'),
  notificationPermissionGranted('notification_permission_granted'),
  notificationOpened('notification_opened'),
  waitlistJoined('waitlist_joined'),

  /// The first `mission_completed` for a user: the activation event.
  userActivated('user_activated');

  const AnalyticsEvent(this.wireName);

  /// The name sent to the analytics backend.
  final String wireName;
}
