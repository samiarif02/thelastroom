import { Check, Lightning } from '@phosphor-icons/react/dist/ssr'
import type { CSSProperties } from 'react'

import { Figure } from '@/cast/Figure'

import { StatusBar } from './parts'
import styles from './screens.module.css'

const roomsPerFloor = 7
/** The room this visit lit: room 4, the fourth window on floor 1. */
const newRoom = 3
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
 * The tower, home (01b-home-tower): three floors of seven arched windows. Floor 1's first four
 * are lit honey with a check; floor 2 waits; the dusk top floor has one lit window, Sam's.
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
							{Array.from({ length: roomsPerFloor }, (_, i) =>
								i === roomsPerFloor - 1 ? (
									<span key={i} className={`${styles.window} ${styles.samWindow}`}>
										<Figure person="sam" expression="neutral" idle={false} />
									</span>
								) : (
									<span key={i} className={styles.window} />
								)
							)}
						</div>
						<p className={styles.floorLabel}>
							<span>{top?.name}</span>
							<span className={styles.noteHoney}>{top?.note}</span>
						</p>
					</div>
					<div className={`${styles.floor} ${styles.floorWaiting}`}>
						<div className={styles.windows}>
							{Array.from({ length: roomsPerFloor }, (_, i) => (
								<span key={i} className={styles.window} />
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
								<span
									key={i}
									className={`${styles.window} ${i <= newRoom ? styles.lit : ''} ${i === newRoom ? styles.newRoom : ''}`}
								>
									{i <= newRoom ? (
										<>
											<span className={styles.windowFill} />
											<Check weight="bold" className={styles.check} />
										</>
									) : null}
									{i === newRoom ? <span className={styles.glow} /> : null}
								</span>
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
