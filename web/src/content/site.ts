// Every word on the landing page, in one typed file, so a wording change never touches layout.
//
// The honesty rule (docs/rules/analytics.md, brief 34): no invented users, testimonials,
// ratings or numbers. Every figure here is a fact of the game (weights, intervals, thresholds)
// that the repository's README or engine states; nothing is a claim about uptake.

export type LinkItem = {
	readonly label: string
	readonly href: string
}

export type Still = {
	/** Under `public/`. */
	readonly src: string
	readonly alt: string
	readonly width: number
	readonly height: number
}

/** A still with the plate under its frame, like a room sign: "1.1 · The question". */
export type Exhibit = Still & {
	readonly caption: string
}

/** How a mission is answered: chosen from written lines, or spoken out loud. */
export type AnswerMode = 'lines' | 'voice'

/** A floor's wayfinding colour: Chapter 1 teal, Chapter 2 signal blue, Chapter 3 oxblood. */
export type FloorTone = 'teal' | 'blue' | 'oxblood'

export type MissionEntry = {
	readonly number: number
	readonly title: string
	readonly mode: AnswerMode
}

export type Floor = {
	/** The section's anchor, which the lobby directory links to. */
	readonly id: string
	readonly level: '1' | '2' | '3'
	readonly title: string
	/** How its rooms are answered, as the floor sign says it. */
	readonly mode: string
	readonly tone: FloorTone
	readonly body: string
	readonly missions: readonly MissionEntry[]
}

export type Step = {
	readonly numeral: string
	readonly title: string
	readonly body: string
	readonly still: Exhibit
}

export type Reason = {
	readonly title: string
	readonly body: string
}

export type Dimension = {
	readonly name: string
	/** Percent of the offline score. The four add up to 100. */
	readonly weight: number
	readonly question: string
}

export type Scorer = {
	readonly eyebrow: string
	readonly title: string
	readonly body: string
}

export type PrivacyPoint = {
	readonly title: string
	readonly body: string
}

const repo = 'https://github.com/samiarif02/thelastroom'

// Every still is 480 px wide (twice the widest frame on the page), status bar cropped.
const phone = { width: 480, height: 1040 } as const

/** Where the site is served in production; read only at build time (every use is static). */
function productionUrl(): string {
	const host = process.env.VERCEL_PROJECT_PRODUCTION_URL
	return host ? `https://${host}` : 'https://thelastroom.vercel.app'
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
	title: 'The Last Room: practise the interview before the one that counts',
	description:
		'An interview-practice game that plays like a film. Answer a recruiter, say why, and get a scored debrief with one lesson. Coming soon on Google Play and the App Store.',
	repo,
	releases: `${repo}/releases`,
	scoringReadme: `${repo}#how-the-score-works`,
	year: 2026
} as const

export const nav: readonly LinkItem[] = [
	{ label: 'Floor 1', href: '#floor-1' },
	{ label: 'Floor 2', href: '#floor-2' },
	{ label: 'Floor 3', href: '#floor-3' },
	{ label: 'Recall Room', href: '#recall-room' },
	{ label: 'Scoring', href: '#scoring' },
	{ label: 'Privacy', href: '#privacy' }
]

const modes = { lines: 'Choose', voice: 'Speak' } as const satisfies Record<AnswerMode, string>

/** The building: Northstar Labs' tower, three floors of seven rooms, the last room at the top. */
export const floors = [
	{
		id: 'floor-1',
		level: '1',
		title: 'Get Through the Door',
		mode: 'Choose your words',
		tone: 'teal',
		body: 'You build each answer in three beats (open, evidence, land) from lines that are realistic mistakes or the one that holds, and say why you chose each.',
		missions: [
			{ number: 1, title: 'The Opportunity', mode: 'lines' },
			{ number: 2, title: 'Tell Me About Yourself', mode: 'lines' },
			{ number: 3, title: 'The Experience Gap', mode: 'lines' },
			{ number: 4, title: 'Show Me the Evidence', mode: 'lines' },
			{ number: 5, title: 'Something Went Wrong', mode: 'lines' },
			{ number: 6, title: 'The Follow-Up Trap', mode: 'lines' },
			{ number: 7, title: 'First Round Review', mode: 'lines' }
		]
	},
	{
		id: 'floor-2',
		level: '2',
		title: 'Under Pressure',
		mode: 'Say it out loud',
		tone: 'blue',
		body: 'Every answer is spoken. A conflict, a failure, a deadline that won’t move: tell your own story or one from the practice CV, then take the follow-up out loud too.',
		missions: [
			{ number: 8, title: 'Team Conflict', mode: 'voice' },
			{ number: 9, title: 'The Failure', mode: 'voice' },
			{ number: 10, title: 'No Clear Instructions', mode: 'voice' },
			{ number: 11, title: 'Tight Deadline', mode: 'voice' },
			{ number: 12, title: 'The Uncomfortable Request', mode: 'voice' },
			{ number: 13, title: 'The Unexpected Follow-Up', mode: 'voice' },
			{ number: 14, title: 'Panel Review', mode: 'voice' }
		]
	},
	{
		id: 'floor-3',
		level: '3',
		title: 'The Final Round',
		mode: 'Both',
		tone: 'oxblood',
		body: 'Chosen lines and spoken answers, mixed the way a final round is: a problem to solve, an interruption, the salary question, your turn to ask.',
		missions: [
			{ number: 15, title: 'Solve the Problem', mode: 'lines' },
			{ number: 16, title: 'The Interruption', mode: 'voice' },
			{ number: 17, title: '“I Don’t Know”', mode: 'voice' },
			{ number: 18, title: 'The Salary Question', mode: 'lines' },
			{ number: 19, title: 'Your Turn to Ask', mode: 'lines' },
			{ number: 20, title: 'The Final Interview', mode: 'voice' },
			{ number: 21, title: 'The Decision', mode: 'voice' }
		]
	}
] as const satisfies readonly Floor[]

export const rooms = {
	label: 'Rooms',
	modes,
	/** "Rooms 01–07": the span of room numbers on a floor. */
	span: (floor: Floor): string => {
		const first = floor.missions[0]?.number ?? 0
		const last = floor.missions[floor.missions.length - 1]?.number ?? first
		return `Rooms ${String(first).padStart(2, '0')}–${String(last).padStart(2, '0')}`
	}
} as const

export const hero = {
	kicker: 'The Last Room · an interview-practice game',
	title: 'Practise the interview before the one that counts.',
	body: 'You are a graduate interviewing for a Product Associate role at Northstar Labs, a company that exists only in the game. Each room is one question from a recruiter. Choose your answer or say it out loud, say why, and walk out with a debrief that shows what made it stronger or weaker.',
	preview: { label: 'Get the Android preview', href: site.releases },
	stores: {
		label: 'Coming soon on',
		names: ['Google Play', 'App Store']
	},
	directory: {
		building: 'Northstar Labs',
		title: 'Directory',
		summary: '21 rooms on three floors',
		lastRoom: { mark: '21', name: 'The Last Room', detail: 'Room 21 · The Decision' },
		lobby: { mark: 'L', name: 'Lobby', detail: 'You are here' }
	}
} as const

export const howItWorks = {
	label: 'How a room works',
	steps: [
		{
			numeral: '1',
			title: 'Hear the question',
			body: 'A recruiter asks a real interview question: why this role, tell me about yourself, a time something went wrong. She reacts to what you say and pushes back with a follow-up.',
			still: {
				src: '/screens/mission-answers.jpg',
				alt: 'Priya asks why you applied, with four answers to choose from: each one a mistake real candidates make, or the one that holds.',
				caption: '1.1 · The question',
				...phone
			}
		},
		{
			numeral: '2',
			title: 'Build or speak your answer',
			body: 'On Floor 1 you build it from lines and say why you chose each one. From Floor 2 you answer out loud, as you would in the room.',
			still: {
				src: '/screens/why-step.jpg',
				alt: 'The why step: Priya asks “Why lead with that, Candidate?” and you pick the principle behind your line.',
				caption: '1.2 · The why step',
				...phone
			}
		},
		{
			numeral: '3',
			title: 'Get a scored debrief',
			body: 'A score on four dimensions, each with its reason, what you fell for and what holds instead. One lesson to take with you.',
			still: {
				src: '/screens/debrief-assessment.jpg',
				alt: 'The debrief: a candidate assessment from Northstar Labs scoring relevance, specificity, structure and adaptability out of 100, a note, “Answer the question they asked”, and the overall score sealed.',
				caption: '1.3 · The debrief',
				...phone
			}
		}
	] satisfies readonly Step[],
	tower: {
		src: '/screens/tower.jpg',
		alt: 'The tower, the home screen: the next mission, Tell Me About Yourself, with the recruiter Priya, and Chapter 1’s rooms below it.',
		caption: '1.0 · The tower, in the app',
		...phone
	} satisfies Exhibit
} as const

export const voice = {
	label: 'A spoken answer',
	title: 'Say it the way you would in the room',
	body: [
		'The interviewer asks the question out loud and you answer out loud. Pause, carry on or delete the take before you send it.',
		'Online, the AI recruiter scores what you said and shows you what it heard. Offline, you listen back and tick the points you made, and the engine scores them. Never on your accent or how you sound.'
	],
	still: {
		src: '/screens/voice-recording.jpg',
		alt: 'A voice mission: the interviewer asks “Tell me about a time a plan changed under you.” and the recorder runs at 0:12 of 0:30, with Delete and Done.',
		caption: '2.1 · Recording',
		...phone
	} satisfies Exhibit
} as const

export const lastRoom = {
	label: 'Room 21 · The Decision',
	body: 'Where the story ends: get it in writing, then decide.'
} as const

export const whyItWorks = {
	mark: 'R',
	label: 'The Recall Room',
	aside: 'Why it works',
	title: 'Built to teach, not to quiz',
	intro: 'Reading fifty model answers is not the same as choosing one under pressure. The game is built around the moments that decide an interview.',
	reasons: [
		{
			title: 'Each room names what you practise.',
			body: 'Before you start, you know the skill: answering “why this role?” about the job, introducing yourself in under a minute, owning a gap, backing a claim with a result.'
		},
		{
			title: 'The Recall Room brings it back.',
			body: 'Every trap you fell for becomes a card that returns one day later, then three, then seven, until it stops catching you.'
		},
		{
			title: 'You play against your first try.',
			body: 'Your first mission is your baseline. Later scores are shown against it, dimension by dimension, so you see what changed, not a leaderboard.'
		},
		{
			title: 'It can’t be played on autopilot.',
			body: 'A pick made in under 1.5 seconds counts as a guess and scores nothing. The strongest line chosen for the wrong reason keeps only 60% of its points.'
		}
	] satisfies readonly Reason[],
	recall: {
		label: 'A trap comes back',
		days: [1, 3, 7]
	},
	still: {
		src: '/screens/recall-room.jpg',
		alt: 'A Recall Room card: “The recruiter asks why you applied. Which answer stays on the question?” with three answers.',
		caption: 'R.1 · A Recall Room card',
		...phone
	} satisfies Exhibit
} as const

export const scoring = {
	mark: 'N',
	label: 'Notice board',
	aside: 'How we score',
	title: 'Every number has a reason',
	intro: 'An answer is scored on four dimensions, out of 100. The debrief always says which scorer produced the number you see.',
	board: { title: 'How an answer is weighed', total: 'Total 100' },
	dimensions: [
		{ name: 'Relevance', weight: 25, question: 'Does it answer the question that was asked?' },
		{ name: 'Specificity', weight: 30, question: 'Is there a real example, with your part and a result?' },
		{ name: 'Structure', weight: 25, question: 'Does it open, prove and land? Scored by the weakest beat.' },
		{ name: 'Adaptability', weight: 20, question: 'Does it hold up when the follow-up comes?' }
	] satisfies readonly Dimension[],
	scorers: [
		{
			eyebrow: 'Online',
			title: 'An AI senior recruiter',
			body: 'When the optional backend is on, your answer (game content only, never your name) is graded by a model acting as a senior recruiter: each dimension from 0 to 100 with one sentence of basis, so every number says why.'
		},
		{
			eyebrow: 'Offline',
			title: 'A deterministic engine',
			body: 'With no network, a rule-based engine on the phone scores the answer from weights written with the content. The same answer always gets the same score, and it is labelled “Offline score”.'
		}
	] satisfies readonly Scorer[],
	limitsTitle: 'What it doesn’t do',
	limits: [
		'It doesn’t predict whether you’ll get a job. The story’s outcomes are narrative.',
		'The weights are a hypothesis. They haven’t been validated against answers rated by human recruiters.',
		'The AI’s scores aren’t perfectly reproducible. A fixed temperature narrows the spread; it doesn’t remove it.',
		'Spoken answers are scored on what you said, never on accent or how you sound.'
	],
	readMore: { label: 'Read how the score works', href: site.scoringReadme }
} as const

export const privacy = {
	mark: 'P',
	label: 'House rules',
	aside: 'Privacy',
	title: 'Your practice stays yours',
	points: [
		{
			title: 'No sign-up',
			body: 'Open the game and play. No account, no email, no form before the first question.'
		},
		{
			title: 'Your progress stays on your phone',
			body: 'Everything is saved on the device first, and the whole game works offline. Nothing leaves the phone unless you turn on the optional backup or AI scoring.'
		},
		{
			title: 'Your voice isn’t stored',
			body: 'A spoken answer sent for AI scoring is used to score it and then discarded. Recordings on the phone are deleted after the debrief.'
		}
	] satisfies readonly PrivacyPoint[]
} as const

export const footer = {
	label: 'Way out',
	line: 'Practise the interview before the one that counts.',
	privacy: 'No sign-up. Your progress stays on your phone. Your voice isn’t stored.',
	links: [
		{ label: 'GitHub', href: repo },
		{ label: 'Android preview', href: site.releases },
		{ label: 'How the score works', href: site.scoringReadme }
	] satisfies readonly LinkItem[],
	note: 'Northstar Labs and its people are fictional.'
} as const
