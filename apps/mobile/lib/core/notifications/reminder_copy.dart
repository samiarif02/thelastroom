/// What the reminders say: in the voice of whoever asks the next question (FR-50: in a
/// character's voice, 3+ variants each). Plain text, no player name (it stays on the device).
abstract final class ReminderCopy {
  static const String recallTitle = 'Recall Room';

  /// "3 traps are waiting in the Recall Room", in three ways.
  static String recallBody(int due, int variant) {
    final traps = due == 1 ? '1 trap' : '$due traps';
    final waiting = due == 1 ? 'is' : 'are';
    return switch (variant % variants) {
      0 => '$traps $waiting waiting in the Recall Room.',
      1 => '$traps you fell for $waiting back. One minute to beat them.',
      _ => 'One quick round: $traps want a rematch.',
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

  /// Every reminder kind has this many ways of saying it.
  static const int variants = 3;
}
