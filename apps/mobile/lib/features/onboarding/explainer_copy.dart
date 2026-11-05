/// One page of "How it works" (issue 75): a kicker, the idea in one line, and what it means.
typedef ExplainerPageCopy = ({String kicker, String title, String line});

/// What the "How it works" explainer says (issue 75): what the app is, how a room works, how
/// you're scored, how it sticks and why you'd come back. Plain and warm; every claim is
/// something the game really does.
abstract final class ExplainerCopy {
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String back = 'Previous page';
  static const String close = 'Close';

  /// The last page's button in onboarding: on to the questions.
  static const String ready = 'Let’s get you ready';

  /// The last page's button when Settings replays it.
  static const String done = 'Done';

  /// The dots, for a screen reader.
  static String pageOf(int page, int of) => 'Page $page of $of';

  static const List<ExplainerPageCopy> pages = [
    (
      kicker: 'What this is',
      title: 'Practise the interview before the interview.',
      line:
          'Northstar Labs is hiring. Its tower has 21 rooms on three floors, each one a real '
          'interview question. Priya, Marcus and Lena interview you on the way up, and Sam '
          'waits at the top with the offer.',
    ),
    (
      kicker: 'How a room works',
      title: 'They ask. You answer. Then you say why.',
      line:
          'On floor 1 you pick the line you’d really say. On floor 2 you answer out loud. '
          'Then you tell them why you chose it. The points are in the why.',
    ),
    (
      kicker: 'How you’re scored',
      title: 'Every answer scored, with the reasons.',
      line:
          'A senior recruiter (an AI) scores your answer out of 100 on four things and says '
          'why for each. With no connection, the game scores it itself, so it always works.',
    ),
    (
      kicker: 'How it sticks',
      title: 'The lines that caught you come back.',
      line:
          'Every slip becomes a Recall note. The Recall Room brings it back after a day, then '
          'three, then seven, until it’s yours. One reminder names the day, and never more '
          'than one a day.',
    ),
    (
      kicker: 'Why come back',
      title: 'See yourself get better, week by week.',
      line:
          'Every room earns XP. Climb the weekly leaderboard from Bronze to Diamond and earn skills '
          'as you climb. A day off costs you nothing: there’s no streak to lose.',
    ),
  ];

  // Page 1's art.
  static const String sign = 'NORTHSTAR LABS';
  static const String towerFacts = '21 rooms · 3 floors · 1 offer';
  static const String towerArt =
      'Northstar tower: three floors of seven rooms. Room 1 is open with Priya inside; Sam '
      'waits on the top floor.';

  // Page 2's art.
  static const String askSpeaker = 'Marcus · Hiring manager';
  static const String askLine = 'Tell me about a time a deadline slipped.';
  static const String answerStrong =
      'I flagged it two days early and agreed a smaller first release.';
  static const String answerWeak = 'It wasn’t really my fault.';
  static const String whyKicker = 'Why that line?';
  static const String whyLine = 'It owns the problem and shows what I did.';
  static const String voiceTag = 'Floor 2: out loud';
  static const String roomArt =
      'An example room. Marcus asks about a deadline that slipped. Two answers to pick from, '
      'then the reason you picked it.';

  // Page 3's art: a still of the Candidate assessment, not the sheet itself.
  static const String sheetTitle = 'Candidate assessment';
  static const String scoredBy = 'Scored by AI · Senior recruiter';
  static const String offline = 'Works offline';
  static const int exampleTotal = 78;
  static const List<({String name, int score, String basis})> dimensions = [
    (name: 'Relevance', score: 84, basis: 'Answered the question they asked.'),
    (name: 'Specificity', score: 66, basis: 'Name the number you moved.'),
    (name: 'Structure', score: 81, basis: 'A clear start, middle and end.'),
    (name: 'Adaptability', score: 79, basis: 'Held up when they pushed back.'),
  ];

  /// The weakest of the example's four, drawn in trap clay as the real sheet does.
  static const String weakest = 'Specificity';
  static const String scoreArt =
      'An example Candidate assessment: 78 out of 100. Relevance 84, Specificity 66, '
      'Structure 81, Adaptability 79, each with its reason.';

  // Page 4's art.
  static const List<String> recallDays = ['Day 1', 'Day 3', 'Day 7'];
  static const String recallNote = 'Priya will bring this line back tomorrow.';
  static const String reminderTag = 'At most one reminder a day';
  static const String recallArt =
      'A Recall note comes back on day 1, day 3 and day 7. Priya will bring this line back '
      'tomorrow.';

  // Page 5's art.
  static const String xpTag = '+120 XP';
  static const String weekTag = 'This week';
  static const String skillName = 'Evidence builder';
  static const String skillHint = 'Earned';
  static const String rewardsArt =
      'Rewards: XP for every room, five leagues from Bronze to Diamond on the weekly '
      'leaderboard, and skills to earn.';
}
