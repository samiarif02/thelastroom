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

  /// "Sign in on another device" (FR-3): a player who saved their progress on one device signs
  /// in on this one with an emailed code, and their saved file comes down. Never the email.
  accountSignedIn('account_signed_in'),

  /// "Sign out" on a saved account (FR-3): everything had backed up, the account stays saved
  /// to its email, and this phone starts again as a new guest. Never the email.
  accountSignedOut('account_signed_out'),
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
  aiScoreFallback('ai_score_fallback'),

  /// The player locks in an answer built from fragments (brief 27): how many they placed, and
  /// what cost points (parts missing, parts out of order, the decoy). Counts only, no text.
  answerBuilt('answer_built'),

  /// The player opens "How we scored this" on the debrief (brief 36): who scored it and how.
  scoreBasisViewed('score_basis_viewed'),

  /// A spoken answer is submitted on a voice mission (brief 35), once per take (the answer, then
  /// the reply): how long it ran, how often it paused, how often it was thrown away. Never audio,
  /// never words.
  voiceAnswerRecorded('voice_answer_recorded'),

  /// A voice mission is scored: by the AI recruiter, or by the player's self-check.
  voiceAnswerScored('voice_answer_scored'),

  /// The player sends themselves a test reminder from Settings (brief 42): tomorrow's planned
  /// reminder, shown now. Its kind only, never its text.
  testReminderSent('test_reminder_sent'),

  /// The tower greets a player back after a day or more away (brief 42): how many days, and
  /// where its one button goes.
  welcomeBackShown('welcome_back_shown'),

  /// The welcome-back card goes away: its button was followed, or it was dismissed.
  welcomeBackClosed('welcome_back_closed'),

  /// A session closes the player's weekly goal (the ring on the tower fills): how many sessions
  /// the week now has, and the goal.
  weeklyGoalClosed('weekly_goal_closed'),

  /// A Recall Room note is shown (the taped note of the trap that caught the player): its kind
  /// and its Leitner box. Never the note's text.
  recallNoteOpened('recall_note_opened'),

  /// A floor of the tower is opened as a sheet (its rooms, its interviewers, how it's
  /// answered), open or still locked: the player looking ahead.
  floorPreviewed('floor_previewed'),

  /// "View all chapters" under the tower opens the chapters list: every floor with its rooms,
  /// played, up next or locked.
  allChaptersOpened('all_chapters_opened'),

  /// A first-time tip is shown (one short line from the cast, once, the first time the player
  /// reaches that moment): which tip, and whether "Show tips again" brought it back.
  tipShown('tip_shown'),

  /// A first-time tip is put away: its target was tapped (and did its normal action), or it
  /// was dismissed ("Got it", or a tap anywhere else).
  tipDone('tip_done'),

  /// "Share your floor card" on the floor-cleared screen: which floor, and how it went (the
  /// share sheet was used, closed without sharing, or sharing isn't available here). Never the
  /// card, never the player's name.
  floorCardShared('floor_card_shared'),

  /// The debrief's dated promise is shown (brief 61): when the room's lines come back in the
  /// Recall Room, or, with nothing to recall, the next room. Its kind and how many days ahead,
  /// never its words.
  promiseShown('promise_shown'),

  /// The first-day moment ("Day 1 of your prep") is shown on the tower after the player's first
  /// finished room ever (brief 61), once: whether a Recall note is due tomorrow.
  firstDayShown('first_day_shown');

  const AnalyticsEvent(this.wireName);

  /// The name sent to the analytics backend.
  final String wireName;
}
