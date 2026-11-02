import type { ReactNode } from 'react'

import { rooms, type Floor } from '@/content/site'

import { RoomList } from './RoomList'
import { Sign } from './Sign'
import styles from './FloorSection.module.css'

type FloorSectionProps = {
	readonly floor: Floor
	/** What's on this floor besides its rooms: how a room works, a spoken answer, the last room. */
	readonly children: ReactNode
	/** Above the room list, in the side column: a still, if the floor has one there. */
	readonly side?: ReactNode
}

/** One floor of the building: its band and sign, what happens there, and its room directory. */
export function FloorSection({ floor, children, side }: FloorSectionProps) {
	const titleId = `${floor.id}-title`
	return (
		<section
			id={floor.id}
			className="section"
			aria-labelledby={titleId}
			data-tone={floor.tone}
			data-lift={floor.level}
			data-lift-name={`Floor ${floor.level} · ${floor.title}`}
		>
			<div className={`container ${styles.floor}`}>
				<Sign
					id={titleId}
					mark={floor.level}
					label={`Floor ${floor.level} · ${rooms.span(floor)}`}
					title={floor.title}
					aside={floor.mode}
					intro={floor.body}
				/>
				<div className={styles.grid}>
					<div className={styles.main}>{children}</div>
					<div className={styles.side}>
						{side}
						<RoomList floor={floor} />
					</div>
				</div>
			</div>
		</section>
	)
}
