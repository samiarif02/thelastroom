import { hero, lastRoom } from '@/content/site'

import styles from './LastRoom.module.css'

/** Floor 3's main column: the last room's door plate. */
export function LastRoom() {
	return (
		<div className={styles.door}>
			<p className={styles.number} aria-hidden="true">
				{hero.directory.lastRoom.mark}
			</p>
			<div className={styles.plate}>
				<h3 className={styles.name}>{hero.directory.lastRoom.name}</h3>
				<p className={`label ${styles.label}`}>{lastRoom.label}</p>
				<p className={styles.copy}>{lastRoom.body}</p>
			</div>
		</div>
	)
}
