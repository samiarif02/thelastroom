import '../../core/profile/profile_repository.dart';

/// What onboarding says. The host's lines are short: the whole flow fits in a minute.
abstract final class OnboardingCopy {
  static const String skip = 'Skip';

  static const String askName = 'Before we start: what should I call you?';
  static String askExperience(String name) =>
      'Good to meet you, $name. Where are you right now?';
  static const String askRole = 'And what kind of role are you going for?';
  static const String askNerves =
      'Be honest with me: how nervous do interviews make you?';
  static const String askGoal = 'How often do you want to practise?';

  static const Map<Experience, String> experience = {
    Experience.student: 'Still studying',
    Experience.freshGraduate: 'Just graduated',
    Experience.earlyCareer: 'One or two years in',
    Experience.switchingCareers: 'Switching careers',
  };

  static const Map<TargetRole, String> role = {
    TargetRole.product: 'Product',
    TargetRole.design: 'Design or research',
    TargetRole.data: 'Data or analytics',
    TargetRole.engineering: 'Engineering',
    TargetRole.marketing: 'Marketing or sales',
    TargetRole.notSure: 'Not sure yet',
  };

  /// One line per level, 1 (calm) to 5.
  static const List<String> nerves = [
    '1 · Not at all',
    '2 · A little',
    '3 · Some',
    '4 · Quite nervous',
    '5 · Very nervous',
  ];

  /// The weekly goal as named tiers, not a number field (Duolingo's daily goal).
  static const List<({int sessions, String label})> goals = [
    (sessions: 1, label: 'Easy · 1 session a week'),
    (sessions: 3, label: 'Steady · 3 sessions a week'),
    (sessions: 5, label: 'Serious · 5 sessions a week'),
  ];

  static const String readyEyebrow = 'FLOOR ONE';
  static const String ready = 'Your first interview is waiting.';
  static String readyLine(String name, String host) =>
      '$host has your file, $name. One question, a few lines, and you see exactly '
      'what landed.';
  static const String calmOn =
      'Calm mode is on: no answer timers. You can change it in your file.';
  static const String toTower = 'Go to the tower';
}
