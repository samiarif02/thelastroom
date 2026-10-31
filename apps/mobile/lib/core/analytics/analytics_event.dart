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
  towerOpened('tower_opened'),
  roomEntered('room_entered'),
  missionStarted('mission_started'),
  missionCompleted('mission_completed'),
  baselineRecorded('baseline_recorded'),
  draftCompleted('draft_completed'),
  answerTimerExpired('answer_timer_expired'),
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
  userActivated('user_activated'),

  /// The player leaves a mission part-way (back button, "Leave"); the attempt is kept.
  missionLeft('mission_left'),

  /// The player picks up a mission they left ("Continue where you left off").
  missionResumed('mission_resumed'),

  /// The Recall Room opens (brief 21), with how many cards are due.
  recallRoomOpened('recall_room_opened'),

  /// One recall card answered: its kind, how the answer counted, and the box it was in.
  recallCardAnswered('recall_card_answered'),

  /// The debrief asks the AI recruiter to score the answer (brief 22).
  aiScoreRequested('ai_score_requested'),

  /// The AI's verdict is on the dossier.
  aiScoreShown('ai_score_shown'),

  /// No AI verdict (no backend, offline, a timeout or an error): the engine's "Offline score".
  aiScoreFallback('ai_score_fallback');

  const AnalyticsEvent(this.wireName);

  /// The name sent to the analytics backend.
  final String wireName;
}
