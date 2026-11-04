// Every word on the landing page, in one typed file, so a wording change never touches layout.
//
// The honesty rule (docs/rules/analytics.md, brief 34): no invented users, testimonials, ratings
// or numbers. Every figure is a fact the repository states: the game's content (21 missions, four
// interviewers), the engine (weights, the 1.5 s guess, Leitner days 1, 3 and 7, the XP formula)
// or the published scoring evaluation (docs/scoring-eval.md). Every line an interviewer says is
// a line they say in the game (packages/content).
//
// Copy rules (the landing-page-design skill): sentence case, no hyphens inside sentences, no
// exclamation marks, a verb plus an outcome on every button.

import type { Expression, Person } from '@/cast/people'

export type LinkItem = {
	readonly label: string
	readonly href: string
}

const repo = 'https://github.com/samiarif02/thelastroom'

/** Where the site is served in production; read only at build time (every use is static). */
function productionUrl(): string {
	const host = process.env.VERCEL_PROJECT_PRODUCTION_URL
	return host ? `https://${host}` : 'https://thelastroom-ten.vercel.app'
}

export const site = {
	name: 'The Last Room',
	/**
	 * The production URL, for canonical links, Open Graph and the sitemap. On Vercel it's the
	 * project's own production address, which Vercel sets at build time
	 * (`VERCEL_PROJECT_PRODUCTION_URL`, a system variable: nothing to configure), so a free
	 * `*.vercel.app` address or a custom domain both work without an edit. Locally, the fallback.
	 */
	url: productionUrl(),
	title: 'The Last Room · interview practice game for graduates',
	description:
		'Answer 21 real interview questions from four interviewers, say why your answer works, and get a scored debrief with one lesson. Free, offline, no sign-up needed.',
	repo,
	scoringEval: `${repo}/blob/main/docs/scoring-eval.md`,
	scoringReadme: `${repo}#how-the-score-works`,
	year: 2026
} as const

/** The one action on the page, identical at the top and the bottom. */
export const cta = {
	label: 'Get the app',
	/** The repo: its README says how to install and run the game. Opens in a new tab. */
	href: site.repo,
	newTab: '(opens GitHub in a new tab)',
	risk: ['No sign-up needed', 'Plays offline', 'Your voice is never stored'],
	/** The same three, shorter, for a phone's width. */
	riskShort: ['No sign-up', 'Plays offline', 'Voice never stored']
} as const

/** In page order, so the highlighted link moves along the bar as the page scrolls. */
export const nav = {
	links: [
		{ label: 'The panel', href: '#panel' },
		{ label: 'How it works', href: '#how' },
		{ label: 'Scoring', href: '#scoring' },
		{ label: 'Questions', href: '#faq' }
	] satisfies readonly LinkItem[],
	cta: { label: 'Get the app', href: '#get' },
	open: 'Open the menu',
	close: 'Close the menu',
	home: 'The Last Room, back to the top'
} as const

export const hero = {
	kicker: 'An interview practice game for graduates',
	/** Broken where the thought breaks. */
	title: ['Rehearse the interview', 'before the real one.'],
	body: 'Four interviewers ask you 21 real questions. Pick your lines or say them out loud, explain why they work, and get a scored debrief with one lesson to keep.',
	proof: [
		{ value: '21', label: 'real interview questions' },
		{ value: '4', label: 'interviewers who push back' },
		{ value: '4', label: 'scores, each with its reason' }
	],
	art: {
		label:
			'Marcus, the hiring manager, in an arched window, and the game on a phone: he asks for evidence, you pick a line, and the debrief scores it.',
		speaker: 'Marcus · hiring manager',
		line: '“Tell me about a time you used data to change something.”',
		/** The offline engine's specificity for room 4's strongest answer (the play in docs/scoring-eval.md). */
		dimension: 'Specificity',
		dimensionScore: 82,
		xp: '+91 XP'
	}
} as const

/**
 * The hero phone: room 4, "Show me the evidence", the evidence beat, played the strong way.
 * Every line is the game's own; the scores are the offline engine's for this play (the "strong"
 * case in docs/scoring-eval.md: 82, with these four dimensions), and the XP is the engine's
 * formula for a first clear (20 + 82 ÷ 2 + 30).
 */
export const demo = {
	label: 'The game on a phone, playing room 4 with Marcus',
	pause: 'Pause the demo',
	play: 'Play the demo',
	beats: ['Open', 'Evidence', 'Land'],
	speaker: 'Marcus · hiring manager',
	reaction: 'Fine. You noticed something. Go on.',
	soFar: {
		beat: 'Open',
		line: '“At my Larkfield internship, I noticed the support team kept answering the same question.”'
	},
	pick: 'Pick your evidence',
	pickHint: 'Tap a line, then lock it in',
	options: [
		'We went through a month of tickets, found password resets were the biggest group, and then we cut those by a quarter with a help page.',
		'I tagged 600 tickets from one month. One in three were password resets, so I wrote a help page for them.',
		'I looked through a lot of tickets and found some really clear patterns, mostly around logins, so I suggested some improvements to the team.'
	],
	chosen: 1,
	lock: 'Lock in line B',
	why: {
		speaker: 'Marcus',
		question: 'Why those details?',
		reason: 'He asked about data, so give the actual numbers and what I did with them.',
		verdict: 'That’s the principle.',
		reaction: '“600 tickets, one in three. Good. Numbers.”',
		next: 'Next: land the answer'
	},
	debrief: {
		kicker: 'Debrief · floor 1 · room 4',
		mission: 'Show me the evidence',
		speaker: 'Marcus',
		line: '“A quarter fewer, and a lesson. That I believe.”',
		total: 82,
		outOf: 'of 100',
		verdict: 'A strong answer',
		scorer: 'Offline score',
		xp: '+91 XP',
		dimensions: [
			{ name: 'Relevance', score: 90 },
			{ name: 'Specificity', score: 82 },
			{ name: 'Structure', score: 60 },
			{ name: 'Adaptability', score: 100 }
		],
		/** The weakest dimension is drawn in clay. */
		weakest: 'Structure',
		cta: 'Light room 4'
	},
	tower: {
		greeting: 'Room 4 cleared',
		title: 'Northstar tower',
		lit: '4 of 21 rooms lit',
		week: { label: 'This week', value: '2 of 3' },
		sign: 'Northstar Labs',
		floors: [
			{ name: 'Floor 3 · The final round', note: 'Sam waits here' },
			{ name: 'Floor 2 · Under pressure', note: 'Opens after floor 1' },
			{ name: 'Floor 1 · Get through the door', note: '4 of 7' }
		]
	}
} as const

export const tagline = {
	words: 'Nerves fade when the questions stop being new.',
	note: 'Each room is one real question. Missed something? It comes back in your Recall Room on day 1, 3 and 7, until it sticks.',
	recall: {
		label: 'A Recall Room note, as it arrives on day 3',
		kicker: 'Recall Room · due today',
		greeting: 'Welcome back. Marcus caught you on this one.',
		fell: 'You fell for',
		principle: '“Sharing credit with the team is the professional thing to do.”',
		led: 'It led to a “we” where he wanted your part.',
		day: 'The second look',
		days: [
			{ day: 'Day 1', state: 'done' },
			{ day: 'Day 3', state: 'now' },
			{ day: 'Day 7', state: 'next' }
		]
	}
} as const

export type Tone = 'ch1' | 'honey' | 'ch2' | 'ch3'

export type Interviewer = {
	readonly person: Person
	readonly name: string
	readonly role: string
	/** A line they say in the game. */
	readonly line: string
	readonly listens: string
	readonly rest: Expression
	readonly hover: Expression
	readonly tone: Tone
}

export const panel = {
	title: 'Meet the panel',
	body: 'Four people at Northstar Labs, each listening for something different. They react to what you say, and they ask the follow up you were hoping to avoid.',
	steps: [
		{ title: 'Build the answer.', body: 'Pick a line for each beat, or say it out loud from floor 2.' },
		{ title: 'Say why it works.', body: 'Choosing the principle is what makes it stick.' },
		{ title: 'Read the debrief.', body: 'Four scores, the reason for each, one lesson.' }
	],
	listensLabel: 'Listens for',
	people: [
		{
			person: 'priya',
			name: 'Priya',
			role: 'Recruiter',
			line: '“Keep it to about a minute. I’ll stop you if I want more.”',
			listens: 'did you answer her question',
			rest: 'smile',
			hover: 'talk',
			tone: 'ch1'
		},
		{
			person: 'marcus',
			name: 'Marcus',
			role: 'Hiring manager',
			line: '“I’d want the actual count. And whose it was.”',
			listens: 'your part, and a number',
			rest: 'hmm',
			hover: 'nod',
			tone: 'honey'
		},
		{
			person: 'lena',
			name: 'Lena',
			role: 'Senior engineer',
			line: '“You said ‘we’ caught the error. Who actually caught it?”',
			listens: 'how you handle the follow up',
			rest: 'thinking',
			hover: 'hmm',
			tone: 'ch2'
		},
		{
			person: 'sam',
			name: 'Sam',
			role: 'Head of product',
			line: '“One change, measured. I’d trust that.”',
			listens: 'everything, together',
			rest: 'neutral',
			hover: 'smile',
			tone: 'ch3'
		}
	] satisfies readonly Interviewer[]
} as const

export type Floor = {
	readonly id: string
	readonly level: string
	readonly title: string
	readonly mode: string
	readonly body: string
	readonly points: readonly string[]
	readonly screen: 'answer' | 'voice' | 'tower'
	readonly tone: 'ch1' | 'ch2' | 'ch3'
}

export const floors = {
	kicker: 'How it works',
	title: 'Three floors, one climb',
	body: 'Northstar Labs’ tower has 21 rooms, seven to a floor. Every room is one interview question, and every floor asks more of you.',
	items: [
		{
			id: 'floor-1',
			level: 'Floor 1',
			title: 'Get through the door',
			mode: 'Choose your words',
			body: 'Build each answer in three beats (open, evidence, land) from lines that all sound right. Most are mistakes real candidates make. Then say why the one you kept works.',
			points: [
				'Rooms 1 to 7, with Priya, Marcus and Lena',
				'A pick in under 1.5 seconds counts as a guess',
				'The right line for the wrong reason keeps 60% of its points'
			],
			screen: 'answer',
			tone: 'ch1'
		},
		{
			id: 'floor-2',
			level: 'Floor 2',
			title: 'Under pressure',
			mode: 'Say it out loud',
			body: 'Every answer is spoken, the way it would be in the room. Tell your own story or one from the practice CV, then take the follow up out loud too.',
			points: [
				'Rooms 8 to 14: a conflict, a failure, a deadline that won’t move',
				'Points to cover, never a script',
				'Scored on what you said, never how you sound'
			],
			screen: 'voice',
			tone: 'ch2'
		},
		{
			id: 'floor-3',
			level: 'Floor 3',
			title: 'The final round',
			mode: 'Both, mixed',
			body: 'Chosen lines and spoken answers, mixed the way a final round mixes them: a problem to solve, an interruption, the salary question, your turn to ask.',
			points: [
				'Rooms 15 to 21, with Sam, the head of product',
				'Then the last room: the offer, and what you do with it',
				'Every room you clear lights its door in the tower'
			],
			screen: 'tower',
			tone: 'ch3'
		}
	] satisfies readonly Floor[]
} as const

/** The phone screens beside the floors: real lines from rooms 2 and 8. */
export const screens = {
	answer: {
		label: 'Room 2 on a phone: Priya asks you to introduce yourself, and you pick your opening line.',
		beats: ['Open', 'Evidence', 'Land'],
		speaker: 'Priya · recruiter',
		line: 'So, tell me about yourself.',
		pick: 'Pick your opening',
		pickHint: 'Tap a line, then lock it in',
		options: [
			'I grew up in a small town where I was the one who fixed everyone’s computers, and that’s really where my love of technology began.',
			'I’ve finished a degree in Information Systems, and the part I enjoyed most was user research: finding out why people get stuck.',
			'I’d describe myself as curious, hard working and a good communicator, and I think those three words sum me up pretty well, honestly.'
		],
		chosen: 1,
		lock: 'Lock in line B'
	},
	voice: {
		label: 'Room 8 on a phone: Lena asks about a disagreement, and you answer out loud with the points to cover below.',
		room: 'Floor 2 · room 8',
		mission: 'Team conflict',
		tag: 'Out loud',
		recording: 'Recording',
		listening: 'Listening',
		speaker: 'Lena · senior engineer',
		line: 'Tell me about a time you disagreed with someone you worked with.',
		pointsTitle: 'Points to cover',
		pointsHint: 'your story or the CV',
		points: [
			'A real disagreement, with one person',
			'Their view, fairly: what they wanted',
			'What you did to settle it',
			'How it was settled, then stop'
		],
		privacy: 'Scored when you finish, on what you said. The audio is never stored.',
		time: '0:47',
		cap: 'of 2:00',
		pause: 'Pause',
		again: 'Start again'
	},
	tower: {
		label:
			'Northstar tower on a phone: floor 1, four rooms done, room 5 next, its door ajar with Marcus in the doorway; floor 2 is locked, and Sam waits behind the lit last door on the dark top floor.'
	}
} as const

export type Dimension = {
	readonly name: string
	/** Percent of the score. The four add up to 100. */
	readonly weight: number
	readonly question: string
}

export const scoring = {
	kicker: 'Scoring',
	title: 'Every number has a reason',
	body: 'An answer is scored on four dimensions, out of 100. Each comes with the reason behind it, and the debrief always says which scorer produced the number you see.',
	weightLabel: 'of the score',
	dimensions: [
		{ name: 'Relevance', weight: 25, question: 'Does it answer the question that was asked?' },
		{ name: 'Specificity', weight: 30, question: 'Is there a real example, with your part and a result?' },
		{ name: 'Structure', weight: 25, question: 'Does it open, prove and land? Scored by the weakest beat.' },
		{ name: 'Adaptability', weight: 20, question: 'Does it hold up when the follow up comes?' }
	] satisfies readonly Dimension[],
	scorers: [
		{
			kicker: 'Offline, always',
			title: 'A rule based engine on the phone',
			body: 'Weights written with the content score every answer the same way every time. It needs no network, and the debrief labels it “Offline score”.'
		},
		{
			kicker: 'Online, optional',
			title: 'An AI senior recruiter',
			body: 'With the optional backend on, the answer you built (game content only, never your name) is graded by a model playing a senior recruiter, with one sentence of basis per dimension.'
		}
	],
	readMore: { label: 'Read how the score works', href: site.scoringReadme }
} as const

export const proof = {
	kicker: 'Proof, in public',
	title: 'We test the scorer and publish the results',
	body: 'Before trusting the AI recruiter, we scored 21 answers to the seven floor 1 rooms (a strong, a weak and a guessed one for each), three times over, and published every number.',
	stats: [
		{ value: '92%', label: 'of 63 verdicts landed in the band the content’s author intended' },
		{ value: '7 of 7', label: 'rooms ranked right: the strong answer above the weak and the guessed' },
		{ value: '0.91', label: 'correlation with the offline engine on the same answers' },
		{ value: '5', label: 'points: the median spread when the same answer is scored again' }
	],
	limitsTitle: 'What it doesn’t claim',
	limits: [
		'It doesn’t predict whether you’ll get a job. The story’s outcomes are narrative.',
		'The weights are a hypothesis, not yet checked against answers rated by human recruiters.',
		'21 answers is a small set: it catches a broken prompt, not subtle bias.'
	],
	source: { label: 'Read the full evaluation', href: site.scoringEval },
	date: 'Run on 2 November 2026'
} as const

export type Faq = {
	readonly q: string
	readonly a: string
}

export const faq = {
	kicker: 'Questions',
	title: 'Before you start',
	items: [
		{
			q: 'Is it free?',
			a: 'Yes. It’s free to play, with nothing to buy and no account needed.'
		},
		{
			q: 'Do I need an account?',
			a: 'No. Open the game and play. Nothing asks for your name or email before the first question. Saving your progress with an email is optional.'
		},
		{
			q: 'Does it work offline?',
			a: 'Yes, all 21 rooms. Your progress is saved on the phone first, and answers get the offline score. The AI recruiter and the backup only run if you turn the optional backend on.'
		},
		{
			q: 'Is my voice recorded or stored?',
			a: 'A spoken answer is recorded on your phone so it can be scored, then deleted after the debrief. One sent for AI scoring is used to score it and then discarded.'
		},
		{
			q: 'Does it judge my accent or grammar?',
			a: 'No. Spoken answers are scored on what you said, never on your accent or how you sound.'
		},
		{
			q: 'How is my answer scored?',
			a: 'On relevance, specificity, structure and adaptability, weighted 25, 30, 25 and 20. Each score comes with its reason, and a guess, or the right line for the wrong reason, scores less.'
		},
		{
			q: 'Who is it for?',
			a: 'Students, fresh graduates, career changers and non native English speakers getting ready for their first interviews. You play a graduate applying for a Product Associate role.'
		},
		{
			q: 'Will it help with a real interview at my company?',
			a: 'It drills the questions most first interviews ask and the habits that answer them well. It doesn’t know your company’s process, and it can’t promise an offer.'
		},
		{
			q: 'Is Northstar Labs real?',
			a: 'No. Northstar Labs and its people are fictional. The questions are the real ones.'
		},
		{
			q: 'Is there an iPhone version?',
			a: 'Not yet. The game is built for both, and the iPhone build is still being tested.'
		}
	] satisfies readonly Faq[]
} as const

export const finale = {
	kicker: 'Your first interview doesn’t have to be your first try',
	title: ['Walk in having heard', 'the questions before.'],
	body: 'Four interviewers, 21 rooms and a debrief after every answer. Play a room whenever you have a few minutes.',
	cast: [
		{ person: 'priya', expression: 'smile', hover: 'talk' },
		{ person: 'marcus', expression: 'nod', hover: 'smile' },
		{ person: 'lena', expression: 'listening', hover: 'smile' },
		{ person: 'sam', expression: 'smile', hover: 'nod' }
	] as const satisfies readonly { readonly person: Person; readonly expression: Expression; readonly hover: Expression }[]
} as const

export const footer = {
	line: 'Rehearse the interview before the real one.',
	links: [
		{ label: 'Privacy', href: '/privacy/' },
		{ label: 'Terms', href: '/terms/' },
		{ label: 'Source on GitHub', href: repo }
	] satisfies readonly LinkItem[],
	note: 'Northstar Labs and its people are fictional.'
} as const

export const notFound = {
	kicker: 'Error 404',
	title: 'Wrong floor.',
	body: 'This room isn’t in the building. Priya will walk you back down.',
	back: 'Back to the lobby'
} as const

/**
 * Where an emailed link lands (FR-3, status 67). "Save your progress" sends Supabase's default
 * confirmation email, whose link comes here once the address is confirmed; Supabase sends an
 * expired or used link here too, with `#error=…`.
 */
export const verified = {
	title: 'You’re verified',
	kicker: 'Progress saved',
	heading: 'You’re verified.',
	body: 'Your progress is saved to your email. Go back to The Last Room: it notices by itself.',
	open: 'Open the app',
	desktop:
		'Opened this on a computer? Your phone is already saved, so just go back to the app there. A sign in link for a new phone works when you open it on that phone.',
	expiredKicker: 'Link expired',
	expiredHeading: 'This link expired or was used.',
	expiredBody: 'Request a new one in the app: Settings, then Save your progress. The newest link is the one that works.',
	home: 'Back to the lobby'
} as const

export type LegalSection = {
	readonly title: string
	readonly body: readonly string[]
}

export const privacy = {
	title: 'Privacy',
	description: 'What The Last Room keeps, and where: no sign-up needed, progress on your phone, your voice never stored.',
	intro: 'The short version: no sign-up needed, your progress stays on your phone, and your voice isn’t stored.',
	sections: [
		{
			title: 'What the game keeps',
			body: [
				'Your progress (rooms played, scores, Recall Room notes, XP) is saved on your phone. The whole game works offline.',
				'Nothing leaves the phone unless the app is set up with the optional backend, for backup and AI scoring.'
			]
		},
		{
			title: 'Your voice',
			body: [
				'A spoken answer is recorded on the phone so it can be scored, and deleted after the debrief.',
				'With AI scoring, the recording is sent to be transcribed and scored, then discarded: the audio is never stored. The written transcript and the scores are kept in your own guest account, which only you can read. It is scored on what you said, never on how you sound.'
			]
		},
		{
			title: 'The optional backend',
			body: [
				'When the app is set up with it, a guest session with no name or email backs up your progress (an email is added only if you choose to save your progress with one), and the AI recruiter receives your answer (the lines you chose, or your recording), never your name.'
			]
		},
		{
			title: 'This website',
			body: [
				'This site sets no cookies, runs no analytics and loads nothing from anyone else. Its fonts are served from here.'
			]
		}
	] satisfies readonly LegalSection[],
	updated: 'Last updated 4 November 2026'
} as const

export const terms = {
	title: 'Terms',
	description: 'The plain terms for playing The Last Room, a free interview practice game.',
	intro: 'The Last Room is a free practice game. Playing it means agreeing to these plain terms.',
	sections: [
		{
			title: 'What it is',
			body: [
				'A game for practising interview answers. The scores and lessons are practice feedback, not a prediction of how a real interview will go, and no job is promised.'
			]
		},
		{
			title: 'The story',
			body: ['Northstar Labs and its people are fictional. Any likeness to a real company or person is a coincidence.']
		},
		{
			title: 'The app',
			body: [
				'The app is an early release, provided as it is, without warranty. Things may change between versions.'
			]
		},
		{
			title: 'The source',
			body: ['The code is public on GitHub, where issues and questions are welcome.']
		}
	] satisfies readonly LegalSection[],
	updated: 'Last updated 4 November 2026'
} as const
