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

// Chapter 3, "The Final Round" (brief 38).

const lessonCauseBeforeFix = Lesson(
  id: 'lesson_cause_before_fix',
  title: 'Find the cause before the fix',
  flag: Flag.offQuestion,
  flaw: 'It jumps to a fix before finding out what is actually broken.',
  takeaway: 'Say what you would check first, and why. A fix that worked somewhere else is still a guess until you know the cause here.',
  recall: RecallCheck(
    prompt: 'Sign-ups fell last month. Which first step is strongest?',
    options: [
      RecallOption(
        id: 'recall_cause_before_fix_redesign',
        text: 'Redesign the sign-up screens, since shorter forms nearly always win.',
      ),
      RecallOption(
        id: 'recall_cause_before_fix_funnel',
        text:
            'Find the step where people stop, and compare it with last month.',
      ),
      RecallOption(
        id: 'recall_cause_before_fix_ads',
        text: 'Spend more on ads for a month, so the numbers can recover.',
      ),
    ],
    correctOptionId: 'recall_cause_before_fix_funnel',
  ),
);

const lessonFirstStep = Lesson(
  id: 'lesson_first_step',
  title: 'Commit to a first step',
  flag: Flag.vague,
  flaw: 'It lists every possible cause but commits to checking none of them.',
  takeaway: 'Pick the one thing you would check first and say why it comes first. A clear first step beats a long list of maybes.',
  recall: RecallCheck(
    prompt: 'Asked where you would start, which answer commits?',
    options: [
      RecallOption(
        id: 'recall_first_step_everything',
        text: "It could be lots of things, so I'd look at all of them to be safe.",
      ),
      RecallOption(
        id: 'recall_first_step_steps',
        text: 'The sign-up steps first: a big drop usually shows in one place.',
      ),
      RecallOption(
        id: 'recall_first_step_wait',
        text: "I'd wait a month first, in case it's only a seasonal dip.",
      ),
    ],
    correctOptionId: 'recall_first_step_steps',
  ),
);

const lessonUseTheMethod = Lesson(
  id: 'lesson_use_the_method',
  title: "Use the method, don't name it",
  flag: Flag.memorized,
  flaw: 'It names a framework but never applies it to the problem in front of you.',
  takeaway: "Skip the framework's name. Say the first thing you'd check in this problem, and why it comes first.",
  recall: RecallCheck(
    prompt: 'Which opening sounds like real problem-solving?',
    options: [
      RecallOption(
        id: 'recall_use_the_method_framework',
        text:
            "I'd define the problem, gather data, form hypotheses, then test.",
      ),
      RecallOption(
        id: 'recall_use_the_method_check',
        text: "I'd check the drop is real before I touch anything at all.",
      ),
      RecallOption(
        id: 'recall_use_the_method_gut',
        text: "I've solved lots of problems like this, so I'd trust my gut.",
      ),
    ],
    correctOptionId: 'recall_use_the_method_check',
  ),
);

const lessonAnswerFirst = Lesson(
  id: 'lesson_answer_first',
  title: 'Lead with the answer',
  flag: Flag.rambling,
  flaw: 'It saves the point for the end, so an interruption cuts it off.',
  takeaway: 'Put the result in your first two sentences, then tell the story. If they stop you, they have already heard what matters.',
  recall: RecallCheck(
    prompt: 'They might cut in after thirty seconds. Which opening is best?',
    options: [
      RecallOption(
        id: 'recall_answer_first_background',
        text: 'So, to give you some background, it all started in my second year…',
      ),
      RecallOption(
        id: 'recall_answer_first_result',
        text: 'I redesigned our sign-up, and finished sign-ups nearly doubled.',
      ),
      RecallOption(
        id: 'recall_answer_first_team',
        text: 'It was a group project, so first let me explain who did what.',
      ),
    ],
    correctOptionId: 'recall_answer_first_result',
  ),
);

const lessonHonestGap = Lesson(
  id: 'lesson_honest_gap',
  title: "Say what you don't know, then reason",
  flag: Flag.vague,
  flaw: 'A confident guess sounds fine until the next question shows it was a guess.',
  takeaway: "Say which part you don't know, reason from what you do, and say how you'd find out. Honest and useful beats sure and wrong.",
  recall: RecallCheck(
    prompt: "Asked something you don't know, which reply works best?",
    options: [
      RecallOption(
        id: 'recall_honest_gap_bluff',
        text: "Two weeks. That's the standard length for any test like that.",
      ),
      RecallOption(
        id: 'recall_honest_gap_reason',
        text: "I don't know the length, but it needs enough visitors to trust.",
      ),
      RecallOption(
        id: 'recall_honest_gap_freeze',
        text:
            "Sorry, I really don't know. We never covered that at university.",
      ),
    ],
    correctOptionId: 'recall_honest_gap_reason',
  ),
);

const lessonResearchedRange = Lesson(
  id: 'lesson_researched_range',
  title: 'Give a range you can explain',
  flag: Flag.vague,
  flaw: 'A number with no reason behind it is easy to push down, or to wave away.',
  takeaway: 'Look up what similar roles pay, give a range, and say where you sit in it and why. Then the number has something behind it.',
  recall: RecallCheck(
    prompt: 'Asked about salary, which answer is strongest?',
    options: [
      RecallOption(
        id: 'recall_researched_range_low',
        text: "Twenty-eight thousand is fine. I'm just glad to get a start.",
      ),
      RecallOption(
        id: 'recall_researched_range_range',
        text:
            'Similar roles pay thirty to thirty-four; I aim for the top half.',
      ),
      RecallOption(
        id: 'recall_researched_range_high',
        text: "I'd start at forty-five, then see where we end up from there.",
      ),
    ],
    correctOptionId: 'recall_researched_range_range',
  ),
);

const lessonPriceTheRole = Lesson(
  id: 'lesson_price_the_role',
  title: 'Talk about the role, not your needs',
  flag: Flag.offQuestion,
  flaw: 'It talks about what you need or would accept, not what the role is worth.',
  takeaway: "Base pay on the role: what similar jobs pay, and what you bring. Your rent, or 'whatever's fair', leaves them to set it.",
  recall: RecallCheck(
    prompt: 'Which salary answer stays on the role?',
    options: [
      RecallOption(
        id: 'recall_price_the_role_rent',
        text:
            'My rent is high, so I would need at least thirty-five to manage.',
      ),
      RecallOption(
        id: 'recall_price_the_role_market',
        text:
            'Roles like this pay thirty to thirty-four, so I would aim there.',
      ),
      RecallOption(
        id: 'recall_price_the_role_fair',
        text: "Whatever you think is fair is fine. I'm not fussy about money.",
      ),
    ],
    correctOptionId: 'recall_price_the_role_market',
  ),
);

const lessonAskWhatOnlyTheyKnow = Lesson(
  id: 'lesson_ask_what_only_they_know',
  title: 'Ask what only they can answer',
  flag: Flag.generic,
  flaw: 'The website already answers it, so the question shows no thought.',
  takeaway: 'Ask about something you heard today, or something only this team knows: a problem, a project, what a good start looks like.',
  recall: RecallCheck(
    prompt: 'Which question shows you were listening?',
    options: [
      RecallOption(
        id: 'recall_ask_what_only_they_know_values',
        text: 'What are the company values, and how would you describe the culture?',
      ),
      RecallOption(
        id: 'recall_ask_what_only_they_know_drop',
        text: 'You said sign-ups fell. What did the team find in the end?',
      ),
      RecallOption(
        id: 'recall_ask_what_only_they_know_future',
        text: 'Where do you see the company in five years, and why there?',
      ),
    ],
    correctOptionId: 'recall_ask_what_only_they_know_drop',
  ),
);

const lessonAskAboutTheWork = Lesson(
  id: 'lesson_ask_about_the_work',
  title: 'Ask about the work first',
  flag: Flag.offQuestion,
  flaw: 'It asks what the job gives you, so it says little about how you would do it.',
  takeaway: 'Spend your questions on the work: the problems, the team, what a good start looks like. Holidays, bonuses and promotion come with the offer.',
  recall: RecallCheck(
    prompt: 'Your turn to ask. Which question goes first?',
    options: [
      RecallOption(
        id: 'recall_ask_about_the_work_holiday',
        text: 'How many holiday days come with the role, and is there a bonus?',
      ),
      RecallOption(
        id: 'recall_ask_about_the_work_start',
        text: 'What would a good first three months look like in this role?',
      ),
      RecallOption(
        id: 'recall_ask_about_the_work_promotion',
        text: 'How soon could I move up to a more senior role if I do well?',
      ),
    ],
    correctOptionId: 'recall_ask_about_the_work_start',
  ),
);

const lessonMakeTheCase = Lesson(
  id: 'lesson_make_the_case',
  title: 'Make the case in three parts',
  flag: Flag.rambling,
  flaw: 'It lists every strength, so none of them sticks.',
  takeaway: 'Name the two things this job needs most, give one proof for each, and end on why you want it. Then stop.',
  recall: RecallCheck(
    prompt: '"Why you?" Which answer is built best?',
    options: [
      RecallOption(
        id: 'recall_make_the_case_list',
        text: "I'm curious, organised, hard-working, a good listener and a fast learner.",
      ),
      RecallOption(
        id: 'recall_make_the_case_two',
        text: 'It needs users and numbers: I ran twelve interviews and tagged 600 tickets.',
      ),
      RecallOption(
        id: 'recall_make_the_case_school',
        text: 'Well, it really started at school, when I first got into computers…',
      ),
    ],
    correctOptionId: 'recall_make_the_case_two',
  ),
);

const lessonCloseTheOffer = Lesson(
  id: 'lesson_close_the_offer',
  title: 'Get it in writing, then decide',
  flag: Flag.vague,
  flaw: 'Saying yes on the spot means agreeing to terms you have not seen.',
  takeaway: "Thank them, say you want the job, and ask for the offer in writing. Agree a day you'll answer by, and keep to it.",
  recall: RecallCheck(
    prompt: 'They offer you the job. What do you say first?',
    options: [
      RecallOption(
        id: 'recall_close_the_offer_yes',
        text: 'Yes! I accept, whatever the details are. When can I start?',
      ),
      RecallOption(
        id: 'recall_close_the_offer_writing',
        text: 'Thank you, I want this. Can I see it in writing and reply by Friday?',
      ),
      RecallOption(
        id: 'recall_close_the_offer_salary',
        text:
            'Thanks. Before anything else, can we talk about the salary first?',
      ),
    ],
    correctOptionId: 'recall_close_the_offer_writing',
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
  lessonCauseBeforeFix,
  lessonFirstStep,
  lessonUseTheMethod,
  lessonAnswerFirst,
  lessonHonestGap,
  lessonResearchedRange,
  lessonPriceTheRole,
  lessonAskWhatOnlyTheyKnow,
  lessonAskAboutTheWork,
  lessonMakeTheCase,
  lessonCloseTheOffer,
];
