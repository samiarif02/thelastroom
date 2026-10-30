import '../player_character.dart';

/// Jordan, the candidate the player plays through Chapter 1. Every answer line draws on these
/// facts and no others; the figures are the only numbers a line may quote in digits.
const player = PlayerCharacter(
  name: 'Jordan Reyes',
  premise:
      'You play Jordan Reyes, a new Information Systems graduate going for a first job in '
      "product. Every answer you pick is Jordan's.",
  figures: {'40%', '75%', '600', '900', '300'},
  facts: [
    CharacterFact(
      id: 'fact_degree',
      label: 'Degree',
      detail:
          'BSc in Information Systems, finished this summer. The favourite part was user '
          'research.',
      markers: ['Information Systems', 'degree'],
    ),
    CharacterFact(
      id: 'fact_project',
      label: 'University project',
      detail:
          'Final-year project: a study app for first-year students, built by a team of four. '
          'Jordan interviewed twelve students and designed a new sign-up, cut from five screens '
          'to two; finished sign-ups went from 40% to 75%. Two teammates built the back end, '
          'one built the screens. Before the demo, Jordan asked a teammate to recheck the '
          'figures.',
      markers: ['study app', 'project', 'twelve students', 'sign-up'],
    ),
    CharacterFact(
      id: 'fact_internship',
      label: 'Internship',
      detail:
          'Three months in the support team at Larkfield, a small booking-software company. '
          'Jordan tagged 600 support tickets from one month; one in three were password resets. '
          'Jordan wrote a step-by-step help page, the support lead approved it, and password '
          'tickets fell by a quarter the next month. An engineer later added a reset link to '
          'the login screen.',
      markers: ['Larkfield', 'internship', 'tickets'],
    ),
    CharacterFact(
      id: 'fact_mistake',
      label: 'The mistake',
      detail:
          'At Larkfield, the first ticket report said half the tickets were password resets. '
          'The export had 900 rows and 300 were duplicates; Jordan had not checked. Jordan '
          'found it, told the lead the same afternoon, before the team meeting, and sent a '
          'corrected report. Since then: compare the row count with the unique ticket IDs '
          'before any number goes out.',
      markers: ['report', 'duplicate', 'export'],
    ),
    CharacterFact(
      id: 'fact_cafe',
      label: 'Part-time job',
      detail:
          'Two years at the campus café, about fifteen hours a week. It opened late about twice '
          'a week; nobody asked, but Jordan timed a few openings, wrote a one-page opening '
          'checklist (keys, float, stock, machine) and tested it on their own shifts. The café '
          'then opened on time every day for the rest of term, and Jordan used the checklist '
          'to train three new staff.',
      markers: ['café', 'checklist'],
    ),
    CharacterFact(
      id: 'fact_learning',
      label: 'Still learning',
      detail:
          'Has only used small datasets. Halfway through an online SQL course, and would ask '
          'the data team to review the first queries.',
      markers: ['SQL', 'small spreadsheets', 'datasets'],
    ),
    CharacterFact(
      id: 'fact_outside',
      label: 'Outside work',
      detail: 'Plays five-a-side football every Sunday.',
      markers: ['football'],
    ),
  ],
);

/// The draft-first prompt (FR-11). The draft is the player's own words about themselves, not
/// Jordan's: it's what "then vs. now" sets beside a later answer (owner's note 3).
const String draftPrompt =
    "Before you see Jordan's options, start this answer in your own words, about yourself. "
    "Later we'll put it beside a newer answer, so you can see what changed.";
