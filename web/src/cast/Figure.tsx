import type { CSSProperties, ReactElement } from 'react'

import {
	browShapes,
	catchLight,
	featureInk,
	type BrowKind,
	type EyeKind,
	type Expression,
	type MouthKind,
	type Palette,
	type Person,
	palettes,
	poses
} from './people'
import styles from './Figure.module.css'

// One interviewer, drawn on cast.js's 200 × 200 grid in plain paths, ellipses and circles (no
// filters, no gradients), in the daylight style: one shade tone per material, a shading crescent
// on the face's far side and a faint rim light on the hair.
//
// Every expression passed in `faces` is drawn, stacked; the svg's `data-expr` picks the one that
// shows, and CSS blends between them (faces cross-fade, the head tilts) over 300 ms. So a script
// can change the expression by setting one attribute, and a hover can swap it with no script at
// all (`hover`, inside an element with the global `react-host` class).

const HEAD =
	'M100 38 C126 38 140 56 140 82 C140 106 130 125 113 132.6 C106 135.6 94 135.6 87 132.6 C70 125 60 106 60 82 C60 56 74 38 100 38Z'
const TORSO = 'M14 200 C16 172 30 157 58 150.5 L84 145 L116 145 L142 150.5 C170 157 184 172 186 200Z'
const EYE_X = [84, 116] as const

/** Eyes that can blink (closed and happy eyes are already shut). */
const blinking: ReadonlySet<EyeKind> = new Set<EyeKind>(['open', 'wide', 'up', 'lidded'])

function eye(kind: EyeKind, cx: number): ReactElement {
	switch (kind) {
		case 'open':
			return (
				<>
					<path d={`M${cx - 6.6} 86 Q${cx} 77.4 ${cx + 6.6} 86 Q${cx} 92.2 ${cx - 6.6} 86Z`} fill={featureInk} />
					<circle cx={cx + 1.9} cy={84} r={1.5} fill={catchLight} />
				</>
			)
		case 'wide':
			return (
				<>
					<path d={`M${cx - 6.8} 86 Q${cx} 76 ${cx + 6.8} 86 Q${cx} 93 ${cx - 6.8} 86Z`} fill={featureInk} />
					<circle cx={cx + 2} cy={83.4} r={1.6} fill={catchLight} />
				</>
			)
		case 'up':
			return (
				<>
					<path
						d={`M${cx - 6.2} 85 Q${cx + 0.8} 76.6 ${cx + 6.8} 84.4 Q${cx + 0.6} 90.6 ${cx - 6.2} 85Z`}
						fill={featureInk}
					/>
					<circle cx={cx + 3} cy={82.4} r={1.5} fill={catchLight} />
				</>
			)
		case 'happy':
			return <path d={`M${cx - 7} 87.4 Q${cx} 78.6 ${cx + 7} 87.4 Q${cx} 84.2 ${cx - 7} 87.4Z`} fill={featureInk} />
		case 'closed':
			return (
				<path
					d={`M${cx - 6.5} 86 Q${cx} 90.4 ${cx + 6.5} 86`}
					fill="none"
					stroke={featureInk}
					strokeWidth={2.3}
					strokeLinecap="round"
				/>
			)
		case 'lidded':
			return (
				<>
					<path d={`M${cx - 6.6} 86 L${cx + 6.6} 85.4 Q${cx} 91.4 ${cx - 6.6} 86Z`} fill={featureInk} />
					<path
						d={`M${cx - 7.4} 85.2 L${cx + 7.4} 84.6`}
						stroke={featureInk}
						strokeWidth={1.8}
						strokeLinecap="round"
					/>
				</>
			)
	}
}

/** The lid crease above an eye: it makes the eyes read as adult, not cartoon. */
function crease(p: Palette, cx: number, lift: number): ReactElement {
	return (
		<path
			d={`M${cx - 6} ${79.6 - lift} Q${cx} ${76.2 - lift} ${cx + 6} ${79.2 - lift}`}
			fill="none"
			stroke={p.shade}
			strokeWidth={1.3}
			strokeLinecap="round"
			opacity={0.9}
		/>
	)
}

/** side −1 is the viewer's left, +1 the viewer's right. */
function brow(p: Palette, side: -1 | 1, kind: BrowKind): ReactElement {
	const cx = side < 0 ? EYE_X[0] : EYE_X[1]
	const [outerY, peakY, innerY] = browShapes[kind]
	const outerX = cx + side * 9
	const innerX = cx - side * 7.5
	return (
		<path
			d={`M${innerX} ${innerY} Q${cx + side * 1.5} ${peakY} ${outerX} ${outerY}`}
			fill="none"
			stroke={p.brow}
			strokeWidth={3.4}
			strokeLinecap="round"
		/>
	)
}

function mouth(p: Palette, kind: MouthKind): ReactElement {
	switch (kind) {
		case 'neutral':
			return (
				<path d="M93 117.4 Q100 119.6 107 117.4" fill="none" stroke={p.lip} strokeWidth={2.5} strokeLinecap="round" />
			)
		case 'soft':
			return (
				<path
					d="M91.5 116.6 Q100 121.6 108.5 116.6"
					fill="none"
					stroke={p.lip}
					strokeWidth={2.6}
					strokeLinecap="round"
				/>
			)
		case 'smile':
			return (
				<>
					<path d="M89.5 115.2 Q100 116.4 110.5 115.2 Q108.6 124.6 100 125 Q91.4 124.6 89.5 115.2Z" fill={p.lip} />
					<path d="M91.6 115.6 Q100 116.6 108.4 115.6 L107.6 118.2 Q100 119.4 92.4 118.2Z" fill="#FFFBF5" />
				</>
			)
		case 'hmm':
			return (
				<path d="M93 118.6 Q99 117.2 107.6 115.8" fill="none" stroke={p.lip} strokeWidth={2.5} strokeLinecap="round" />
			)
		case 'purse':
			return <ellipse cx={103.5} cy={117.6} rx={3} ry={2.3} fill={p.lip} />
		case 'talk':
			// Talking alternates the open mouth with the resting one, a syllable at a time (CSS).
			return (
				<>
					<path
						className={styles.syllable}
						d="M94 116 Q100 115 106 116 Q105 122.6 100 122.8 Q95 122.6 94 116Z"
						fill={p.lip}
					/>
					<path
						className={styles.rest}
						d="M93 117.4 Q100 119.6 107 117.4"
						fill="none"
						stroke={p.lip}
						strokeWidth={2.5}
						strokeLinecap="round"
					/>
				</>
			)
	}
}

function face(p: Palette, expression: Expression): ReactElement {
	const pose = poses[expression]
	const lift = pose.brows.some((b) => b === 'high' || b === 'raised') ? 1.2 : 0
	return (
		<g key={expression} data-face={expression} className={styles.face}>
			<ellipse cx={84} cy={103} rx={7.5} ry={4.2} fill={p.blush} opacity={pose.blush} />
			<ellipse cx={116} cy={103} rx={7.5} ry={4.2} fill={p.blush} opacity={pose.blush} />
			{crease(p, EYE_X[0], lift)}
			{crease(p, EYE_X[1], lift)}
			<g className={blinking.has(pose.eyes) ? styles.eyes : undefined}>
				{eye(pose.eyes, EYE_X[0])}
				{eye(pose.eyes, EYE_X[1])}
			</g>
			{brow(p, -1, pose.brows[0])}
			{brow(p, 1, pose.brows[1])}
			{mouth(p, pose.mouth)}
		</g>
	)
}

/** Hair behind the head. */
function back(person: Person, p: Palette): ReactElement | null {
	switch (person) {
		case 'priya':
			return (
				<path
					d="M56 84 C54 52 72 31 100 31 C130 31 147 52 145 84 C144 104 146 120 151 132 C141 140 127 140 118 134 L82 134 C73 140 59 140 49 132 C54 120 56 104 56 84Z"
					fill={p.hair}
				/>
			)
		case 'lena':
			return (
				<>
					<circle cx={100} cy={31} r={15.5} fill={p.hair} />
					<path d="M89 25 Q100 17 111 25 Q100 21.5 89 25Z" fill={p.hairHi} opacity={0.6} />
				</>
			)
		case 'marcus':
		case 'sam':
			return null
	}
}

function clothes(person: Person, p: Palette): ReactElement {
	switch (person) {
		case 'priya':
			return (
				<>
					<path d="M84 146 L100 178 L116 146Z" fill={p.inner} />
					<path d="M80 146 L100 184 L93 200 L70 200 L64 152Z" fill={p.outerShade} />
					<path d="M120 146 L100 184 L107 200 L130 200 L136 152Z" fill={p.outerShade} />
					<path d="M100 184 L93 200 L107 200Z" fill={p.outer} />
				</>
			)
		case 'marcus':
			return (
				<>
					<path d="M84 146 L100 174 L116 146Z" fill={p.inner} />
					<path d="M95.4 147.5 L104.6 147.5 L103.2 155 L96.8 155Z" fill={p.accent} />
					<path d="M96.6 155 L103.4 155 L106 184 L100 193 L94 184Z" fill={p.accent} />
					<path d="M81 146 L98 182 L91 200 L68 200 L63 152Z" fill={p.outerShade} />
					<path d="M119 146 L102 182 L109 200 L132 200 L137 152Z" fill={p.outerShade} />
				</>
			)
		case 'lena':
			return (
				<>
					<path d="M80 146 Q100 160 120 146" fill="none" stroke={p.inner} strokeWidth={7} strokeLinecap="round" />
					<path
						d="M62 156 L70 200 M138 156 L130 200"
						stroke={p.outerShade}
						strokeWidth={2.4}
						strokeLinecap="round"
						opacity={0.7}
					/>
					<path d="M88 152 L100 196" stroke={p.accent} strokeWidth={3} strokeLinecap="round" />
					<rect x={94} y={181} width={16} height={12} rx={2.5} fill="#F7F3EA" transform="rotate(-14 102 187)" />
				</>
			)
		case 'sam':
			return (
				<>
					<path d="M82 132 L118 132 L121 154 Q100 161 79 154Z" fill={p.inner} />
					<path
						d="M84 140 Q100 145 116 140 M83 147 Q100 152 117 147"
						fill="none"
						stroke="#5E2034"
						strokeWidth={1.4}
						opacity={0.7}
					/>
					<path d="M79 152 L94 200 L68 200 L62 154Z" fill={p.outerShade} />
					<path d="M121 152 L106 200 L132 200 L138 154Z" fill={p.outerShade} />
				</>
			)
	}
}

/** Hair, beard, glasses and accessories in front of the face. */
function front(person: Person, p: Palette): ReactElement {
	switch (person) {
		case 'priya':
			return (
				<>
					<path
						d="M59 88 C56 58 72 39 101 39 C125 39 141 54 141.5 80 C134 64 121 54 106 51.5 C95 63 77 74 59 88Z"
						fill={p.hair}
					/>
					<path d="M59.5 82 C58.5 102 61 118 66.5 128 L57 130 C54 112 55 96 59.5 82Z" fill={p.hair} />
					<path d="M74 50 C84 43.5 97 41.6 110 43.4 C98 44 86 47 76 53Z" fill={p.hairHi} opacity={0.55} />
					<circle cx={140.5} cy={104} r={4.6} fill="none" stroke={p.accent} strokeWidth={2} />
				</>
			)
		case 'marcus':
			return (
				<>
					<path
						d="M60.5 84 C58 54 76 38.5 100 38.5 C124 38.5 142 54 139.5 84 C137 70 131 58.5 119 53 C107 48.6 93 48.6 81 53 C69 58.5 63 70 60.5 84Z"
						fill={p.hair}
					/>
					<path
						d="M63 97 C64.5 115 77 131.5 100 135.5 C123 131.5 135.5 115 137 97 C134 107 128.5 114 121 117.5 C115 112 107 110.5 100 111.5 C93 110.5 85 112 79 117.5 C71.5 114 66 107 63 97Z"
						fill={p.beard}
					/>
					<path d="M88.5 112.6 Q100 106.4 111.5 112.6 Q100 110.2 88.5 112.6Z" fill={p.beard} />
					<g fill="#FFFFFF" fillOpacity={0.06} stroke={p.frame} strokeWidth={2.3}>
						<rect x={73.5} y={78.5} width={21} height={15.5} rx={5.5} />
						<rect x={105.5} y={78.5} width={21} height={15.5} rx={5.5} />
					</g>
					<path
						d="M94.5 84 Q100 81 105.5 84 M73.5 83.5 L61 82 M126.5 83.5 L139 82"
						fill="none"
						stroke={p.frame}
						strokeWidth={2.3}
						strokeLinecap="round"
					/>
					<path d="M108.5 81.6 L112 80.6" stroke="#FFFFFF" strokeWidth={1.4} strokeLinecap="round" opacity={0.55} />
				</>
			)
		case 'lena':
			return (
				<>
					<path
						d="M60 84 C57.5 55 76 37.5 100 37.5 C124 37.5 142.5 55 140 84 C138 70 132 59 122 53.5 C112 49.5 104 51 100 55.5 C96 51 88 49.5 78 53.5 C68 59 62 70 60 84Z"
						fill={p.hair}
					/>
					<path d="M100 55.5 C96 51 88 49.6 79 53.2 C88 51.8 95 53 100 55.5Z" fill={p.hairHi} opacity={0.5} />
					<path
						d="M62.6 80 C60 94 62 106 66.6 115"
						fill="none"
						stroke={p.hair}
						strokeWidth={2.6}
						strokeLinecap="round"
					/>
					<g fill={p.freckle}>
						<circle cx={79} cy={99} r={1.1} />
						<circle cx={84.5} cy={101.5} r={1} />
						<circle cx={76} cy={102.5} r={1} />
						<circle cx={121} cy={99} r={1.1} />
						<circle cx={115.5} cy={101.5} r={1} />
						<circle cx={124} cy={102.5} r={1} />
					</g>
					<circle cx={59.8} cy={97} r={1.8} fill="#E2B04B" />
					<circle cx={140.2} cy={97} r={1.8} fill="#E2B04B" />
				</>
			)
		case 'sam':
			return (
				<>
					<path
						d="M60.5 86 C56 54 74 34 102 34 C128 34 145 50 139.5 84 C137 69 129 56 117 51 C106 47 94 47.5 85 51 C73 56 64 68 60.5 86Z"
						fill={p.hair}
					/>
					<path
						d="M70 52 C80 36 104 29 126 38 C134 41 138 47 140 54 C130 44 114 40 98 42 C88 43.5 79 47 70 52Z"
						fill={p.hair}
					/>
					<path
						d="M76 47.5 C88 39 106 36.5 122 41 M84 52 C96 46.5 110 45.5 124 48.5"
						fill="none"
						stroke={p.hairHi}
						strokeWidth={1.7}
						strokeLinecap="round"
						opacity={0.6}
					/>
					<path
						d="M126 89 L130.5 87.5 M126.2 92.4 L130.6 92.6"
						stroke={p.shade}
						strokeWidth={1.1}
						strokeLinecap="round"
					/>
					<path d="M74 89 L69.5 87.5 M73.8 92.4 L69.4 92.6" stroke={p.shade} strokeWidth={1.1} strokeLinecap="round" />
					<path
						d="M88.6 108 Q86.6 113 88.4 117.6 M111.4 108 Q113.4 113 111.6 117.6"
						fill="none"
						stroke={p.shade}
						strokeWidth={1.2}
						strokeLinecap="round"
						opacity={0.8}
					/>
					<circle cx={140.4} cy={99} r={1.6} fill={p.accent} />
				</>
			)
	}
}

const names: Readonly<Record<Person, string>> = { priya: 'Priya', marcus: 'Marcus', lena: 'Lena', sam: 'Sam' }

type FigureProps = {
	readonly person: Person
	/** The expression it rests in. */
	readonly expression: Expression
	/** Other expressions a script may switch to (through `data-expr`). */
	readonly also?: readonly Expression[]
	/** The expression it takes while a `.react-host` ancestor is hovered or focused. */
	readonly hover?: Expression
	/** Breath, sway and blinks. Off for small figures that never hold the eye. */
	readonly idle?: boolean
	/** Set when the figure is the only thing describing itself; otherwise it's decorative. */
	readonly label?: string
	readonly className?: string | undefined
	/** Spreads the blinks so a row of people never blinks in unison. */
	readonly blinkDelay?: number
}

export function Figure({
	person,
	expression,
	also = [],
	hover,
	idle = true,
	label,
	className,
	blinkDelay = 0
}: FigureProps) {
	const p = palettes[person]
	const faces = [...new Set<Expression>([expression, ...also, ...(hover ? [hover] : [])])]
	const style = { '--blink-delay': `${blinkDelay}ms` } as CSSProperties
	const a11y = label ? { role: 'img', 'aria-label': label } : { 'aria-hidden': true }
	return (
		<svg
			viewBox="0 0 200 200"
			preserveAspectRatio="xMidYMax meet"
			className={[styles.figure, idle ? styles.idle : '', className ?? ''].join(' ')}
			data-expr={expression}
			data-hover={hover}
			data-person={names[person]}
			style={style}
			focusable="false"
			{...a11y}
		>
			<g className={styles.sway}>
				<g className={styles.head}>{back(person, p)}</g>
				<path d="M85 118 L115 118 L117 150 L83 150Z" fill={p.shade} />
				<path d="M85 122 Q100 136 115 122 L115 132 Q100 142 85 132Z" fill="#000" opacity={0.12} />
				<g className={styles.torso}>
					<path d={TORSO} fill={p.outer} />
					{clothes(person, p)}
				</g>
				<g className={styles.head}>
					<ellipse cx={60.5} cy={90} rx={6} ry={9.5} fill={p.shade} />
					<ellipse cx={139.5} cy={90} rx={6} ry={9.5} fill={p.shade} />
					<ellipse cx={61.5} cy={90} rx={3} ry={5.5} fill={p.skin} opacity={0.5} />
					<ellipse cx={138.5} cy={90} rx={3} ry={5.5} fill={p.skin} opacity={0.5} />
					<path d={HEAD} fill={p.skin} />
					<path
						d="M128 56 C138 70 141 92 134 110 C128 124 118 131 108 134 C122 122 131 104 131 86 C131 74 130 64 128 56Z"
						fill={p.shade}
						opacity={0.55}
					/>
					<path
						d="M99.2 90 Q96.6 100 96.4 104.2"
						fill="none"
						stroke={p.shade}
						strokeWidth={2.2}
						strokeLinecap="round"
					/>
					<path
						d="M95.6 105.6 Q100 108.2 104.6 105.6"
						fill="none"
						stroke={p.shade}
						strokeWidth={2.2}
						strokeLinecap="round"
					/>
					{faces.map((e) => face(p, e))}
					{front(person, p)}
					<path
						d="M64 72 C66 56 77 44.5 91 41"
						fill="none"
						stroke="#FFF6E2"
						strokeWidth={2}
						strokeLinecap="round"
						opacity={0.35}
					/>
				</g>
			</g>
		</svg>
	)
}
