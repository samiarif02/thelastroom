import { rooms, type Floor } from '@/content/site'

import styles from './RoomList.module.css'

type RoomListProps = {
	readonly floor: Floor
}

/** A floor's room directory, like the panel by the lift: number, name, how it's answered. */
export function RoomList({ floor }: RoomListProps) {
	return (
		<div className={styles.panel}>
			<p className={`label ${styles.head}`}>
				<span>{`Floor ${floor.level}`}</span>
				<span>{rooms.span(floor)}</span>
			</p>
			<ol className={styles.list} aria-label={`Floor ${floor.level} rooms`}>
				{floor.missions.map((mission) => (
					<li key={mission.number} className={styles.room}>
						<span className={styles.number}>{String(mission.number).padStart(2, '0')}</span>
						<span className={styles.name}>{mission.title}</span>
						<span className={`label ${styles[mission.mode]}`}>{rooms.modes[mission.mode]}</span>
					</li>
				))}
			</ol>
		</div>
	)
}
