import { Ornament } from './Ornament'
import styles from './SectionHeading.module.css'

type SectionHeadingProps = {
	readonly id: string
	readonly eyebrow: string
	readonly title: string
	readonly intro?: string
}

/** A section's tracked-caps eyebrow, serif title and one-line intro. `id` labels the section. */
export function SectionHeading({ id, eyebrow, title, intro }: SectionHeadingProps) {
	return (
		<header className={styles.heading}>
			<p className={styles.eyebrow}>{eyebrow}</p>
			<h2 id={id} className={styles.title}>
				{title}
			</h2>
			<Ornament align="start" />
			{intro ? <p className={styles.intro}>{intro}</p> : null}
		</header>
	)
}
