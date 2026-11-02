import {
	BatteryHigh,
	CellSignalHigh,
	CheckCircle,
	Handshake,
	LockSimple,
	WifiHigh,
	X
} from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties, ReactNode } from 'react'

import { Figure } from '@/cast/Figure'
import type { Expression, Person } from '@/cast/people'

import styles from './parts.module.css'

// The app's kit, drawn for the phone pictures (direction.md, "Screen by screen"): the status
// bar, the top bar with the beats and trust, the room with the interviewer in it, the speech
// bubble, the answer cards and the primary button. Sizes are the app's, at 390 wide.

/** The skyline through the arched glass: x, width and height of each building. */
const city: readonly (readonly [number, number, number])[] = [
	[4, 22, 36],
	[30, 28, 58],
	[62, 18, 30],
	[84, 30, 48],
	[118, 26, 34],
	[148, 24, 62],
	[176, 30, 40]
]

export function StatusBar({ tone = 'ink' }: { readonly tone?: 'ink' | 'light' }) {
	return (
		<div className={`${styles.status} ${tone === 'light' ? styles.statusLight : ''}`}>
			<span>9:41</span>
			<span className={styles.statusIcons}>
				<CellSignalHigh weight="fill" />
				<WifiHigh weight="fill" />
				<BatteryHigh weight="fill" />
			</span>
		</div>
	)
}

/** Close, the three beats (the current one part filled) and the trust pips. */
export function MissionBar({ beats, current }: { readonly beats: readonly string[]; readonly current: number }) {
	return (
		<div className={styles.bar}>
			<span className={styles.iconTile}>
				<X weight="bold" />
			</span>
			<ol className={styles.beats}>
				{beats.map((beat, i) => (
					<li key={beat} className={i < current ? styles.done : i === current ? styles.now : undefined}>
						<span />
						{beat}
					</li>
				))}
			</ol>
			<span className={styles.trust}>
				<Handshake weight="fill" />
				<b />
				<b />
				<b />
				<b className={styles.off} />
				<b className={styles.off} />
			</span>
		</div>
	)
}

/** A top bar with a title instead of beats: the voice room, the debrief. */
export function TitleBar({ kicker, title, aside }: { readonly kicker: string; readonly title: string; readonly aside?: ReactNode }) {
	return (
		<div className={styles.titleBar}>
			<span className={styles.iconTile}>
				<X weight="bold" />
			</span>
			<span className={styles.titleText}>
				<span className="caption-4">{kicker}</span>
				<span className="heading-6">{title}</span>
			</span>
			{aside}
		</div>
	)
}

type RoomProps = {
	readonly person: Person
	readonly expression: Expression
	readonly also?: readonly Expression[]
	/** Tags over the glass, like "Recording". */
	readonly tags?: ReactNode
	/** Marks the figure for a script that changes its expression. */
	readonly figureHook?: string
}

/** The flat office: arched glass onto the city, a plant, the desk, the interviewer. */
export function RoomStage({ person, expression, also, tags, figureHook }: RoomProps) {
	return (
		<div className={styles.room}>
			<div className={styles.glass}>
				{city.map(([left, width, height]) => (
					<i key={left} style={{ left, width, height } satisfies CSSProperties} />
				))}
			</div>
			<div className={styles.plant}>
				<span />
				<span />
				<span />
			</div>
			<div className={styles.who} data-figure={figureHook}>
				<Figure person={person} expression={expression} also={also ?? []} idle={false} />
			</div>
			<div className={styles.desk} />
			{tags ? <div className={styles.tags}>{tags}</div> : null}
		</div>
	)
}

/** The interviewer's line, overlapping the room. `typed` reserves the full line's space. */
export function Bubble({ speaker, line, typed }: { readonly speaker: string; readonly line: string; readonly typed?: boolean }) {
	return (
		<div className={styles.bubble}>
			<p className={`caption-3 ${styles.speaker}`}>{speaker}</p>
			{typed ? (
				<p className={`heading-6 ${styles.typedLine}`}>
					<span className={styles.ghost}>{line}</span>
					<span className={styles.typed} data-type={line}>
						{line}
					</span>
				</p>
			) : (
				<p className="heading-6">{line}</p>
			)}
		</div>
	)
}

export function SoFar({ beat, line }: { readonly beat: string; readonly line: string }) {
	return (
		<div className={styles.soFar}>
			<CheckCircle weight="fill" />
			<p className="body-6">
				<b>{beat}</b> {line}
			</p>
		</div>
	)
}

const letters = ['A', 'B', 'C', 'D'] as const

/** The answer cards: a letter tile and the line; `chosen` is lifted and ringed. */
export function AnswerCards({
	title,
	hint,
	options,
	chosen
}: {
	readonly title: string
	readonly hint: string
	readonly options: readonly string[]
	readonly chosen: number
}) {
	return (
		<>
			<div className={styles.pickHead}>
				<p className="body-1">{title}</p>
				<p className={`caption-4 ${styles.hint}`}>{hint}</p>
			</div>
			<ul className={styles.options}>
				{options.map((option, i) => (
					<li
						key={option}
						className={`${styles.option} ${i === chosen ? styles.chosen : ''}`}
						style={{ '--i': i } as CSSProperties}
					>
						<span className={styles.letter}>{letters[i]}</span>
						<p className="body-3">{option}</p>
					</li>
				))}
			</ul>
		</>
	)
}

/** The primary button, pinned at the bottom: honey, 56 tall, a hard edge below. */
export function Dock({ label, icon, ground = 'tint' }: { readonly label: string; readonly icon?: ReactNode; readonly ground?: 'tint' | 'paper' }) {
	return (
		<div className={`${styles.dock} ${ground === 'paper' ? styles.dockPaper : ''}`}>
			<span className={styles.button}>
				{icon ?? <LockSimple weight="bold" />}
				{label}
			</span>
		</div>
	)
}

/** An arch-framed portrait on a coloured ground: the app's avatar shape. */
export function ArchPortrait({
	person,
	expression,
	also,
	className,
	figureHook
}: {
	readonly person: Person
	readonly expression: Expression
	readonly also?: readonly Expression[]
	readonly className?: string | undefined
	readonly figureHook?: string
}) {
	return (
		<span className={`${styles.archPortrait} ${className ?? ''}`} data-figure={figureHook}>
			<Figure person={person} expression={expression} also={also ?? []} idle={false} />
		</span>
	)
}
