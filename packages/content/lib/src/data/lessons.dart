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

const lessonNowThenNext = Lesson(
  id: 'lesson_now_then_next',
  title: 'Now, then, next',
  flag: Flag.rambling,
  flaw: 'It starts at the beginning of your life, not at what matters for this job.',
  takeaway: '"Tell me about yourself" in three steps: what you do now, one thing from before that fits this job, and why this job is next.',
  recall: RecallCheck(
    prompt: 'Which is the best first line for "Tell me about yourself"?',
    options: [
      RecallOption(
        id: 'recall_now_then_next_childhood',
        text: "I grew up in a small town, and I always loved fixing people's computers.",
      ),
      RecallOption(
        id: 'recall_now_then_next_now',
        text: "I've just graduated in Information Systems, and I love user research.",
      ),
      RecallOption(
        id: 'recall_now_then_next_adjectives',
        text:
            "I'd describe myself as curious, hard-working and a good listener.",
      ),
    ],
    correctOptionId: 'recall_now_then_next_now',
  ),
);

const lessonOwnTheGap = Lesson(
  id: 'lesson_own_the_gap',
  title: 'Name the gap, then close it',
  flag: Flag.generic,
  flaw: 'It argues with the concern instead of answering it, so the concern stays.',
  takeaway: "Agree with the fair part of a concern, then show what you have already done about it. Don't argue, and don't give in.",
  recall: RecallCheck(
    prompt: 'They say others have more experience. Which reply works best?',
    options: [
      RecallOption(
        id: 'recall_own_the_gap_attitude',
        text: "Experience isn't everything; attitude matters much more than years.",
      ),
      RecallOption(
        id: 'recall_own_the_gap_fair',
        text: "That's fair. I've done both halves of this job already, on a small scale.",
      ),
      RecallOption(
        id: 'recall_own_the_gap_give_in',
        text: "I completely understand if you'd rather hire someone with more experience.",
      ),
    ],
    correctOptionId: 'recall_own_the_gap_fair',
  ),
);

const lessonTellItDontRecite = Lesson(
  id: 'lesson_tell_it_dont_recite',
  title: 'Tell the story, not the method',
  flag: Flag.memorized,
  flaw: 'Saying the steps out loud makes a real story sound learned by heart.',
  takeaway: 'Use STAR to plan the story, then hide it: say what happened, what you did and what changed, in your own words.',
  recall: RecallCheck(
    prompt: 'Which opening sounds like a real story?',
    options: [
      RecallOption(
        id: 'recall_tell_it_dont_recite_labels',
        text:
            'The situation was my internship, and my task was a ticket report.',
      ),
      RecallOption(
        id: 'recall_tell_it_dont_recite_story',
        text: 'At my internship I sent my lead a report with a wrong number in it.',
      ),
      RecallOption(
        id: 'recall_tell_it_dont_recite_learning',
        text: 'The key learning from this whole experience was attention to detail.',
      ),
    ],
    correctOptionId: 'recall_tell_it_dont_recite_story',
  ),
);

const lessonOwnYourPart = Lesson(
  id: 'lesson_own_your_part',
  title: 'Own your part',
  flag: Flag.blame,
  flaw:
      'It may be true, but it says whose fault it was instead of what you did.',
  takeaway: 'Name your own part in what went wrong first, in one sentence. Then say what you did about it, and leave the others out.',
  recall: RecallCheck(
    prompt: 'They ask about a mistake. Which line owns it?',
    options: [
      RecallOption(
        id: 'recall_own_your_part_tool',
        text: 'The export tool duplicated rows, so the numbers were wrong from the start.',
      ),
      RecallOption(
        id: 'recall_own_your_part_mine',
        text: "I didn't check the export for duplicates, so my numbers were wrong.",
      ),
      RecallOption(
        id: 'recall_own_your_part_nobody',
        text: 'Nobody had warned me about the export, and I was still very new there.',
      ),
    ],
    correctOptionId: 'recall_own_your_part_mine',
  ),
);

const lessonKeepYourStory = Lesson(
  id: 'lesson_keep_your_story',
  title: 'Keep your story straight',
  flag: Flag.offQuestion,
  flaw:
      'Changing the story under pressure makes the first version sound untrue.',
  takeaway: "When someone pushes back, repeat the same facts calmly and add detail. Don't soften or rewrite what happened.",
  recall: RecallCheck(
    prompt: '"That\'s not what you told Marcus." What do you say?',
    options: [
      RecallOption(
        id: 'recall_keep_your_story_rewrite',
        text: 'Maybe my lead caught it first, actually, and I only fixed it later on.',
      ),
      RecallOption(
        id: 'recall_keep_your_story_same',
        text: "It's the same story: my mistake, and I told my lead that afternoon.",
      ),
      RecallOption(
        id: 'recall_keep_your_story_better',
        text: "I think I just explained it better this time round, that's all.",
      ),
    ],
    correctOptionId: 'recall_keep_your_story_same',
  ),
);

// Chapter 2, "Under Pressure" (brief 37): the lessons the voice missions teach where no
// Chapter 1 lesson fits. Missions 9 and 14 reuse Chapter 1's.

const lessonBothSides = Lesson(
  id: 'lesson_both_sides',
  title: 'Give the other side its due',
  flag: Flag.blame,
  flaw: 'It makes the other person the problem, so the listener wonders what they would say.',
  takeaway: 'Say what the other person wanted and why it made sense, then what you did to settle it. How you settled it matters more than who was right.',
  recall: RecallCheck(
    prompt: 'You disagreed with a teammate. Which line tells it best?',
    options: [
      RecallOption(
        id: 'recall_both_sides_difficult',
        text: 'He was honestly quite difficult to work with, so I had to push back.',
      ),
      RecallOption(
        id: 'recall_both_sides_fair',
        text:
            'She wanted to ship fast; I wanted to test first. Both made sense.',
      ),
      RecallOption(
        id: 'recall_both_sides_avoid',
        text: "I don't really get into conflicts, I just get along with everyone.",
      ),
    ],
    correctOptionId: 'recall_both_sides_fair',
  ),
);

const lessonAskThenAct = Lesson(
  id: 'lesson_ask_then_act',
  title: 'Show what you asked and assumed',
  flag: Flag.vague,
  flaw: 'It says you took the initiative, but not what you asked or what you decided.',
  takeaway: 'Say who you asked, what you assumed where nobody knew, and how you checked that assumption early.',
  recall: RecallCheck(
    prompt:
        'Your brief is one line long. Which answer shows how you handled it?',
    options: [
      RecallOption(
        id: 'recall_ask_then_act_initiative',
        text: "I'm a natural self-starter, so I just used my initiative and figured it out.",
      ),
      RecallOption(
        id: 'recall_ask_then_act_asked',
        text: 'I asked the lead two questions and shared my guesses before starting.',
      ),
      RecallOption(
        id: 'recall_ask_then_act_waited',
        text: 'I waited until my manager had time to give me a proper, full brief.',
      ),
    ],
    correctOptionId: 'recall_ask_then_act_asked',
  ),
);

const lessonCutDontCram = Lesson(
  id: 'lesson_cut_dont_cram',
  title: 'Say what you cut, not how late you stayed',
  flag: Flag.generic,
  flaw: 'Working late shows effort, but not how you decided what mattered.',
  takeaway: 'Say what you did first, what you dropped or delayed, and who you told. Choosing is the skill; extra hours are not.',
  recall: RecallCheck(
    prompt: 'Which answer shows how you handled a tight deadline?',
    options: [
      RecallOption(
        id: 'recall_cut_dont_cram_late',
        text: 'I stayed late every night that week, and I got everything finished.',
      ),
      RecallOption(
        id: 'recall_cut_dont_cram_cut',
        text: "I did the client's part first and told my lead the report would slip.",
      ),
      RecallOption(
        id: 'recall_cut_dont_cram_pressure',
        text: 'I honestly work best under pressure, so deadlines never worry me much.',
      ),
    ],
    correctOptionId: 'recall_cut_dont_cram_cut',
  ),
);

const lessonNoWithAWay = Lesson(
  id: 'lesson_no_with_a_way',
  title: 'Say no, then offer another way',
  flag: Flag.generic,
  flaw: 'It talks about your values but never shows what you said in the room.',
  takeaway: 'Say what you were asked, what you said back, and what you offered instead. Firm and helpful beats a speech about principles.',
  recall: RecallCheck(
    prompt: 'A lead asks you to leave a bad number out. What do you say?',
    options: [
      RecallOption(
        id: 'recall_no_with_a_way_values',
        text: "I'd tell them I have strong values and I never compromise on integrity.",
      ),
      RecallOption(
        id: 'recall_no_with_a_way_offer',
        text:
            "I'd keep the number in and offer to add a note that explains it.",
      ),
      RecallOption(
        id: 'recall_no_with_a_way_comply',
        text: "It's their call in the end, so I'd do it and raise it some other time.",
      ),
    ],
    correctOptionId: 'recall_no_with_a_way_offer',
  ),
);

const lessonPauseThenAnswer = Lesson(
  id: 'lesson_pause_then_answer',
  title: 'Pause, then answer',
  flag: Flag.rambling,
  flaw: 'Thinking out loud to fill the silence buries the answer when it finally comes.',
  takeaway: "It's fine to say \"Give me a second.\" Then answer in one sentence, add one example, and stop.",
  recall: RecallCheck(
    prompt: 'A follow-up catches you off guard. What is the best first move?',
    options: [
      RecallOption(
        id: 'recall_pause_then_answer_fill',
        text: "Start talking straight away so there's no awkward silence in the room.",
      ),
      RecallOption(
        id: 'recall_pause_then_answer_pause',
        text:
            "Say 'Give me a second', think, then answer in one clear sentence.",
      ),
      RecallOption(
        id: 'recall_pause_then_answer_dodge',
        text: 'Steer back to the story you prepared, since you know that one well.',
      ),
    ],
    correctOptionId: 'recall_pause_then_answer_pause',
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
  lessonNowThenNext,
  lessonOwnTheGap,
  lessonTellItDontRecite,
  lessonOwnYourPart,
  lessonKeepYourStory,
  lessonBothSides,
  lessonAskThenAct,
  lessonCutDontCram,
  lessonNoWithAWay,
  lessonPauseThenAnswer,
];
