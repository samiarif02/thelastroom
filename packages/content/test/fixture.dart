import 'package:content/content.dart';
import 'package:engine/engine.dart';

/// The one tiny mission the schema tests run against. Real mission text lands in brief 04.
const fixture = ContentBundle(
  interviewers: [
    Interviewer(
      id: 'priya',
      name: 'Priya',
      role: 'Recruiter',
      voice: 'Warm and brisk.',
      tests: {Dimension.relevance},
    ),
  ],
  lessons: [
    Lesson(
      id: 'lesson_name_your_part',
      title: 'Say what you did',
      flag: Flag.weNotI,
      flaw: 'It hides what you did.',
      takeaway: 'Use "I" for your part of a team result.',
      recall: RecallCheck(
        prompt: 'Which line shows your own part?',
        options: [
          RecallOption(id: 'recall_we', text: 'We shipped it.'),
          RecallOption(id: 'recall_i', text: 'I wrote the tests.'),
        ],
        correctOptionId: 'recall_i',
      ),
    ),
  ],
  missions: [
    Mission(
      id: 'm_fixture',
      chapter: 1,
      number: 1,
      title: 'Fixture',
      scene: [SceneLine(speakerId: 'priya', text: 'Thanks for coming in.')],
      question: SceneLine(speakerId: 'priya', text: 'Why this role?'),
      hinted: false,
      timed: false,
      isBaseline: true,
      beats: [
        Beat(
          kind: BeatKind.open,
          options: [
            AnswerOption(id: 'o1', text: 'A strong line.', scores: _strong),
            AnswerOption(
              id: 'o2',
              text: 'We did a lot of things.',
              scores: _weak,
              flags: {Flag.weNotI, Flag.vague},
              lessonId: 'lesson_name_your_part',
            ),
            AnswerOption(id: 'o3', text: 'An okay line.', scores: _okay),
          ],
        ),
        Beat(
          kind: BeatKind.evidence,
          options: [
            AnswerOption(id: 'e1', text: 'A strong line.', scores: _strong),
            AnswerOption(
              id: 'e2',
              text: 'We did a lot of things.',
              scores: _weak,
              flags: {Flag.weNotI, Flag.vague},
              lessonId: 'lesson_name_your_part',
            ),
            AnswerOption(id: 'e3', text: 'An okay line.', scores: _okay),
          ],
        ),
        Beat(
          kind: BeatKind.land,
          options: [
            AnswerOption(id: 'l1', text: 'A strong line.', scores: _strong),
            AnswerOption(
              id: 'l2',
              text: 'We did a lot of things.',
              scores: _weak,
              flags: {Flag.weNotI, Flag.vague},
              lessonId: 'lesson_name_your_part',
            ),
            AnswerOption(id: 'l3', text: 'An okay line.', scores: _okay),
          ],
        ),
      ],
      followUps: [
        FollowUp(
          id: 'f_default',
          line: SceneLine(speakerId: 'priya', text: 'Tell me more.'),
          replies: [
            AnswerOption(id: 'fd1', text: 'A strong line.', scores: _strong),
            AnswerOption(
              id: 'fd2',
              text: 'We did a lot of things.',
              scores: _weak,
              flags: {Flag.weNotI, Flag.vague},
              lessonId: 'lesson_name_your_part',
            ),
            AnswerOption(id: 'fd3', text: 'An okay line.', scores: _okay),
          ],
        ),
        FollowUp(
          id: 'f_we',
          trigger: Flag.weNotI,
          line: SceneLine(speakerId: 'priya', text: 'What did you do?'),
          replies: [
            AnswerOption(id: 'fw1', text: 'A strong line.', scores: _strong),
            AnswerOption(
              id: 'fw2',
              text: 'We did a lot of things.',
              scores: _weak,
              flags: {Flag.weNotI, Flag.vague},
              lessonId: 'lesson_name_your_part',
            ),
            AnswerOption(id: 'fw3', text: 'An okay line.', scores: _okay),
          ],
        ),
      ],
      skillRequirements: [
        SkillRequirement(
          skill: Skill.clearIntroductions,
          dimension: Dimension.relevance,
          minScore: 70,
        ),
      ],
    ),
  ],
);

const _strong = DimensionScores(
  relevance: 3,
  specificity: 3,
  structure: 3,
  adaptability: 3,
);

const _okay = DimensionScores(
  relevance: 2,
  specificity: 2,
  structure: 2,
  adaptability: 2,
);

/// A realistic mistake: on topic, but vague and hiding behind the team.
const _weak = DimensionScores(
  relevance: 2,
  specificity: 1,
  structure: 1,
  adaptability: 1,
);
