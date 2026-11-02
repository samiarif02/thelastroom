import { SignArrow } from './SignArrow'
import styles from './Sign.module.css'

type SignProps = {
	/** Labels the section (`aria-labelledby`). */
	readonly id: string
	/** What's on the sign's coloured block: the floor number, or a room's letter. */
	readonly mark: string
	/** The small line above the title: "Floor 1 · Rooms 01–07". */
	readonly label: string
	readonly title: string
	/** The right-hand line, with an arrow: "Choose your words". */
	readonly aside: string
	readonly intro?: string
}

/**
 * A section's sign, set like the floor signs by a lift: the coloured block with the floor or room,
 * the name in heavy capitals, where it leads. Its colour comes from the section's `data-tone`.
 */
export function Sign({ id, mark, label, title, aside, intro }: SignProps) {
	return (
		<header className={styles.wrap}>
			<div className={styles.sign}>
				<span className={styles.mark} aria-hidden="true">
					{mark}
				</span>
				<div className={styles.text}>
					<p className={`label ${styles.label}`}>{label}</p>
					<h2 id={id} className={styles.title}>
						{title}
					</h2>
				</div>
				<p className={`label ${styles.aside}`}>
					{aside}
					<SignArrow />
				</p>
			</div>
			{intro ? <p className={styles.intro}>{intro}</p> : null}
		</header>
	)
}
