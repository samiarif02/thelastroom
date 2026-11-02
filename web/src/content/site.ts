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

export type Step = {
	readonly numeral: string
	readonly title: string
	readonly body: string
	readonly still: Still
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

const phone = { width: 540, height: 1140 } as const

export const site = {
	name: 'The Last Room',
	/**
	 * The production URL, for canonical links, Open Graph and the sitemap. Change it here once
	 * the Vercel project has its domain (web/README.md).
	 */
	url: 'https://thelastroom.vercel.app',
	title: 'The Last Room: practise the interview before the one that counts',
	description:
		'An interview-practice game that plays like a film. Answer a recruiter, say why, and get a scored debrief with one lesson. Coming soon on Google Play and the App Store.',
	repo,
	releases: `${repo}/releases`,
	scoringReadme: `${repo}#how-the-score-works`,
	year: 2026
} as const

export const nav: readonly LinkItem[] = [
	{ label: 'How it works', href: '#how-it-works' },
	{ label: 'Why it works', href: '#why-it-works' },
	{ label: 'Scoring', href: '#scoring' },
	{ label: 'Privacy', href: '#privacy' }
]

export const hero = {
	eyebrow: 'An interview-practice game',
	title: 'The Last Room',
	line: 'Practise the interview before the one that counts.',
	body: 'You are a graduate interviewing for a Product Associate role at Northstar Labs, a company that exists only in the game. Each mission is one question from a recruiter. Build your answer, say why you chose it, and walk out with a debrief that shows what made it stronger or weaker.',
	preview: { label: 'Get the Android preview', href: site.releases },
	stores: {
		label: 'Coming soon on',
		names: ['Google Play', 'App Store']
	},
	stills: [
		{
			src: '/screens/tower.jpg',
			alt: 'The tower, the home screen: the next mission, Tell Me About Yourself, with the recruiter Priya, and Chapter 1’s rooms below it.',
			...phone
		},
		{
			src: '/screens/mission-answers.jpg',
			alt: 'Mission 1: Priya asks “So, what made you apply for this role?” and four plausible opening lines wait below her.',
			...phone
		}
	]
} as const

export const howItWorks = {
	eyebrow: 'How it works',
	title: 'A mission in three steps',
	intro: 'One question, a few minutes, one lesson you can use in the real room.',
	steps: [
		{
			numeral: 'i',
			title: 'Hear the question',
			body: 'A recruiter asks a real interview question: why this role, tell me about yourself, a time something went wrong. She reacts to what you say and pushes back with a follow-up.',
			still: {
				src: '/screens/mission-answers.jpg',
				alt: 'Priya asks why you applied, with four answers to choose from: each one a mistake real candidates make, or the one that holds.',
				...phone
			}
		},
		{
			numeral: 'ii',
			title: 'Build or speak your answer',
			body: 'In Chapter 1 you build it in three beats (open, evidence, land) from lines that are realistic mistakes, not jokes, and say why you chose each one. From Chapter 2 you answer out loud, as you would in the room.',
			still: {
				src: '/screens/why-step.jpg',
				alt: 'The why step: Priya asks “Why lead with that, Candidate?” and you pick the principle behind your line.',
				...phone
			}
		},
		{
			numeral: 'iii',
			title: 'Get a scored debrief',
			body: 'A dossier lands on the desk: a score on four dimensions, what you said, what you fell for and what holds instead. One lesson to take with you.',
			still: {
				src: '/screens/debrief.jpg',
				alt: 'The debrief: for each beat, the line you chose, the reason you gave, what you fell for and what holds.',
				...phone
			}
		}
	] satisfies readonly Step[]
} as const

export const whyItWorks = {
	eyebrow: 'Why it works',
	title: 'Built to teach, not to quiz',
	intro: 'Reading fifty model answers is not the same as choosing one under pressure. The game is built around the moments that decide an interview.',
	reasons: [
		{
			title: 'Each mission names what you practise',
			body: 'Before you start, you know the skill: answering “why this role?” about the job, introducing yourself in under a minute, owning a gap, backing a claim with a result.'
		},
		{
			title: 'The Recall Room brings it back',
			body: 'Every trap you fell for becomes a card that returns one day later, then three, then seven, until it stops catching you.'
		},
		{
			title: 'You play against your first try',
			body: 'Your first mission is your baseline. Later scores are shown against it, dimension by dimension, so you see what changed, not a leaderboard.'
		},
		{
			title: 'It can’t be played on autopilot',
			body: 'A pick made in under 1.5 seconds counts as a guess and scores nothing. The strongest line chosen for the wrong reason keeps only 60% of its points.'
		}
	] satisfies readonly Reason[],
	still: {
		src: '/screens/recall-room.jpg',
		alt: 'A Recall Room card: “The recruiter asks why you applied. Which answer stays on the question?” with three answers.',
		...phone
	}
} as const

export const scoring = {
	eyebrow: 'How we score',
	title: 'Every number has a reason',
	intro: 'An answer is scored on four dimensions, out of 100. The debrief always says which scorer produced the number you see.',
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
			body: 'When the optional backend is on, the answer you built (game content only, never your name) is graded by a model acting as a senior recruiter: each dimension from 0 to 100 with one sentence of basis, so every number says why.'
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
	eyebrow: 'Privacy',
	title: 'Your practice stays yours',
	points: [
		{
			title: 'No sign-up',
			body: 'Open the game and play. No account, no email, no form before the first question.'
		},
		{
			title: 'Your progress lives on your phone',
			body: 'Everything is saved on the device first, and the whole game works offline. Nothing leaves the phone unless you turn on the optional backup or AI scoring.'
		},
		{
			title: 'Your voice isn’t stored',
			body: 'A spoken answer sent for AI scoring is used to score it and then discarded. Recordings on the phone are deleted after the debrief.'
		}
	] satisfies readonly PrivacyPoint[]
} as const

export const footer = {
	line: 'Practise the interview before the one that counts.',
	privacy: 'No sign-up. Your progress stays on your phone. Your voice isn’t stored.',
	links: [
		{ label: 'GitHub', href: repo },
		{ label: 'Android preview', href: site.releases },
		{ label: 'How the score works', href: site.scoringReadme }
	] satisfies readonly LinkItem[],
	note: 'Northstar Labs and its people are fictional.'
} as const
