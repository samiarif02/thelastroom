# content

Missions, interviewers, lessons, chapters and the player character sheet as typed Dart, with
validation tests. Versioned by `contentSchemaVersion`.

- `lib/src/data/`: what ships. `gameContent` is the bundle the app plays; Chapter 1 is
  `missions/m01_…` to `m07_…`; Chapters 2–3 are locked teasers in `chapters.dart`; `player` is
  Jordan, the candidate every answer line speaks for.
- `validateContent` checks the structure (beats, ids, speakers, flags against lessons, 30 words
  per line, two subtitle lines per interviewer line, chapters, Mission 6's continuity).
- `test/writing_notes_test.dart` checks the owner's writing notes: lines in a set within 20 % of
  each other's length, the best line rarely the longest, ids with no screen-order hint, every
  figure from the character sheet. `test/chapter_one_test.dart` checks scoring and branching
  over every path through every mission.
