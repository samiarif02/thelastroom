/// What the reminders say: in the voice of whoever asks the next question (FR-50: in a
/// character's voice, 3+ variants each). Plain text, no player name (it stays on the device).
abstract final class ReminderCopy {
  static const String recallTitle = 'Recall Room';

  /// "3 notes are waiting in the Recall Room", in three ways. Notes, as the Recall Room calls
  /// them (QA 51: the reminder said "traps").
  static String recallBody(int due, int variant) {
    final notes = due == 1 ? '1 note' : '$due notes';
    final waiting = due == 1 ? 'is' : 'are';
    return switch (variant % variants) {
      0 => '$notes $waiting waiting in the Recall Room.',
      1 => '$notes from your rooms $waiting back. One minute to keep them.',
      _ => 'One quick round: $notes to keep fresh.',
    };
  }

  static const Map<String, String> _names = {
    'priya': 'Priya',
    'marcus': 'Marcus',
    'lena': 'Lena',
    'sam': 'Sam',
  };

  static const Map<String, List<String>> _nudges = {
    'priya': [
      "Still thinking about why you'd take this role? Your next question is ready.",
      "Five minutes? I've kept a seat for you in the lobby.",
      'Your next interview is waiting. Bring one real example.',
    ],
    'marcus': [
      "I'll want the numbers this time. Ready when you are.",
      'One question, one real example. Your interview is waiting.',
      'Bring a number, and whose it was. Your next round is ready.',
    ],
    'lena': [
      "You said you'd tell me what actually happened. I'm listening.",
      'Same story, same facts? Come and walk me through it.',
      "I'll repeat your words back to you. Ready?",
    ],
    'sam': [
      'One room left. Take your time, then come and see me.',
      "I'll ask the one question that matters. When you're ready.",
      'The last room is quiet. It is waiting for you.',
    ],
  };

  /// An interviewer's name ("Priya"), or null for an id that isn't one.
  static String? name(String? interviewerId) => _names[interviewerId];

  /// The interviewer's name over the nudge (unknown ids fall back to the company).
  static String nudgeTitle(String interviewerId) {
    final name = _names[interviewerId];
    return name == null ? company : '$name · $company';
  }

  static const String company = 'Northstar Labs';

  static String nudgeBody(String interviewerId, int variant) {
    final lines = _nudges[interviewerId] ?? _nudges['priya']!;
    return lines[variant % lines.length];
  }

  /// A nudge before the interview leads with the countdown (FR-4, brief 32).
  static String withCountdown(int daysToInterview, String line) =>
      switch (daysToInterview) {
        0 => 'Interview day. One warm-up? $line',
        1 => 'Your interview is tomorrow. $line',
        _ => '$daysToInterview days to your interview. $line',
      };

  /// Every reminder kind has this many ways of saying it.
  static const int variants = 3;
}
