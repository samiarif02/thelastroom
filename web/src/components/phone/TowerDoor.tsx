import { Check, LockSimple, Play } from '@phosphor-icons/react/dist/ssr'

import { Figure } from '@/cast/Figure'
import type { Person } from '@/cast/people'

import styles from './TowerDoor.module.css'

/**
 * How a room's door stands on the tower, as the app draws it (`tower_door.dart`):
 * `done` honey with a check, `next` ajar with the interviewer in the warm doorway, `closed`
 * panelled with a knob, `locked` closed with a small lock, `waiting` the lit last door with Sam.
 */
export type DoorState = 'done' | 'next' | 'closed' | 'locked' | 'waiting'

/** The floor's colours for a door, as the app picks them: dusk on top, the floor's own below. */
export type DoorTone = 'dusk' | 'open' | 'pale'

// The arch motif on the app's own grid: a 28 × 44 door, a 2 px frame, round top, flat sill.
const W = 28
const H = 44
const FRAME = 2
const INSET = W * 0.22
const KNOB_Y = H * 0.56

/** The arch of a rect: straight sides, a round top, a flat sill. */
function arch(left: number, top: number, right: number, bottom: number): string {
	const r = (right - left) / 2
	return `M${left} ${bottom}V${top + r}A${r} ${r} 0 0 1 ${right} ${top + r}V${bottom}Z`
}

const OUTER = arch(0, 0, W, H)
const LEAF = arch(FRAME, FRAME, W - FRAME, H)
const UPPER = arch(INSET, INSET + FRAME, W - INSET, H * 0.52)
const LOWER = { x: INSET, y: H * 0.6, width: W - 2 * INSET, height: H - INSET * 0.8 - H * 0.6 }

// The ajar leaf, swung in on its left hinge: a narrowing trapezoid, its free edge further away.
const OPEN = W * 0.38
const HALF = W / 2
const AJAR_LEAF = `M${FRAME} ${H}V${HALF}Q${FRAME + OPEN * 0.2} ${HALF * 0.25} ${FRAME + OPEN} ${HALF * 0.55}V${H * 0.94}Z`

// The light from the open door, fanning out on the floor below the sill.
const SPILL_W = W * 1.5
const SPILL_H = 6
const SPILL_X = -W * 0.25
const SPILL = `M${SPILL_X + SPILL_W * 0.2} ${H}H${SPILL_X + SPILL_W * 0.8}L${SPILL_X + SPILL_W} ${H + SPILL_H}H${SPILL_X}Z`

const CHECK = W * 0.5
const LOCK = W * 0.42

type TowerDoorProps = {
	readonly state: DoorState
	readonly tone: DoorTone
	/** Who waits in the doorway of the door to play. */
	readonly person?: Person
	/** The door this visit lit: drawn closed, then the honey leaf rises over it (the hero's step). */
	readonly lighting?: boolean
}

/** A closed door: the frame, the leaf, two recessed panels and the knob. */
function Closed({ className, upper = true }: { readonly className?: string | undefined; readonly upper?: boolean }) {
	return (
		<g className={className}>
			<path className={styles.frame} d={OUTER} />
			<path className={styles.leaf} d={LEAF} />
			{upper ? <path className={styles.panel} d={UPPER} /> : null}
			<rect className={styles.panel} rx={1.5} {...LOWER} />
			<circle className={styles.knob} cx={W - INSET * 0.9} cy={KNOB_Y} r={W * 0.06} />
		</g>
	)
}

/** One door of the tower, in a cell tall enough for the play cue over the door to play. */
export function TowerDoor({ state, tone, person, lighting = false }: TowerDoorProps) {
	return (
		<span className={`${styles.cell} ${styles[tone]} ${styles[state]}`}>
			{state === 'next' ? (
				<span className={styles.cue}>
					<Play weight="fill" />
				</span>
			) : null}
			<span className={`${styles.door} ${lighting ? styles.lighting : ''}`}>
				{state === 'next' && person ? (
					<span className={styles.doorway}>
						<span className={styles.peek}>
							<Figure person={person} expression="neutral" idle={false} />
						</span>
					</span>
				) : null}
				<svg viewBox={`0 0 ${W} ${H}`} className={styles.art} focusable="false" aria-hidden="true">
					{state === 'next' ? (
						<>
							<path className={styles.spill} d={SPILL} />
							<path className={styles.frame} d={`${OUTER}${LEAF}`} fillRule="evenodd" />
							<path className={styles.leaf} d={AJAR_LEAF} />
							<path className={`${styles.panel} ${styles.hinge}`} d={`M${FRAME + OPEN * 0.35} ${H * 0.3}V${H * 0.85}`} />
							<circle className={styles.cueKnob} cx={FRAME + OPEN * 0.8} cy={KNOB_Y} r={W * 0.05} />
						</>
					) : null}
					{state === 'closed' || state === 'locked' || lighting ? <Closed /> : null}
					{state === 'done' ? (
						<>
							<Closed className={`${styles.honey} ${styles.rise}`} upper={false} />
							<g className={styles.check}>
								<Check
									weight="bold"
									x={(W - CHECK) / 2}
									y={H / 2 - 0.3 * ((H - CHECK) / 2) - CHECK / 2}
									size={CHECK}
								/>
							</g>
						</>
					) : null}
					{state === 'waiting' ? (
						<>
							<Closed className={styles.honey} />
							<circle className={styles.sam} cx={W / 2} cy={H - 9 - 2 - 4.5} r={4.5} />
							<path className={styles.sam} d={`M${W / 2 - 9} ${H}A9 9 0 0 1 ${W / 2 + 9} ${H}Z`} />
						</>
					) : null}
					{state === 'locked' ? (
						<g className={styles.lock}>
							<LockSimple
								weight="fill"
								x={(W - LOCK) / 2}
								y={H / 2 + 0.25 * ((H - LOCK) / 2) - LOCK / 2}
								size={LOCK}
							/>
						</g>
					) : null}
				</svg>
				{lighting ? <span className={styles.glow} /> : null}
			</span>
		</span>
	)
}
