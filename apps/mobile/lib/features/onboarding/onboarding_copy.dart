/// What onboarding says (brief 17): three short steps, the whole flow in well under a minute.
abstract final class OnboardingCopy {
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String letsGo = 'Let’s go';

  // Step 1: the game.
  static const String gameKicker = 'The Last Room';
  static const String gameTitle = 'One room left between you and the offer.';
  static const List<({String title, String line})> gameIdeas = [
    (
      title: 'Build your answer',
      line: 'Line by line: open, prove it, land it.',
    ),
    (
      title: 'Answer when they push back',
      line: 'They follow up. You answer that too.',
    ),
    (
      title: 'See what landed',
      line: 'Every line is scored, and you learn why.',
    ),
  ];

  // Step 2: the cast.
  static const String castKicker = 'Across the desk';
  static const String castTitle = 'Meet your interviewers.';
  static const String castLine =
      'Friendly, fair and fictional. They want you to do well.';

  /// Where the player first sits across from them.
  static String castFirstMet(int mission) => 'First met in room $mission';

  /// The top floor's interviewer, seen from day one, met last.
  static const String samRole = 'Head of product';
  static const String samLine = 'Waits on the top floor';

  // Step 3: the name.
  static const String nameKicker = 'Last thing';
  static const String nameTitle = 'What should we call you?';
  static const String nameLine = 'Just a first name. It stays on this device.';
}
