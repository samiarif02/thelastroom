/// What onboarding says (brief 17): three short steps, the whole flow in well under a minute.
abstract final class OnboardingCopy {
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String letsGo = 'Let’s go';

  // Step 1: the game.
  static const String gameKicker = 'THE LAST ROOM';
  static const String gameTitle = 'One room left between you and the offer.';
  static const List<({String title, String line})> gameIdeas = [
    (
      title: 'Build your answer',
      line: 'Line by line: open, prove it, land it.',
    ),
    (
      title: 'Handle the push-back',
      line: 'They follow up. You answer that too.',
    ),
    (
      title: 'See what landed',
      line: 'Every line is scored, and you learn why.',
    ),
  ];

  // Step 2: the cast.
  static const String castKicker = 'ACROSS THE DESK';
  static const String castTitle = 'Meet your interviewers.';
  static const String castLine =
      'Friendly, fair and fictional. They want you to do well.';

  /// Where the player first sits across from them.
  static String castFirstMet(int mission) => 'First met in Mission $mission';

  // Step 3: the name.
  static const String nameKicker = 'LAST THING';
  static const String nameTitle = 'What should we call you?';
  static const String nameLine = 'Just a first name. It stays on this device.';
}
