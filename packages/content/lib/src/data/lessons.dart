import 'package:engine/engine.dart';

import '../lesson.dart';

const lessonWhyThisRole = Lesson(
  id: 'lesson_why_this_role',
  title: 'Say why this role, not why any job',
  flag: Flag.generic,
  flaw: 'It sounds keen, but it would fit any company and any candidate.',
  takeaway: 'Name one thing in this job you want to do, and why. If the line would work for anyone applying anywhere, it is too general.',
  recall: RecallCheck(
    prompt: 'Which opening answers "Why this role?" best?',
    options: [
      RecallOption(
        id: 'recall_why_this_role_culture',
        text: "I've always loved technology, and your company has a really great culture.",
      ),
      RecallOption(
        id: 'recall_why_this_role_work',
        text: 'I want to talk to users and read the numbers, and this role does both.',
      ),
      RecallOption(
        id: 'recall_why_this_role_challenge',
        text: "I'm a hard worker, and I'm ready for a new challenge in a growing company.",
      ),
    ],
    correctOptionId: 'recall_why_this_role_work',
  ),
);

const lessonAnswerTheQuestion = Lesson(
  id: 'lesson_answer_the_question',
  title: 'Answer the question they asked',
  flag: Flag.offQuestion,
  flaw: 'It answers a question nobody asked, so the real one goes unanswered.',
  takeaway: 'Listen for what they actually asked, and answer that first. Perks, side stories and apologies can wait until they ask.',
  recall: RecallCheck(
    prompt: 'The recruiter asks why you applied. Which answer stays on the question?',
    options: [
      RecallOption(
        id: 'recall_answer_the_question_perks',
        text:
            'The salary is good, and the office is very close to where I live.',
      ),
      RecallOption(
        id: 'recall_answer_the_question_work',
        text:
            'The job is mostly user research, which is the work I enjoy most.',
      ),
      RecallOption(
        id: 'recall_answer_the_question_any',
        text: "Honestly, any job here would be fine for me, I'm just keen to start.",
      ),
    ],
    correctOptionId: 'recall_answer_the_question_work',
  ),
);

const lessonTalkLikeYourself = Lesson(
  id: 'lesson_talk_like_yourself',
  title: 'Talk like a person, not a CV',
  flag: Flag.memorized,
  flaw: 'It sounds rehearsed, so the listener stops believing it.',
  takeaway: 'Phrases like "proactive team player" sound learned by heart and prove nothing. Swap each one for something you actually did.',
  recall: RecallCheck(
    prompt: 'Which line sounds like a real person talking?',
    options: [
      RecallOption(
        id: 'recall_talk_like_yourself_driven',
        text: "I'm a results-driven self-starter with strong communication skills.",
      ),
      RecallOption(
        id: 'recall_talk_like_yourself_real',
        text: 'Last term I ran user interviews for our app, and I loved it.',
      ),
      RecallOption(
        id: 'recall_talk_like_yourself_fast',
        text:
            'I thrive in fast-paced environments and always go the extra mile.',
      ),
    ],
    correctOptionId: 'recall_talk_like_yourself_real',
  ),
);

const lessonNameYourPart = Lesson(
  id: 'lesson_name_your_part',
  title: 'Say what you did',
  flag: Flag.weNotI,
  flaw: 'It sounds modest, but it hides what you actually did.',
  takeaway: 'Use "I" for your part of a team result and "we" for the rest. They are hiring you, not your team.',
  recall: RecallCheck(
    prompt: 'Which line shows your own part?',
    options: [
      RecallOption(
        id: 'recall_name_your_part_we',
        text: 'We improved the app a lot, and the whole team was proud of it.',
      ),
      RecallOption(
        id: 'recall_name_your_part_i',
        text: 'I ran the user interviews and redesigned the sign-up myself.',
      ),
      RecallOption(
        id: 'recall_name_your_part_team',
        text: 'Our team worked really hard on it, and we got great results.',
      ),
    ],
    correctOptionId: 'recall_name_your_part_i',
  ),
);

const lessonBeConcrete = Lesson(
  id: 'lesson_be_concrete',
  title: 'One real example, one real number',
  flag: Flag.vague,
  flaw: 'It claims a skill but never shows one example of it.',
  takeaway: 'Swap "a lot of projects" for one example you can name, with a detail or a number that shows what changed.',
  recall: RecallCheck(
    prompt: 'Which evidence is easiest to believe?',
    options: [
      RecallOption(
        id: 'recall_be_concrete_lots',
        text: 'I have a lot of experience working closely with users and data.',
      ),
      RecallOption(
        id: 'recall_be_concrete_number',
        text: 'I interviewed twelve students and cut sign-up to two screens.',
      ),
      RecallOption(
        id: 'recall_be_concrete_always',
        text: 'I always use data in my work, and it has served me very well.',
      ),
    ],
    correctOptionId: 'recall_be_concrete_number',
  ),
);

const lessonOneStory = Lesson(
  id: 'lesson_one_story',
  title: 'Tell one story, then stop',
  flag: Flag.rambling,
  flaw: 'It keeps going after the point, so the point gets lost.',
  takeaway: 'Pick your best example, tell it start to finish, and end on purpose. A clear ending sounds confident; a trailing list sounds unsure.',
  recall: RecallCheck(
    prompt: 'You have just finished your example. What is the best next line?',
    options: [
      RecallOption(
        id: 'recall_one_story_more',
        text: "So yes, I've got some other projects too, if you want to hear them…",
      ),
      RecallOption(
        id: 'recall_one_story_land',
        text: "That's the kind of work I want to be doing here, every single day.",
      ),
      RecallOption(
        id: 'recall_one_story_guess',
        text:
            "Anyway, I think that's mostly it, I guess, unless you have more…",
      ),
    ],
    correctOptionId: 'recall_one_story_land',
  ),
);

const lessonPromiseTheHabit = Lesson(
  id: 'lesson_promise_the_habit',
  title: 'Promise the habit, not the result',
  flag: Flag.vague,
  flaw: 'It promises results nobody can know yet, so it sounds bold but not believable.',
  takeaway: 'Instead of promising impact, say what you will do: the habit you would bring, and how you would check it worked.',
  recall: RecallCheck(
    prompt: 'Which ending is the most believable?',
    options: [
      RecallOption(
        id: 'recall_promise_the_habit_double',
        text: "I'm confident I could double your key numbers within my first year.",
      ),
      RecallOption(
        id: 'recall_promise_the_habit_habit',
        text: "I'd ask users first, then check the numbers to see what worked.",
      ),
      RecallOption(
        id: 'recall_promise_the_habit_harder',
        text:
            'Nobody on your shortlist will work harder than me, I promise you.',
      ),
    ],
    correctOptionId: 'recall_promise_the_habit_habit',
  ),
);

const lessonShareTheCredit = Lesson(
  id: 'lesson_share_the_credit',
  title: "Claim your part, not the team's",
  flag: Flag.vague,
  flaw: "It takes credit for the whole team's work, and one more question will show it.",
  takeaway: 'Say exactly what you did, then name who did the rest. Precise credit is more impressive than all of it.',
  recall: RecallCheck(
    prompt: 'Who built the fix? Which answer is the most convincing?',
    options: [
      RecallOption(
        id: 'recall_share_the_credit_all',
        text: 'Me, really. I drove the whole thing, from start to finish, on my own.',
      ),
      RecallOption(
        id: 'recall_share_the_credit_split',
        text: 'I found the problem and wrote the page; an engineer built the link.',
      ),
      RecallOption(
        id: 'recall_share_the_credit_team',
        text: "It was a team effort, so I'd rather not single anyone out here.",
      ),
    ],
    correctOptionId: 'recall_share_the_credit_split',
  ),
);

/// Every lesson the campaign teaches. Each belongs to one flag; a flag can have several, so
/// a mission can teach the version of a mistake its own lines make.
const List<Lesson> lessons = [
  lessonWhyThisRole,
  lessonAnswerTheQuestion,
  lessonTalkLikeYourself,
  lessonNameYourPart,
  lessonBeConcrete,
  lessonOneStory,
  lessonPromiseTheHabit,
  lessonShareTheCredit,
];
