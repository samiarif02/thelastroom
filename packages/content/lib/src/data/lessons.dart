import '../lesson.dart';

/// "Why this role" is about the role: the lesson for [Flag.generic] in Chapter 1.
const lessonWhyThisRole = Lesson(
  id: 'lesson_why_this_role',
  title: 'Say why this role, not why any job',
  takeaway:
      'Name one thing in this job you want to do, and why. If the line would work for any '
      'company, it is too general.',
  recall: RecallCheck(
    prompt: 'Which opening answers "Why this role?" best?',
    options: [
      RecallOption(
        id: 'recall_why_this_role_culture',
        text: 'I have always loved technology, and you have a great culture.',
      ),
      RecallOption(
        id: 'recall_why_this_role_work',
        text:
            'I want to spend my days talking to users and using data to decide what to '
            'build, and this role does both.',
      ),
      RecallOption(
        id: 'recall_why_this_role_challenge',
        text: 'I am a hard worker, and I am ready for a new challenge.',
      ),
    ],
    correctOptionId: 'recall_why_this_role_work',
  ),
);

/// Staying on the question: the lesson for [Flag.offQuestion].
const lessonAnswerTheQuestion = Lesson(
  id: 'lesson_answer_the_question',
  title: 'Answer the question they asked',
  takeaway:
      '"Why did you apply?" is about the work, not the salary or the location. Save the '
      'perks for when they ask about them.',
  recall: RecallCheck(
    prompt: 'The recruiter asks why you applied. Which answer stays on the question?',
    options: [
      RecallOption(
        id: 'recall_answer_the_question_perks',
        text: 'The salary is good, and the office is close to my home.',
      ),
      RecallOption(
        id: 'recall_answer_the_question_work',
        text:
            'The job is mostly user research, which is the work I enjoy most.',
      ),
      RecallOption(
        id: 'recall_answer_the_question_any',
        text: 'Honestly, any job here would be fine for me.',
      ),
    ],
    correctOptionId: 'recall_answer_the_question_work',
  ),
);

/// Sounding like a person: the lesson for [Flag.memorized].
const lessonTalkLikeYourself = Lesson(
  id: 'lesson_talk_like_yourself',
  title: 'Talk like a person, not a CV',
  takeaway:
      'Phrases like "motivated team player" sound learned by heart and prove nothing. Swap '
      'each one for something you actually did.',
  recall: RecallCheck(
    prompt: 'Which line sounds like a real person talking?',
    options: [
      RecallOption(
        id: 'recall_talk_like_yourself_driven',
        text: 'I am a results-driven self-starter.',
      ),
      RecallOption(
        id: 'recall_talk_like_yourself_real',
        text: 'Last term I ran user interviews for our app, and I loved it.',
      ),
      RecallOption(
        id: 'recall_talk_like_yourself_fast',
        text: 'I thrive in fast-paced environments.',
      ),
    ],
    correctOptionId: 'recall_talk_like_yourself_real',
  ),
);

/// "I", not "we": the lesson for [Flag.weNotI].
const lessonNameYourPart = Lesson(
  id: 'lesson_name_your_part',
  title: 'Say what you did',
  takeaway: 'Use "I" for your part of a team result. They are hiring you, not your team.',
  recall: RecallCheck(
    prompt: 'Which line shows your own part?',
    options: [
      RecallOption(
        id: 'recall_name_your_part_we',
        text: 'We improved the app a lot.',
      ),
      RecallOption(
        id: 'recall_name_your_part_i',
        text: 'I ran the user interviews and redesigned the sign-up.',
      ),
      RecallOption(
        id: 'recall_name_your_part_team',
        text: 'Our team worked really hard on it.',
      ),
    ],
    correctOptionId: 'recall_name_your_part_i',
  ),
);

/// Concrete beats general: the lesson for [Flag.vague].
const lessonBeConcrete = Lesson(
  id: 'lesson_be_concrete',
  title: 'One real example, one real number',
  takeaway:
      'Swap "a lot of projects" for one example you can name, with a detail or a number '
      'that shows what changed.',
  recall: RecallCheck(
    prompt: 'Which evidence is easiest to believe?',
    options: [
      RecallOption(
        id: 'recall_be_concrete_lots',
        text: 'I have a lot of experience working with users.',
      ),
      RecallOption(
        id: 'recall_be_concrete_number',
        text: 'I interviewed twelve students and cut the sign-up from five screens to two.',
      ),
      RecallOption(
        id: 'recall_be_concrete_always',
        text: 'I always use data in my work.',
      ),
    ],
    correctOptionId: 'recall_be_concrete_number',
  ),
);

/// One story, then stop: the lesson for [Flag.rambling].
const lessonOneStory = Lesson(
  id: 'lesson_one_story',
  title: 'Tell one story, then stop',
  takeaway:
      'Pick your best example, tell it from start to finish, and end it on purpose. A clear '
      'ending sounds confident; a trailing list sounds unsure.',
  recall: RecallCheck(
    prompt: 'You have just finished your example. What is the best next line?',
    options: [
      RecallOption(
        id: 'recall_one_story_more',
        text:
            'So yes, I have some other projects too, if you want to hear them…',
      ),
      RecallOption(
        id: 'recall_one_story_land',
        text: 'That is the kind of work I want to do here every day.',
      ),
      RecallOption(
        id: 'recall_one_story_guess',
        text: 'Anyway, I think that is mostly it, I guess.',
      ),
    ],
    correctOptionId: 'recall_one_story_land',
  ),
);

/// Every lesson the campaign teaches.
const List<Lesson> lessons = [
  lessonWhyThisRole,
  lessonAnswerTheQuestion,
  lessonTalkLikeYourself,
  lessonNameYourPart,
  lessonBeConcrete,
  lessonOneStory,
];
