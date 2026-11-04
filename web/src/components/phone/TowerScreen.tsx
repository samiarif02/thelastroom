import { Lightning } from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties } from 'react'

import type { Person } from '@/cast/people'

import { StatusBar } from './parts'
import styles from './screens.module.css'
import { TowerDoor } from './TowerDoor'

const roomsPerFloor = 7
/** The room this visit lit: room 4, the fourth door on floor 1. */
const newRoom = 3
/** The room to play next, room 5, and who waits in its doorway (mission 5 is Marcus's). */
const nextRoom = newRoom + 1
const nextPerson: Person = 'marcus'
const ringRadius = 22
const ringLength = 2 * Math.PI * ringRadius

type TowerScreenProps = {
	readonly greeting: string
	readonly title: string
	readonly lit: string
	readonly week: { readonly label: string; readonly value: string }
	readonly sign: string
	readonly floors: readonly { readonly name: string; readonly note: string }[]
	/** In the hero demo it's a step: hidden until `tower`, where room 4 lights up. */
	readonly overlay?: boolean
}

/**
 * The tower, home (01b-home-tower), drawn as the app draws it: three floors of seven doors.
 * Floor 1's first four are honey with a check, room 5 stands ajar with Marcus in the doorway and
 * the play cue bobbing over it, rooms 6 and 7 are closed; floors 2 and 3 are locked, and the
 * dusk top floor's last door is lit, Sam waiting in it.
 */
export function TowerScreen({ greeting, title, lit, week, sign, floors, overlay }: TowerScreenProps) {
	const [top, middle, ground] = floors
	return (
		<div className={`${styles.screen} ${overlay ? `${styles.overlay} ${styles.towerOverlay}` : ''}`}>
			<StatusBar />
			<div className={styles.towerHead}>
				<div>
					<p className={`caption-3 ${styles.kickerDeep}`}>{greeting}</p>
					<p className="heading-5">{title}</p>
				</div>
				<div className={styles.week}>
					<svg viewBox="0 0 56 56" className={styles.ring}>
						<circle cx="28" cy="28" r={ringRadius} className={styles.ringTrack} />
						<circle
							cx="28"
							cy="28"
							r={ringRadius}
							className={styles.ringFill}
							style={{ '--ring': ringLength, '--ring-left': ringLength / 3 } as CSSProperties}
						/>
					</svg>
					<span>
						<span className="caption-4">{week.label}</span>
						<span className="body-1 tnum">{week.value}</span>
					</span>
				</div>
			</div>
			<div className={styles.sky}>
				<span className={styles.cloud} />
				<span className={`${styles.cloud} ${styles.cloudRight}`} />
				<div className={styles.building}>
					<span className={styles.mast} />
					<div className={styles.roof}>
						<span>{sign}</span>
					</div>
					<div className={`${styles.floor} ${styles.floorDusk}`}>
						<div className={styles.windows}>
							{Array.from({ length: roomsPerFloor }, (_, i) => (
								<TowerDoor key={i} tone="dusk" state={i === roomsPerFloor - 1 ? 'waiting' : 'locked'} />
							))}
						</div>
						<p className={styles.floorLabel}>
							<span>{top?.name}</span>
							<span className={styles.noteHoney}>{top?.note}</span>
						</p>
					</div>
					<div className={`${styles.floor} ${styles.floorWaiting}`}>
						<div className={styles.windows}>
							{Array.from({ length: roomsPerFloor }, (_, i) => (
								<TowerDoor key={i} tone="pale" state="locked" />
							))}
						</div>
						<p className={styles.floorLabel}>
							<span>{middle?.name}</span>
							<span>{middle?.note}</span>
						</p>
					</div>
					<div className={`${styles.floor} ${styles.floorOne}`}>
						<div className={styles.windows}>
							{Array.from({ length: roomsPerFloor }, (_, i) => (
								<TowerDoor
									key={i}
									tone="open"
									state={i <= newRoom ? 'done' : i === nextRoom ? 'next' : 'closed'}
									lighting={i === newRoom}
									{...(i === nextRoom ? { person: nextPerson } : {})}
								/>
							))}
						</div>
						<p className={styles.floorLabel}>
							<span>{ground?.name}</span>
							<span className="tnum">{ground?.note}</span>
						</p>
					</div>
					<div className={styles.lobby} />
				</div>
			</div>
			<p className={`body-5 ${styles.litLine}`}>
				<Lightning weight="fill" />
				{lit}
			</p>
		</div>
	)
}
